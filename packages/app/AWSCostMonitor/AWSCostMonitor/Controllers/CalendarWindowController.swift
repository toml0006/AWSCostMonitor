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
    
    static func showCalendarWindow(awsManager: AWSManager, highlightedService: String? = nil, initialDate: Date? = nil) {
        // Use async dispatch to ensure proper window management after transitions
        DispatchQueue.main.async {
            // If window already exists: recreate it when a specific date was requested so
            // the calendar jumps to that date; otherwise just bring the existing one forward.
            if let existingWindow = windowController?.window, existingWindow.isVisible {
                if initialDate == nil {
                    existingWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    return
                }
                existingWindow.close()
                windowController = nil
            }

            // Create new window
            let calendarView = CalendarView(highlightedService: highlightedService, initialDate: initialDate)
                .environmentObject(awsManager)
            
            let hostingController = NSHostingController(rootView: calendarView)
            hostingController.sizingOptions = []

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
}