//
//  AppDelegates.swift
//  AWSCostMonitor
//
//  App and window delegates
//

import Foundation
import AppKit
import SwiftUI
import OSLog

class WindowCloseDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// Store export window reference globally
var globalExportWindow: NSWindow?
var globalExportDelegate: WindowCloseDelegate?

// Helper function to show export window
func showExportWindow(awsManager: AWSManager) {
    // Check if export window is already open
    if let window = globalExportWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    // Create new export window
    let exportView = ExportView(awsManager: awsManager)
        .environmentObject(awsManager)
    
    let hostingController = NSHostingController(rootView: exportView)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Export Cost Data"
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.setContentSize(NSSize(width: 500, height: 600))
    window.center()
    
    globalExportWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    // Clear reference when window closes
    globalExportDelegate = WindowCloseDelegate {
        globalExportWindow = nil
        globalExportDelegate = nil
    }
    window.delegate = globalExportDelegate
}

// Store settings window reference globally
var globalSettingsWindow: NSWindow?

// Helper function to show settings window
func showSettingsWindowForApp(awsManager: AWSManager, selectedTab: String = "Profiles") {
    // Use async dispatch to ensure proper window management after transitions
    DispatchQueue.main.async {
        if let window = globalSettingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(initialSelectedCategory: selectedTab)
            .environmentObject(awsManager)
        
        let controller = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentViewController: controller
        )
        window.title = "AWSCostMonitor Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 450))
        window.center()
        
        // Clean up reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            globalSettingsWindow = nil
        }
        
        globalSettingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Helper function to show refresh settings specifically
func showRefreshSettingsForApp(awsManager: AWSManager) {
    showSettingsWindowForApp(awsManager: awsManager, selectedTab: "Refresh Rate")
}

// MARK: - App Delegate for NSStatusItem Management

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the status bar controller with a small delay to ensure proper setup
        DispatchQueue.main.async { [weak self] in
            self?.statusBarController = StatusBarController(awsManager: AWSManager.shared)
        }
        
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
