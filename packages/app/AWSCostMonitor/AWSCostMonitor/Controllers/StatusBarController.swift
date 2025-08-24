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

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awsManager: AWSManager
    private var themeManager: ThemeManager
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(awsManager: AWSManager, themeManager: ThemeManager = ThemeManager.shared) {
        self.awsManager = awsManager
        self.themeManager = themeManager
        super.init()
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
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
        guard let button = statusItem.button else { return }
        
        // Get display settings with defaults
        let displayFormat = UserDefaults.standard.string(forKey: "MenuBarDisplayFormat") ?? "full"
        let showColors = UserDefaults.standard.object(forKey: "ShowMenuBarColors") as? Bool ?? true
        let showCurrencySymbol = UserDefaults.standard.object(forKey: "ShowCurrencySymbol") as? Bool ?? true
        let decimalPlaces = UserDefaults.standard.object(forKey: "DecimalPlaces") as? Int ?? 2
        
        // Force thousands separator to always be true for now
        let useThousandsSeparator = true
        
        var titleString = ""
        var costStatus: MenuBarCostStatus = .normal
        
        // Setup number formatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = useThousandsSeparator
        
        // Determine cost status using theme-aware status calculation
        if let cost = awsManager.costData.first {
            let budget = awsManager.getBudget(for: cost.profileName)
            costStatus = ThemedMenuBarDisplay.getStatus(
                for: cost,
                lastMonthData: awsManager.lastMonthData,
                budget: budget
            )
        } else if awsManager.isLoading {
            costStatus = .loading
        }
        
        switch displayFormat {
        case "abbreviated":
            // No icon for abbreviated format
            button.image = nil
            if let cost = awsManager.costData.first {
                let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
                formatter.maximumFractionDigits = 0
                let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
                titleString = showCurrencySymbol ? "$\(formattedAmount)" : formattedAmount
            } else if awsManager.isLoading {
                titleString = "..."
            } else {
                titleString = "AW$"
            }
            
        case "full":
            // No icon for full format  
            button.image = nil
            if let cost = awsManager.costData.first {
                let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
                formatter.minimumFractionDigits = decimalPlaces
                formatter.maximumFractionDigits = decimalPlaces
                let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
                titleString = showCurrencySymbol ? "$\(formattedAmount)" : formattedAmount
            } else if awsManager.isLoading {
                titleString = "Loading..."
            } else {
                titleString = "AW$"
            }
            
        case "iconOnly":
            // Use theme-aware icon
            button.image = themeManager.currentTheme.createMenuBarIcon(size: 18)
            titleString = "" // No text when showing icon only
        
        default:
            button.image = nil
            titleString = "AW$"
        }
        
        // Create themed attributed string
        #if DEBUG
        if flash {
            // Flash with debug styling
            button.attributedTitle = themeManager.createMenuBarAttributedString(
                text: "⚡\(titleString)⚡",
                status: costStatus,
                isFlashing: true
            )
        } else if showColors {
            button.attributedTitle = themeManager.createMenuBarAttributedString(
                text: titleString,
                status: costStatus
            )
        } else {
            button.attributedTitle = themeManager.createMenuBarAttributedString(
                text: titleString,
                status: .normal
            )
        }
        #else
        if showColors {
            button.attributedTitle = themeManager.createMenuBarAttributedString(
                text: titleString,
                status: costStatus
            )
        } else {
            button.attributedTitle = themeManager.createMenuBarAttributedString(
                text: titleString,
                status: .normal
            )
        }
        #endif
    }
    
    // Legacy color method replaced by theme-aware ThemedMenuBarDisplay.getStatus()
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - Popover Content View with Full Rendering

