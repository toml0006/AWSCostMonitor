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
        popover.contentSize = NSSize(width: 360, height: 500)
        // `.transient` closes the popover the moment any element outside its bounds
        // receives a mouseDown — including the NSMenu spawned by SwiftUI's Picker.
        // That killed the first profile-switch click. We dismiss via the global
        // event monitor (outside-app clicks) and explicit togglePopover instead.
        popover.behavior = .applicationDefined
        popover.animates = true
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
        
        // Subscribe to changes in cost data and settings
        awsManager.$costData
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        awsManager.$isLoading
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        awsManager.$errorMessage
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        awsManager.$selectedProfile
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        // Listen to UserDefaults changes for display settings (debounced to prevent recursion)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        #if DEBUG
        // Subscribe to debug timer flash for visual feedback
        awsManager.$debugTimerFlash
            .sink { [weak self] shouldFlash in
                self?.updateStatusItemView(flash: shouldFlash)
            }
            .store(in: &cancellables)
        #endif

        appearance.$appearance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderStatusItem() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .menuBarOptionsChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.options = MenuBarOptions()
                self?.renderStatusItem()
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
        if let button = statusItem.button {
            // Validate timer health when user opens the menu
            awsManager.validateTimerHealth()

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - Popover Content View with Full Rendering
