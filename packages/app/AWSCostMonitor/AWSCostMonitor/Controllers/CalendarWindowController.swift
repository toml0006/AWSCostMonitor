//
//  CalendarWindowController.swift
//  AWSCostMonitor
//
//  Window controller for the calendar view
//

import SwiftUI
import AppKit

class CalendarWindowController {
    private static var windowController: NSWindowController?
    
    static func showCalendarWindow(awsManager: AWSManager, highlightedService: String? = nil) {
        // If window already exists, bring it to front
        if let existingWindow = windowController?.window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let calendarView = CalendarView(highlightedService: highlightedService)
            .environmentObject(awsManager)
        
        let hostingController = NSHostingController(rootView: calendarView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "AWS Cost Calendar"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("CalendarWindow")
        window.isReleasedWhenClosed = false
        window.level = .normal
        
        // Set minimum size
        window.minSize = NSSize(width: 800, height: 600)
        
        // Create window controller
        let controller = NSWindowController(window: window)
        windowController = controller
        
        // Show window
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Clean up reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            windowController = nil
        }
    }
}