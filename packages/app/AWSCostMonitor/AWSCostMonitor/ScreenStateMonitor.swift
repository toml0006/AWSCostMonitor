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
    
    // MARK: - Initialization
    
    private init() {
        setupScreenStateMonitoring()
        setupLockStateMonitoring()
        setupCombinedState()
        
        // Check initial state
        checkCurrentScreenState()
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
    }
    
    private func handleScreenWake() {
        logger.info("Screen woke up")
        isScreenOn = true
    }
    
    private func handleSystemSleep() {
        logger.info("System is going to sleep")
        isScreenOn = false
    }
    
    private func handleSystemWake() {
        logger.info("System woke up")
        isScreenOn = true
        // Double-check screen state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkCurrentScreenState()
        }
    }
    
    // MARK: - Lock State Handlers
    
    @objc private func handleScreenLock() {
        logger.info("Screen locked")
        isSystemUnlocked = false
    }
    
    @objc private func handleScreenUnlock() {
        logger.info("Screen unlocked")
        isSystemUnlocked = true
    }
    
    @objc private func handleSessionSwitch() {
        logger.info("Session became active")
        isSystemUnlocked = true
    }
    
    @objc private func handleSessionInactive() {
        logger.info("Session became inactive")
        isSystemUnlocked = false
    }
    
    // MARK: - State Checking
    
    private func checkCurrentScreenState() {
        // Check if any screen is active
        let screens = NSScreen.screens
        isScreenOn = !screens.isEmpty
        
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
    
    // MARK: - Power Assertion (Optional)
    
    /// Check if the system is idle or if user is active
    func isUserActive() -> Bool {
        // Get idle time using IOKit
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .null
        )
        
        // Consider user active if there was input in the last 5 minutes
        let isActive = idleTime < 300 // 5 minutes
        
        logger.debug("User idle time: \(idleTime) seconds, active: \(isActive)")
        
        return isActive
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        if let observer = screenStateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        DistributedNotificationCenter.default().removeObserver(self)
        cancellables.removeAll()
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
