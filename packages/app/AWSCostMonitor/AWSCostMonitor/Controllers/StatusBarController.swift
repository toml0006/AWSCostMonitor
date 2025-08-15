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
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(awsManager: AWSManager) {
        self.awsManager = awsManager
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
        // Don't set UserDefaults here - it causes infinite recursion!
        
        var titleString = ""
        var titleColor: NSColor? = nil
        
        // Setup number formatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = useThousandsSeparator
        
        switch displayFormat {
        case "abbreviated":
            // No icon for abbreviated format
            button.image = nil
            if let cost = awsManager.costData.first {
                let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
                formatter.maximumFractionDigits = 0
                let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
                titleString = showCurrencySymbol ? "$\(formattedAmount)" : formattedAmount
                if showColors {
                    titleColor = getColorForCost(cost)
                }
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
                if showColors {
                    titleColor = getColorForCost(cost)
                }
            } else if awsManager.isLoading {
                titleString = "Loading..."
            } else {
                titleString = "AW$"
            }
            
        case "iconOnly":
            // Show colorful cloud icon only for icon-only mode
            button.image = MenuBarCloudIcon.createImage(size: 18)
            titleString = "" // No text when showing icon only
        
        default:
            button.image = nil
            titleString = "AW$"
        }
        
        // Apply the title with optional color and flash effect
        #if DEBUG
        if flash {
            // Flash with bright red when debug timer ticks
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.systemRed,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold),
                .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.3)
            ]
            button.attributedTitle = NSAttributedString(string: "⚡\(titleString)⚡", attributes: attributes)
        } else if showColors && titleColor != nil {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: titleColor!,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        } else {
            // Use regular title without color
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        }
        #else
        if showColors && titleColor != nil {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: titleColor!,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        } else {
            // Use regular title without color
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        }
        #endif
    }
    
    private func getColorForCost(_ cost: CostData) -> NSColor? {
        // Prioritize last month comparison over budget for better user feedback
        if let lastMonthCost = awsManager.lastMonthData[cost.profileName],
           lastMonthCost.amount > 0 {
            let currentAmount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let lastAmount = NSDecimalNumber(decimal: lastMonthCost.amount).doubleValue
            let percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
            
            // Green for spending less than last month (good)
            if percentChange < -5 {
                return NSColor.systemGreen
            }
            // Orange/Red for spending significantly more than last month (concerning)
            else if percentChange > 20 {
                return NSColor.systemRed
            }
            else if percentChange > 10 {
                return NSColor.systemOrange
            }
            // White/default for small changes (within normal range)
            else {
                return nil
            }
        }
        
        // Fallback to budget-based coloring if no last month data
        let budget = awsManager.getBudget(for: cost.profileName)
        if budget.monthlyBudget > 0 {
            let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let percentUsed = (amount / NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue) * 100
            if percentUsed >= 100 {
                return NSColor.systemRed
            } else if percentUsed >= 80 {
                return NSColor.systemOrange
            } else if percentUsed >= 60 {
                return NSColor.systemYellow
            } else {
                return NSColor.systemGreen
            }
        }
        
        // No color if no comparison data available
        return nil
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - Popover Content View with Full Rendering

