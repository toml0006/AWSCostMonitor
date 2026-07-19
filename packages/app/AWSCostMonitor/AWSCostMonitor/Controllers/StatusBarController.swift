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
        // Animations OFF, deliberately. The popover's show/hide/resize uses an
        // `_NSWindowTransformAnimation`; when the SwiftUI content churns layers
        // mid-flight (e.g. selecting the Spectrum theme repaints glow shadows), that
        // window animation gets over-released in the CoreAnimation commit and crashes
        // (EXC_BAD_ACCESS in -[_NSWindowTransformAnimation dealloc]). Showing instantly
        // removes the animation object entirely, so the crash cannot occur. It also
        // makes the post-show frame clamp in showPopover() reliable (no in-flight
        // window animation to fight). Reads as native for a menu-bar popover.
        popover.animates = false
        // Right-edge clipping is handled by clamping the content width
        // (updateAvailableWidth) and, as a timing-independent safety net, clamping the
        // popover window onto the screen after show (clampPopoverOnScreen).
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(awsManager)
                .environmentObject(appearance)
                .environment(\.ledgerAppearance, appearance.appearance)
        )
        
        updateStatusItemView()
        
        // Setup click handler
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
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
        if let button = statusItem.button {
            updateAvailableWidth(for: button)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Kill implicit window animations on the popover's own window. NSPopover
            // animates a window *resize* whenever its SwiftUI content re-lays-out while
            // open (e.g. selecting the Spectrum theme), independent of `popover.animates`.
            // That `_NSWindowTransformAnimation` gets over-released in the CoreAnimation
            // commit → EXC_BAD_ACCESS. animationBehavior = .none suppresses AppKit's
            // automatic window animations, so the resize applies instantly with no
            // animation object to over-release.
            popover.contentViewController?.view.window?.animationBehavior = .none
            clampPopoverOnScreen()
        }
    }

    /// Timing-independent safety net for right-edge clipping. The content-width
    /// clamp (updateAvailableWidth) flows through UserDefaults → @AppStorage →
    /// SwiftUI relayout, which is async, while NSPopover measures its content
    /// synchronously at show() — so a given show can use the previous show's
    /// width and still run off the display. Once the popover window exists, nudge
    /// it fully onto the screen. With animations off the window is already at its
    /// final frame here, so this is a stable, one-shot adjustment.
    private func clampPopoverOnScreen() {
        guard let win = popover.contentViewController?.view.window else { return }
        let visible = (win.screen ?? NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        let margin: CGFloat = 8
        var frame = win.frame
        if frame.maxX > visible.maxX - margin {
            frame.origin.x = visible.maxX - margin - frame.width
        }
        if frame.minX < visible.minX + margin {
            frame.origin.x = visible.minX + margin
        }
        if frame.origin.x != win.frame.origin.x {
            win.setFrame(frame, display: true)
        }
    }

    /// The popover anchors its arrow under the status item and (with
    /// `.applicationDefined` behavior) does not reliably shift to stay on
    /// screen, so a wide popover under an item near the right edge clips off
    /// the display. Publish the widest the content may be while remaining fully
    /// on screen, centered on the item; `PopoverContentView` clamps to it.
    private func updateAvailableWidth(for button: NSStatusBarButton) {
        let margin: CGFloat = 12
        let itemCenterX: CGFloat
        let visible: NSRect
        if let window = button.window {
            let screenRect = window.convertToScreen(button.convert(button.bounds, to: nil))
            itemCenterX = screenRect.midX
            visible = (window.screen ?? NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        } else {
            visible = NSScreen.main?.visibleFrame ?? .zero
            itemCenterX = visible.midX
        }
        // Centered on the arrow, the popover needs half its width on each side;
        // the tighter side (the right edge, for a menu-bar item) governs.
        let rightGap = visible.maxX - itemCenterX
        let leftGap  = itemCenterX - visible.minX
        let centeredFit = 2 * min(rightGap, leftGap) - margin
        let available = max(360, min(visible.width - 2 * margin, centeredFit))
        UserDefaults.standard.set(Double(available), forKey: "popover.availableWidth")
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - Popover Content View with Full Rendering
