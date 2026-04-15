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
import QuartzCore

// MARK: - Custom Status Bar Implementation with Popover

@MainActor
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awsManager: AWSManager
    private var themeManager: ThemeManager
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var pillBackgroundLayer: CALayer?
    private let presenter: MenuBarPresenter
    let appearance: AppearanceManager
    private var options = MenuBarOptions()
    
    convenience init(awsManager: AWSManager, themeManager: ThemeManager = ThemeManager.shared) {
        self.init(awsManager: awsManager, themeManager: themeManager, appearance: AppearanceManager())
    }

    init(awsManager: AWSManager, themeManager: ThemeManager = ThemeManager.shared, appearance: AppearanceManager) {
        self.awsManager = awsManager
        self.themeManager = themeManager
        self.appearance = appearance
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        self.presenter = MenuBarPresenter(button: statusItem.button!)
        super.init()
        
        // Create status item
        // Create popover with SwiftUI content
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(awsManager)
                .themed(themeManager)
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
        
        // Subscribe to theme changes
        themeManager.$currentTheme
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

    private func updatePillBackground(for button: NSStatusBarButton) {
        let theme = themeManager.currentTheme
        let showPill = UserDefaults.standard.bool(forKey: "ShowMenuBarPillBackground")
                       || theme.menuBarBackgroundStyle == .pill

        // Remove existing pill layer
        pillBackgroundLayer?.removeFromSuperlayer()
        pillBackgroundLayer = nil

        guard showPill else { return }

        // Ensure button is layer-backed
        button.wantsLayer = true
        guard let buttonLayer = button.layer else { return }

        // Create pill background layer
        let pillLayer = CALayer()

        // Determine background color based on menu bar appearance
        let isDarkMenu = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor: NSColor
        if isDarkMenu {
            bgColor = NSColor.white.withAlphaComponent(0.12)
        } else {
            bgColor = NSColor.black.withAlphaComponent(0.06)
        }
        pillLayer.backgroundColor = bgColor.cgColor
        pillLayer.cornerRadius = theme.menuBarPillCornerRadius

        // Calculate frame with padding
        let horizontalPadding: CGFloat = 6
        let verticalPadding: CGFloat = 2
        let buttonBounds = button.bounds

        pillLayer.frame = CGRect(
            x: -horizontalPadding,
            y: verticalPadding,
            width: buttonBounds.width + (horizontalPadding * 2),
            height: buttonBounds.height - (verticalPadding * 2)
        )

        // Insert below text
        buttonLayer.insertSublayer(pillLayer, at: 0)
        pillBackgroundLayer = pillLayer
    }
    
    // Legacy color method replaced by theme-aware ThemedMenuBarDisplay.getStatus()

    private func renderStatusItem() {
        let a = appearance.appearance
        let accent = NSColor(LedgerTokens.Color.accent(a))
        let overColor = NSColor(LedgerTokens.Color.signalOver(a))
        let amount = awsManager.costData.first.map { NSDecimalNumber(decimal: $0.amount).doubleValue } ?? 0.0
        let budgetUsed = awsManager.budgetFraction ?? 0.0
        let sparkline = awsManager.dailyTotalsForSelectedProfile ?? []
        presenter.render(
            amount: amount,
            delta: awsManager.deltaFractionVsLastMonth,
            budgetUsed: budgetUsed,
            sparkline: sparkline,
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
