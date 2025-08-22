//
//  TeamCacheController.swift
//  AWSCostMonitor
//
//  Team cache policy enforcement and timer orchestration
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Team Cache Constants

enum TeamCacheConstants {
    static let AUTO_INTERVAL: TimeInterval = 6 * 60 * 60        // 6 hours
    static let MANUAL_COOLDOWN: TimeInterval = 30 * 60          // 30 minutes
    static let LEASE_TTL: TimeInterval = 120                    // 120 seconds
    static let JITTER_PERCENTAGE: Double = 0.1                  // ±10%
    static let STALE_YELLOW: TimeInterval = 12 * 60 * 60        // 12 hours
    static let STALE_RED: TimeInterval = 24 * 60 * 60           // 24 hours
    static let CHECK_INTERVAL: TimeInterval = 10 * 60           // Check every 10 minutes
}

// MARK: - Team Cache State

struct TeamCacheState: Codable {
    let teamId: String
    let lastRefreshedAt: Date?
    let refreshedBy: RefreshedBy?
    let nextAutoEligibleAt: Date
    let nextManualEligibleAt: Date
    let asOfDate: String?
    let version: Int
    
    var isManualRefreshEnabled: Bool {
        Date() >= nextManualEligibleAt
    }
    
    var timeUntilManualRefresh: TimeInterval {
        max(0, nextManualEligibleAt.timeIntervalSince(Date()))
    }
    
    var staleness: StalenessLevel {
        guard let lastRefreshedAt = lastRefreshedAt else { return .red }
        let age = Date().timeIntervalSince(lastRefreshedAt)
        
        if age <= TeamCacheConstants.STALE_YELLOW {
            return .green
        } else if age <= TeamCacheConstants.STALE_RED {
            return .yellow
        } else {
            return .red
        }
    }
    
    enum StalenessLevel {
        case green, yellow, red
        
        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .red: return .red
            }
        }
        
        var label: String {
            switch self {
            case .green: return "Fresh"
            case .yellow: return "Stale"
            case .red: return "Very Stale"
            }
        }
    }
}

struct RefreshedBy: Codable {
    let id: String
    let display: String
}

// MARK: - Soft Lock

struct SoftLock: Codable {
    let holder: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

// MARK: - Team Cache Controller

class TeamCacheController: ObservableObject {
    private let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "TeamCacheController")
    
    @Published var states: [String: TeamCacheState] = [:]  // Profile name -> state
    @Published var isRefreshing: [String: Bool] = [:]      // Profile name -> refreshing
    @Published var errorMessages: [String: String] = [:]   // Profile name -> error
    
    private let awsManager: AWSManager
    private var autoRefreshTimer: Timer?
    private var jitteredInterval: TimeInterval
    private let deviceId = UUID().uuidString  // Unique device/session ID for locking
    
    init(awsManager: AWSManager) {
        self.awsManager = awsManager
        
        // Calculate jittered interval once per session
        let jitter = Double.random(in: -TeamCacheConstants.JITTER_PERCENTAGE...TeamCacheConstants.JITTER_PERCENTAGE)
        self.jitteredInterval = TeamCacheConstants.AUTO_INTERVAL * (1 + jitter)
        
        logger.info("TeamCacheController initialized with jittered interval: \(Int(self.jitteredInterval / 60)) minutes")
    }
    
    // MARK: - Public Methods
    
    func startAutoRefreshTimer() {
        stopAutoRefreshTimer()
        
        // Start timer to check every CHECK_INTERVAL
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: TeamCacheConstants.CHECK_INTERVAL, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAndRefreshEligibleProfiles()
            }
        }
        
        logger.info("Auto-refresh timer started with check interval: \(Int(TeamCacheConstants.CHECK_INTERVAL / 60)) minutes")
    }
    
    func stopAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        logger.info("Auto-refresh timer stopped")
    }
    
    func manualRefresh(for profileName: String) async {
        guard let state = states[profileName], state.isManualRefreshEnabled else {
            logger.warning("Manual refresh not enabled for profile: \(profileName)")
            return
        }
        
        await performRefresh(for: profileName, reason: .manual)
    }
    
    func loadInitialState(for profileName: String) async {
        guard let cacheService = awsManager.teamCacheServices[profileName] else {
            logger.debug("No team cache service for profile: \(profileName)")
            return
        }
        
        do {
            // Try to read existing cache.json
            let accountId = profileName // Use profile name as account ID for now
            let cacheKey = "teams/\(accountId)/cache.json"
            
            let result = try await cacheService.getObject(key: cacheKey)
            
            switch result {
            case .success(let entry):
                // Convert RemoteCacheEntry to TeamCacheState
                let state = TeamCacheState(
                    teamId: accountId,
                    lastRefreshedAt: entry.fetchDate,
                    refreshedBy: RefreshedBy(id: deviceId, display: NSFullUserName()),
                    nextAutoEligibleAt: entry.fetchDate.addingTimeInterval(TeamCacheConstants.AUTO_INTERVAL),
                    nextManualEligibleAt: entry.fetchDate.addingTimeInterval(TeamCacheConstants.MANUAL_COOLDOWN),
                    asOfDate: ISO8601DateFormatter().string(from: entry.fetchDate),
                    version: Int(entry.version) ?? 0
                )
                states[profileName] = state
                logger.info("Loaded team cache state for profile: \(profileName)")
                
            case .notFound:
                // Initialize default state
                let now = Date()
                let state = TeamCacheState(
                    teamId: accountId,
                    lastRefreshedAt: nil,
                    refreshedBy: nil,
                    nextAutoEligibleAt: now,
                    nextManualEligibleAt: now,
                    asOfDate: nil,
                    version: 0
                )
                states[profileName] = state
                logger.info("Initialized default team cache state for profile: \(profileName)")
                
            case .expired:
                // Treat as needing refresh
                let now = Date()
                let state = TeamCacheState(
                    teamId: accountId,
                    lastRefreshedAt: nil,
                    refreshedBy: nil,
                    nextAutoEligibleAt: now,
                    nextManualEligibleAt: now,
                    asOfDate: nil,
                    version: 0
                )
                states[profileName] = state
                logger.info("Cache expired, initialized refresh state for profile: \(profileName)")
                
            case .expired:
                // Treat as needing refresh
                let now = Date()
                let state = TeamCacheState(
                    teamId: accountId,
                    lastRefreshedAt: nil,
                    refreshedBy: nil,
                    nextAutoEligibleAt: now,
                    nextManualEligibleAt: now,
                    asOfDate: nil,
                    version: 0
                )
                states[profileName] = state
                logger.info("Cache expired, initialized refresh state for profile: \(profileName)")
                
            case .error(let cacheError):
                // Handle error case
                logger.error("Failed to load team cache state: \(cacheError.localizedDescription)")
                errorMessages[profileName] = cacheError.localizedDescription
                // Initialize default state on error
                let now = Date()
                let state = TeamCacheState(
                    teamId: accountId,
                    lastRefreshedAt: nil,
                    refreshedBy: nil,
                    nextAutoEligibleAt: now,
                    nextManualEligibleAt: now,
                    asOfDate: nil,
                    version: 0
                )
                states[profileName] = state
            }
        } catch {
            logger.error("Failed to load team cache state for \(profileName): \(error.localizedDescription)")
            errorMessages[profileName] = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    
    private enum RefreshReason {
        case auto, manual
    }
    
    private func checkAndRefreshEligibleProfiles() async {
        let now = Date()
        
        for (profileName, state) in states {
            // Check if auto-refresh is eligible
            if now >= state.nextAutoEligibleAt {
                await performRefresh(for: profileName, reason: .auto)
            }
        }
    }
    
    private func performRefresh(for profileName: String, reason: RefreshReason) async {
        guard !isRefreshing[profileName, default: false] else {
            logger.debug("Already refreshing profile: \(profileName)")
            return
        }
        
        guard let cacheService = awsManager.teamCacheServices[profileName] else {
            logger.warning("No team cache service for profile: \(profileName)")
            return
        }
        
        isRefreshing[profileName] = true
        defer { isRefreshing[profileName] = false }
        
        let accountId = profileName // Use profile name as account ID for now
        let lockKey = "teams/\(accountId)/cache.lock"
        
        do {
            // Try to acquire lock
            let lockAcquired = await tryAcquireLock(cacheService: cacheService, lockKey: lockKey)
            
            guard lockAcquired else {
                logger.info("Could not acquire lock for profile: \(profileName)")
                return
            }
            
            defer {
                // Release lock
                Task {
                    await releaseLock(cacheService: cacheService, lockKey: lockKey)
                }
            }
            
            logger.info("Lock acquired, refreshing costs for profile: \(profileName), reason: \(String(describing: reason))")
            
            // Trigger cost refresh through AWSManager
            await awsManager.fetchCostForSelectedProfile(force: true)
            
            // Update state with new refresh times
            let now = Date()
            let newState = TeamCacheState(
                teamId: accountId,
                lastRefreshedAt: now,
                refreshedBy: RefreshedBy(id: deviceId, display: NSFullUserName()),
                nextAutoEligibleAt: now.addingTimeInterval(TeamCacheConstants.AUTO_INTERVAL),
                nextManualEligibleAt: now.addingTimeInterval(TeamCacheConstants.MANUAL_COOLDOWN),
                asOfDate: ISO8601DateFormatter().string(from: now),
                version: (states[profileName]?.version ?? 0) + 1
            )
            states[profileName] = newState
            
            // Write audit log if enabled
            if reason == .manual {
                await writeAuditLog(cacheService: cacheService, profileName: profileName, reason: reason)
            }
            
            logger.info("Successfully refreshed team cache for profile: \(profileName)")
            
        } catch {
            logger.error("Failed to refresh team cache for \(profileName): \(error.localizedDescription)")
            errorMessages[profileName] = error.localizedDescription
        }
    }
    
    private func tryAcquireLock(cacheService: S3CacheService, lockKey: String) async -> Bool {
        do {
            // Check if lock exists and is valid
            let lockExists = try await cacheService.headObject(key: lockKey)
            
            if lockExists {
                // Try to get the lock to check if it's expired
                let result = try await cacheService.getObject(key: lockKey)
                
                if case .success(let entry) = result {
                    // Try to decode the lock data from the entry
                    // We're repurposing the RemoteCacheEntry structure for locks
                    if let firstDailyCost = entry.dailyCosts.first {
                        let lockHolder = entry.accountId  // Account ID stores the holder
                        let expiresAt = firstDailyCost.date
                        
                        if Date() < expiresAt {
                            logger.debug("Lock is held by \(lockHolder) until \(expiresAt)")
                            return false
                        }
                    }
                }
            }
            
            // Try to acquire lock by creating a minimal RemoteCacheEntry
            let now = Date()
            let expiresAt = now.addingTimeInterval(TeamCacheConstants.LEASE_TTL)
            
            // Create a minimal lock entry using RemoteCacheEntry structure
            let lockEntry = RemoteCacheEntry(
                profileName: "lock",
                accountId: deviceId,
                fetchDate: now,
                mtdTotal: 0,
                currency: "USD",
                dailyCosts: [DailyCost(
                    date: expiresAt,
                    amount: 0,
                    currency: "USD"
                )],
                serviceCosts: [],
                startDate: now,
                endDate: expiresAt,
                version: "1.0",
                metadata: CacheMetadata(
                    createdBy: "TeamCacheController",
                    createdAt: now,
                    ttl: TeamCacheConstants.LEASE_TTL,
                    cacheKey: lockKey,
                    compressedSize: nil,
                    uncompressedSize: nil
                )
            )
            
            try await cacheService.putObject(key: lockKey, entry: lockEntry)
            logger.info("Successfully acquired lock with ID: \(self.deviceId)")
            return true
            
        } catch {
            logger.error("Failed to acquire lock: \(error.localizedDescription)")
            return false
        }
    }
    
    private func releaseLock(cacheService: S3CacheService, lockKey: String) async {
        do {
            // Release by setting expired lock
            let now = Date()
            let expiredAt = now.addingTimeInterval(-1)  // Already expired
            
            // Create an expired lock entry using RemoteCacheEntry structure
            let lockEntry = RemoteCacheEntry(
                profileName: "lock",
                accountId: deviceId,
                fetchDate: now,
                mtdTotal: 0,
                currency: "USD",
                dailyCosts: [DailyCost(
                    date: expiredAt,  // Expired time
                    amount: 0,
                    currency: "USD"
                )],
                serviceCosts: [],
                startDate: now,
                endDate: expiredAt,
                version: "1.0",
                metadata: CacheMetadata(
                    createdBy: "TeamCacheController",
                    createdAt: now,
                    ttl: 0,  // Expired
                    cacheKey: lockKey,
                    compressedSize: nil,
                    uncompressedSize: nil
                )
            )
            
            try await cacheService.putObject(key: lockKey, entry: lockEntry)
            logger.info("Released lock with ID: \(self.deviceId)")
            
        } catch {
            logger.error("Failed to release lock: \(error.localizedDescription)")
        }
    }
    
    private func writeAuditLog(cacheService: S3CacheService, profileName: String, reason: RefreshReason) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let uuid = UUID().uuidString
        let accountId = profileName // Use profile name as account ID for now
        let auditKey = "teams/\(accountId)/audit/\(dateString)/\(uuid).json"
        
        let now = Date()
        let reasonString = String(describing: reason)
        
        // Create audit entry using RemoteCacheEntry structure
        // Store audit info in the metadata
        let auditEntry = RemoteCacheEntry(
            profileName: profileName,
            accountId: accountId,
            fetchDate: now,
            mtdTotal: 0,
            currency: "USD",
            dailyCosts: [DailyCost(
                date: now,
                amount: 0,
                currency: "USD"
            )],
            serviceCosts: [ServiceCost(
                serviceName: reasonString,  // Store reason in serviceName
                amount: 0,
                currency: "USD"
            )],
            startDate: now,
            endDate: now.addingTimeInterval(365 * 24 * 60 * 60), // 1 year retention
            version: "audit-1.0",
            metadata: CacheMetadata(
                createdBy: "TeamCacheController-Audit",
                createdAt: now,
                ttl: 365 * 24 * 60 * 60,  // 1 year
                cacheKey: auditKey,
                compressedSize: nil,
                uncompressedSize: nil
            )
        )
        
        do {
            try await cacheService.putObject(key: auditKey, entry: auditEntry)
            logger.debug("Wrote audit log: \(auditKey)")
            
        } catch {
            logger.error("Failed to write audit log: \(error.localizedDescription)")
        }
    }
}