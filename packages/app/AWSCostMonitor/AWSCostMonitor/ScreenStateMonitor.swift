//
//  ScreenStateMonitor.swift
//  AWSCostMonitor
//
//  Monitors screen state and lock status to control refresh behavior
//

import Foundation
import AppKit
import Combine
import os.log
import ObjectiveC

/// Monitors system screen state and lock status
class ScreenStateMonitor: ObservableObject {
    static let shared = ScreenStateMonitor()
    
    // MARK: - Published Properties
    
    @Published var isScreenOn: Bool = true
    @Published var isSystemUnlocked: Bool = true
    @Published var canRefresh: Bool = true
    
    // MARK: - Private Properties
    
    private var screenStateObserver: Any?
    private var lockStateObserver: Any?
    private var workspaceNotificationObserver: Any?
    private var displayWrangler: Any?
    private let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "ScreenState")
    private var cancellables = Set<AnyCancellable>()
    private var userActivityTimer: DispatchSourceTimer?
    private let activityQueue = DispatchQueue(label: "com.awscostmonitor.userActivity", qos: .utility)
    private var lastUserActive: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        setupScreenStateMonitoring()
        setupLockStateMonitoring()
        setupCombinedState()
        
        // Check initial state
        checkCurrentScreenState()
        
        // Start monitoring user activity transitions (idle -> active)
        startUserActivityMonitoring()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Screen State Monitoring
    
    private func setupScreenStateMonitoring() {
        // Monitor display sleep/wake notifications
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Screen will sleep
        screenStateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenSleep()
        }
        
        // Screen did wake
        notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenWake()
        }
        
        // Also monitor system sleep/wake
        notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemSleep()
        }
        
        notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }
    }
    
    // MARK: - Lock State Monitoring
    
    private func setupLockStateMonitoring() {
        // Monitor screen lock/unlock using distributed notifications
        let distributedCenter = DistributedNotificationCenter.default()
        
        // Screen locked
        distributedCenter.addObserver(
            self,
            selector: #selector(handleScreenLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        // Screen unlocked
        distributedCenter.addObserver(
            self,
            selector: #selector(handleScreenUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        // Session events (Fast User Switching)
        distributedCenter.addObserver(
            self,
            selector: #selector(handleSessionSwitch),
            name: NSNotification.Name("com.apple.sessionDidBecomeActive"),
            object: nil
        )
        
        distributedCenter.addObserver(
            self,
            selector: #selector(handleSessionInactive),
            name: NSNotification.Name("com.apple.sessionDidResignActive"),
            object: nil
        )
    }
    
    // MARK: - Combined State Management
    
    private func setupCombinedState() {
        // Combine screen state and lock state to determine if refresh is allowed
        Publishers.CombineLatest($isScreenOn, $isSystemUnlocked)
            .map { screenOn, unlocked in
                return screenOn && unlocked
            }
            .sink { [weak self] canRefresh in
                self?.canRefresh = canRefresh
                self?.logger.info("Refresh state changed: \(canRefresh ? "enabled" : "disabled") (screen: \(self?.isScreenOn ?? false), unlocked: \(self?.isSystemUnlocked ?? false))")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Screen State Handlers
    
    private func handleScreenSleep() {
        logger.info("Screen is going to sleep")
        isScreenOn = false
        notifyScreenStateChanged()
    }
    
    private func handleScreenWake() {
        logger.info("Screen woke up")
        isScreenOn = true
        notifyScreenStateChanged()
    }
    
    private func handleSystemSleep() {
        logger.info("System is going to sleep")
        isScreenOn = false
        notifyScreenStateChanged()
    }
    
    private func handleSystemWake() {
        logger.info("System woke up")
        isScreenOn = true
        notifyScreenStateChanged()
        // Double-check screen state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkCurrentScreenState()
        }
    }
    
    // MARK: - Lock State Handlers
    
    @objc private func handleScreenLock() {
        logger.info("Screen locked")
        isSystemUnlocked = false
        notifyScreenStateChanged()
    }
    
    @objc private func handleScreenUnlock() {
        logger.info("Screen unlocked")
        isSystemUnlocked = true
        notifyScreenStateChanged()
    }
    
    @objc private func handleSessionSwitch() {
        logger.info("Session became active")
        isSystemUnlocked = true
        notifyScreenStateChanged()
    }
    
    @objc private func handleSessionInactive() {
        logger.info("Session became inactive")
        isSystemUnlocked = false
        notifyScreenStateChanged()
    }
    
    // MARK: - State Checking
    
    private func checkCurrentScreenState() {
        // Check if any screen is active
        let screens = NSScreen.screens
        isScreenOn = !screens.isEmpty
        notifyScreenStateChanged()
        
        // Additional check using CGDisplay
        if isScreenOn {
            var displayCount: UInt32 = 0
            var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
            
            let error = CGGetActiveDisplayList(16, &activeDisplays, &displayCount)
            if error == .success && displayCount > 0 {
                // Check if main display is asleep
                let mainDisplay = CGMainDisplayID()
                let isAsleep = CGDisplayIsAsleep(mainDisplay)
                isScreenOn = isAsleep == 0
            }
        }
        
        logger.info("Current screen state: \(self.isScreenOn ? "on" : "off")")
    }

    // Notify observers that effective screen/lock state changed
    private func notifyScreenStateChanged() {
        NotificationCenter.default.post(
            name: Notification.Name("ScreenStateChanged"),
            object: nil
        )
    }
    
    // MARK: - Power Assertion (Optional)
    
    /// Check if the system is idle or if user is active
    func isUserActive() -> Bool {
        // Get idle time using IOKit
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .null
        )
        
        // Consider user active if there was input in the last 30 minutes
        // For menu bar apps, we want to allow refreshes even when user is "idle"
        let isActive = idleTime < 1800 // 30 minutes
        
        logger.debug("User idle time: \(idleTime) seconds, active: \(isActive)")
        
        return isActive
    }
    
    // MARK: - User Activity Monitoring
    private func startUserActivityMonitoring() {
        let timer = DispatchSource.makeTimerSource(queue: activityQueue)
        userActivityTimer = timer
        // Check every 30 seconds to balance responsiveness and efficiency
        timer.schedule(deadline: .now() + 30, repeating: 30)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let active = self.isUserActive()
            DispatchQueue.main.async {
                if active != self.lastUserActive {
                    self.lastUserActive = active
                    let state = active ? "active" : "idle"
                    self.logger.info("User activity changed: \(state)")
                    // When user becomes active and other conditions allow, trigger catch-up
                    if active && self.isScreenOn && self.isSystemUnlocked && self.canRefresh {
                        self.notifyScreenStateChanged()
                    }
                }
            }
        }
        timer.resume()
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        if let observer = screenStateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        DistributedNotificationCenter.default().removeObserver(self)
        cancellables.removeAll()
        
        if let t = userActivityTimer {
            t.cancel()
            userActivityTimer = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Force a state check
    func refreshState() {
        checkCurrentScreenState()
    }
    
    /// Check if conditions are met for refresh
    func shouldAllowRefresh() -> Bool {
        // Additional checks beyond the basic canRefresh
        let userActive = isUserActive()
        let finalDecision = canRefresh && userActive
        
        if !finalDecision {
            logger.info("Refresh blocked: canRefresh=\(self.canRefresh), userActive=\(userActive)")
        }
        
        return finalDecision
    }
}

// MARK: - AWSManager Extension

extension AWSManager {
    /// Check if refresh should proceed based on screen state
    func shouldProceedWithRefresh() -> Bool {
        let screenMonitor = ScreenStateMonitor.shared
        return screenMonitor.shouldAllowRefresh()
    }
    
    /// Modified refresh method that checks screen state
    func refreshWithScreenCheck() async {
        guard shouldProceedWithRefresh() else {
            log(.info, category: "Refresh", "Refresh skipped: screen is off or system is locked")
            return
        }
        
        // Proceed with normal refresh
        await fetchCostForSelectedProfile()
    }
    
    /// Setup automatic refresh with screen state monitoring
    func setupScreenAwareRefresh() {
        // This method would need to access the internal cancellables property
        // For now, we'll implement this directly in the AWSManager class
        // rather than as an extension to avoid property access issues
    }
    
}
