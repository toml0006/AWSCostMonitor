//
//  StatusBarController.swift
//  AWSCostMonitor
//
//  Menu bar status item controller
//

import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - Custom Status Bar Implementation with Popover

@MainActor
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awsManager: AWSManager
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private let presenter: MenuBarPresenter
    let appearance: AppearanceManager
    private var options = MenuBarOptions()
    private let sizing = PopoverSizing()
    private var hostingController: NSHostingController<AnyView>!

    init(awsManager: AWSManager, appearance: AppearanceManager) {
        self.awsManager = awsManager
        self.appearance = appearance
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        self.presenter = MenuBarPresenter(button: statusItem.button!)
        super.init()
        
        // Create status item
        // Create popover with SwiftUI content
        popover = NSPopover()
        // `.transient` closes the popover the moment any element outside its bounds
        // receives a mouseDown — including the NSMenu spawned by SwiftUI's Picker.
        // That killed the first profile-switch click. We dismiss via the global
        // event monitor (outside-app clicks) and explicit togglePopover instead.
        popover.behavior = .applicationDefined
        // Native fade on show/hide. (The theme-switch crash was an unrelated NSWindow
        // double-free on Settings close, not popover animation, so the fade is safe.)
        popover.animates = true
        // popoverDidShow fires after the presentation animation settles, so the
        // on-screen clamp no longer depends on `animates` being false. cb744d1
        // tied those together in a comment only, and 9f1c3c9 restored the fade
        // and silently broke the clamp.
        popover.delegate = self
        // Right-edge clipping is handled by measuring content against the screen
        // before show (syncContentSize) and moving the window onto the screen in
        // popoverDidShow. The popover is never shrunk to fit.
        // Retained: showPopover() must measure this view's fittingSize before
        // handing a size to NSPopover.
        hostingController = NSHostingController(
            rootView: AnyView(
                PopoverContentView()
                    .environmentObject(awsManager)
                    .environmentObject(appearance)
                    .environmentObject(sizing)
                    .environment(\.ledgerAppearance, appearance.appearance)
            )
        )
        popover.contentViewController = hostingController
        
        updateStatusItemView()
        
        // Setup click handler
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            // Suppress implicit animations on the status item's hosting window; a
            // theme change re-renders the button and can otherwise spin up an
            // _NSWindowTransformAnimation that is over-released on the CA commit.
            button.window?.animationBehavior = .none
        }
        
        // All render-triggering signals funnel into one debounced publisher so
        // rapid theme/appearance clicks can't fire overlapping button mutations
        // mid-CATransaction. Previously separate sinks on appearance, UserDefaults,
        // and AWSManager publishers could fire 2–3 renders per user click, which
        // was producing zombie _NSWindowTransformAnimation over-releases under
        // AppKit's implicit layout animations.
        let signals: [AnyPublisher<Void, Never>] = [
            awsManager.$costData.map { _ in () }.eraseToAnyPublisher(),
            awsManager.$isLoading.map { _ in () }.eraseToAnyPublisher(),
            awsManager.$errorMessage.map { _ in () }.eraseToAnyPublisher(),
            awsManager.$selectedProfile.map { _ in () }.eraseToAnyPublisher(),
            appearance.$appearance.map { _ in () }.eraseToAnyPublisher(),
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification)
                .map { _ in () }
                .eraseToAnyPublisher(),
            NotificationCenter.default
                .publisher(for: .menuBarOptionsChanged)
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.options = MenuBarOptions()
                })
                .map { _ in () }
                .eraseToAnyPublisher()
        ]

        Publishers.MergeMany(signals)
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderStatusItem() }
            .store(in: &cancellables)

        // A profile switch can change the hero digit count and therefore the
        // popover width while it is open. Re-measure and re-anchor; show() on an
        // already-visible popover re-positions without replaying the fade.
        Publishers.MergeMany(signals)
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.popover.isShown, let button = self.statusItem.button else { return }
                self.syncContentSize(on: button.window?.screen ?? NSScreen.main)
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                guard let self, let button = self.statusItem.button else { return }
                self.syncContentSize(on: button.window?.screen ?? NSScreen.main)
            }
            .store(in: &cancellables)
        
        // Monitor for clicks outside popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }

    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
    
    func updateStatusItemView(flash: Bool = false) {
        renderStatusItem()
    }

    private func renderStatusItem() {
        let a = appearance.appearance
        let accent = NSColor(LedgerTokens.Color.accent(a))
        let overColor = NSColor(LedgerTokens.Color.signalOver(a))
        let amount = awsManager.costData.first.map { NSDecimalNumber(decimal: $0.amount).doubleValue } ?? 0.0
        let budgetUsed = awsManager.budgetFraction ?? 0.0
        let rangeRaw = UserDefaults.standard.string(forKey: "SparklineRange") ?? SparklineRange.monthRolling.rawValue
        let range = SparklineRange(rawValue: rangeRaw) ?? .monthRolling
        let series = range.series(from: awsManager.dailyPointsForSelectedProfile ?? [])
        presenter.render(
            amount: amount,
            delta: awsManager.deltaFractionVsLastMonth,
            budgetUsed: budgetUsed,
            sparkline: series.values,
            sparklineHighlightIndex: series.todayIndex,
            options: options,
            accent: accent,
            overBudget: overColor
        )
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        guard let button = statusItem.button else { return }
        syncContentSize(on: button.window?.screen ?? NSScreen.main)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    /// Publish the screen constraint, force a synchronous relayout against it,
    /// then hand NSPopover the true content size. Without the relayout,
    /// fittingSize reports the previous pass and NSPopover clamps against a
    /// stale size — the original bug by another route.
    private func syncContentSize(on screen: NSScreen?) {
        sizing.availableWidth = PopoverGeometry.availableWidth(
            screenWidth: screen?.visibleFrame.width ?? 1440
        )
        hostingController.view.layoutSubtreeIfNeeded()
        popover.contentSize = hostingController.view.fittingSize
    }

    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - NSPopoverDelegate

extension StatusBarController: NSPopoverDelegate {
    /// Timing-independent safety net for edge clipping. Fires once the
    /// presentation animation has settled, so `win.frame` is final.
    func popoverDidShow(_ notification: Notification) {
        guard let win = popover.contentViewController?.view.window else { return }
        let visible = (win.screen ?? NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        var frame = win.frame
        frame.origin.x = PopoverGeometry.clampedOriginX(
            idealX: frame.origin.x, width: frame.width, visible: visible
        )
        guard frame.origin.x != win.frame.origin.x else { return }
        win.setFrame(frame, display: true, animate: false)
    }
}

// MARK: - Popover Content View with Full Rendering
