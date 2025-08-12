//
//  TeamCacheModels.swift
//  AWSCostMonitor
//
//  Team cache-related data models
//  PREMIUM FEATURE: Some models only available in builds with PREMIUM_FEATURES=1
//

import Foundation

// MARK: - Team Cache Configuration

struct TeamCacheConfig: Codable {
    var enabled: Bool
    var s3BucketName: String
    var s3Region: String
    var cachePrefix: String
    var ttlOverride: TimeInterval?
    var encryptionType: S3EncryptionType
    var kmsKeyId: String?
    var enableAuditLogging: Bool
    
    init(
        enabled: Bool = false,
        s3BucketName: String = "",
        s3Region: String = "us-east-1",
        cachePrefix: String = "awscost-team-cache",
        ttlOverride: TimeInterval? = nil,
        encryptionType: S3EncryptionType = .sseS3,
        kmsKeyId: String? = nil,
        enableAuditLogging: Bool = true
    ) {
        self.enabled = enabled
        self.s3BucketName = s3BucketName
        self.s3Region = s3Region
        self.cachePrefix = cachePrefix
        self.ttlOverride = ttlOverride
        self.encryptionType = encryptionType
        self.kmsKeyId = kmsKeyId
        self.enableAuditLogging = enableAuditLogging
    }
    
    var isValid: Bool {
        return enabled && !s3BucketName.isEmpty && !s3Region.isEmpty
    }
}

// MARK: - Profile Team Cache Settings

struct ProfileTeamCacheSettings: Codable {
    var teamCacheEnabled: Bool
    var teamCacheConfig: TeamCacheConfig?
    
    init(teamCacheEnabled: Bool = false, teamCacheConfig: TeamCacheConfig? = nil) {
        self.teamCacheEnabled = teamCacheEnabled
        self.teamCacheConfig = teamCacheConfig
    }
}

// MARK: - Remote Cache Entry

struct RemoteCacheEntry: Codable {
    let profileName: String
    let accountId: String
    let fetchDate: Date
    let mtdTotal: Decimal
    let currency: String
    let dailyCosts: [DailyCost]
    let serviceCosts: [ServiceCost]
    let startDate: Date
    let endDate: Date
    let version: String
    let metadata: CacheMetadata
    
    init(
        profileName: String,
        accountId: String,
        fetchDate: Date = Date(),
        mtdTotal: Decimal,
        currency: String,
        dailyCosts: [DailyCost],
        serviceCosts: [ServiceCost],
        startDate: Date,
        endDate: Date,
        version: String = "1.0",
        metadata: CacheMetadata
    ) {
        self.profileName = profileName
        self.accountId = accountId
        self.fetchDate = fetchDate
        self.mtdTotal = mtdTotal
        self.currency = currency
        self.dailyCosts = dailyCosts
        self.serviceCosts = serviceCosts
        self.startDate = startDate
        self.endDate = endDate
        self.version = version
        self.metadata = metadata
    }
}

// MARK: - Cache Metadata

struct CacheMetadata: Codable {
    let createdBy: String // App identifier
    let createdAt: Date
    let ttl: TimeInterval
    let cacheKey: String
    let compressedSize: Int?
    let uncompressedSize: Int?
    
    init(
        createdBy: String = "AWSCostMonitor",
        createdAt: Date = Date(),
        ttl: TimeInterval,
        cacheKey: String,
        compressedSize: Int? = nil,
        uncompressedSize: Int? = nil
    ) {
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.ttl = ttl
        self.cacheKey = cacheKey
        self.compressedSize = compressedSize
        self.uncompressedSize = uncompressedSize
    }
    
    var isExpired: Bool {
        return Date().timeIntervalSince(createdAt) > ttl
    }
}

// MARK: - Cache Key Generator

struct CacheKeyGenerator {
    static func generateKey(
        accountId: String,
        year: Int,
        month: Int,
        dataType: CacheDataType,
        version: String = "v1"
    ) -> String {
        let monthStr = String(format: "%04d-%02d", year, month)
        return "cache-\(version)/\(accountId)/\(monthStr)/\(dataType.rawValue).json.gz"
    }
    
    static func parseKey(_ key: String) -> (accountId: String, year: Int, month: Int, dataType: CacheDataType)? {
        let components = key.split(separator: "/")
        guard components.count >= 4 else { return nil }
        
        // Extract version prefix (e.g., "cache-v1")
        guard components[0].hasPrefix("cache-v") else { return nil }
        
        let accountId = String(components[1])
        let dateStr = String(components[2])
        let fileStr = String(components[3])
        
        // Parse date (YYYY-MM)
        let dateComponents = dateStr.split(separator: "-")
        guard dateComponents.count == 2,
              let year = Int(dateComponents[0]),
              let month = Int(dateComponents[1]) else { return nil }
        
        // Parse data type from filename (remove .json.gz)
        let dataTypeStr = fileStr.replacingOccurrences(of: ".json.gz", with: "")
        guard let dataType = CacheDataType(rawValue: dataTypeStr) else { return nil }
        
        return (accountId: accountId, year: year, month: month, dataType: dataType)
    }
}

// MARK: - Cache Data Types

enum CacheDataType: String, Codable, CaseIterable {
    case mtdCosts = "mtd-costs"
    case dailyBreakdown = "daily-breakdown"
    case serviceBreakdown = "service-breakdown"
    case fullData = "full-data"
}

// MARK: - Cache Operation Result

enum CacheOperationResult {
    case success(RemoteCacheEntry)
    case notFound
    case expired(RemoteCacheEntry)
    case error(CacheError)
    
    var isSuccessful: Bool {
        if case .success = self { return true }
        return false
    }
    
    var entry: RemoteCacheEntry? {
        switch self {
        case .success(let entry), .expired(let entry):
            return entry
        case .notFound, .error:
            return nil
        }
    }
}

// MARK: - Cache Errors

enum CacheError: Error, LocalizedError {
    case invalidConfiguration
    case bucketNotFound
    case accessDenied
    case networkError(Error)
    case serializationError(Error)
    case compressionError(Error)
    case invalidCacheKey
    case cacheCorrupted
    case premiumFeatureRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid team cache configuration. Please check S3 bucket name and region."
        case .bucketNotFound:
            return "S3 bucket not found. Please verify the bucket exists and is accessible."
        case .accessDenied:
            return "Access denied to S3 bucket. Please check IAM permissions."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serializationError(let error):
            return "Failed to serialize/deserialize cache data: \(error.localizedDescription)"
        case .compressionError(let error):
            return "Failed to compress/decompress cache data: \(error.localizedDescription)"
        case .invalidCacheKey:
            return "Invalid cache key format"
        case .cacheCorrupted:
            return "Cache data is corrupted or invalid"
        case .premiumFeatureRequired:
            return "Team cache is a premium feature. Upgrade to Pro to enable team cost sharing."
        }
    }
}

// MARK: - S3 Encryption Types

enum S3EncryptionType: String, Codable, CaseIterable {
    case none = "none"
    case sseS3 = "AES256"
    case sseKms = "aws:kms"
    
    var displayName: String {
        switch self {
        case .none:
            return "No Encryption"
        case .sseS3:
            return "SSE-S3 (AES256)"
        case .sseKms:
            return "SSE-KMS (Customer Managed)"
        }
    }
}

// MARK: - IAM Permission Check Result

struct IAMPermissionCheckResult {
    let hasReadAccess: Bool
    let hasWriteAccess: Bool
    let hasListAccess: Bool
    let hasKMSAccess: Bool
    let missingPermissions: [String]
    let errors: [String]
    
    var isFullyPermissioned: Bool {
        return hasReadAccess && hasWriteAccess && hasListAccess
    }
    
    var permissionSummary: String {
        if isFullyPermissioned {
            return "All required permissions verified"
        }
        return "Missing permissions: \(missingPermissions.joined(separator: ", "))"
    }
}

// MARK: - Audit Log Entry

struct AuditLogEntry: Codable {
    let timestamp: Date
    let operation: String
    let profileName: String
    let accountId: String
    let cacheKey: String
    let success: Bool
    let errorMessage: String?
    let metadata: [String: String]
    
    init(
        operation: String,
        profileName: String,
        accountId: String,
        cacheKey: String,
        success: Bool,
        errorMessage: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = Date()
        self.operation = operation
        self.profileName = profileName
        self.accountId = accountId
        self.cacheKey = cacheKey
        self.success = success
        self.errorMessage = errorMessage
        self.metadata = metadata
    }
}

// MARK: - Cache Statistics

struct CacheStatistics: Codable {
    var totalEntries: Int = 0
    var totalSizeBytes: Int = 0
    var lastAccessTime: Date?
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var errors: Int = 0
    
    var hitRatio: Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    mutating func recordHit() {
        cacheHits += 1
        lastAccessTime = Date()
    }
    
    mutating func recordMiss() {
        cacheMisses += 1
        lastAccessTime = Date()
    }
    
    mutating func recordError() {
        errors += 1
    }
}