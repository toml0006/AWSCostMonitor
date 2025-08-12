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
func showSettingsWindowForApp(awsManager: AWSManager) {
    if let window = globalSettingsWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    let settingsView = SettingsView()
        .environmentObject(awsManager)
    
    let controller = NSHostingController(rootView: settingsView)
    
    let window = NSWindow(
        contentViewController: controller
    )
    window.title = "AWS Cost Monitor Settings"
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.setContentSize(NSSize(width: 600, height: 450))
    window.center()
    
    globalSettingsWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

// MARK: - App Delegate for NSStatusItem Management

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the status bar controller
        statusBarController = StatusBarController(awsManager: AWSManager.shared)
        
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
