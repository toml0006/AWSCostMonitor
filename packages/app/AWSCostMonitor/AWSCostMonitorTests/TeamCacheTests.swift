//
//  TeamCacheTests.swift
//  AWSCostMonitorTests
//
//  Tests for team cache functionality
//

import Testing
import Foundation
@testable import AWSCostMonitor

struct TeamCacheTests {
    
    // MARK: - Cache Key Generation Tests
    
    @Test func testCacheKeyGeneration() async throws {
        // Test basic key generation
        let key = CacheKeyGenerator.generateKey(
            accountId: "123456789012",
            year: 2025,
            month: 8,
            dataType: .mtdCosts
        )
        
        #expect(key == "cache-v1/123456789012/2025-08/mtd-costs.json.gz")
    }
    
    @Test func testCacheKeyGenerationWithDifferentDataTypes() async throws {
        let accountId = "123456789012"
        let year = 2025
        let month = 8
        
        let testCases: [(CacheDataType, String)] = [
            (.mtdCosts, "cache-v1/123456789012/2025-08/mtd-costs.json.gz"),
            (.dailyBreakdown, "cache-v1/123456789012/2025-08/daily-breakdown.json.gz"),
            (.serviceBreakdown, "cache-v1/123456789012/2025-08/service-breakdown.json.gz"),
            (.fullData, "cache-v1/123456789012/2025-08/full-data.json.gz")
        ]
        
        for (dataType, expectedKey) in testCases {
            let key = CacheKeyGenerator.generateKey(
                accountId: accountId,
                year: year,
                month: month,
                dataType: dataType
            )
            #expect(key == expectedKey)
        }
    }
    
    @Test func testCacheKeyGenerationWithCustomVersion() async throws {
        let key = CacheKeyGenerator.generateKey(
            accountId: "123456789012",
            year: 2025,
            month: 12,
            dataType: .fullData,
            version: "v2"
        )
        
        #expect(key == "cache-v2/123456789012/2025-12/full-data.json.gz")
    }
    
    @Test func testCacheKeyGenerationWithSingleDigitMonth() async throws {
        let key = CacheKeyGenerator.generateKey(
            accountId: "987654321098",
            year: 2025,
            month: 1,
            dataType: .mtdCosts
        )
        
        // Should pad single digit month with zero
        #expect(key == "cache-v1/987654321098/2025-01/mtd-costs.json.gz")
    }
    
    // MARK: - Cache Key Parsing Tests
    
    @Test func testCacheKeyParsing() async throws {
        let key = "cache-v1/123456789012/2025-08/mtd-costs.json.gz"
        let parsed = CacheKeyGenerator.parseKey(key)
        
        #expect(parsed != nil)
        #expect(parsed?.accountId == "123456789012")
        #expect(parsed?.year == 2025)
        #expect(parsed?.month == 8)
        #expect(parsed?.dataType == .mtdCosts)
    }
    
    @Test func testCacheKeyParsingInvalidFormats() async throws {
        let invalidKeys = [
            "invalid-key",
            "cache-v1/123456789012/2025-08", // Missing filename
            "cache-v1/123456789012/invalid-date/mtd-costs.json.gz",
            "cache-v1/123456789012/2025-13/mtd-costs.json.gz", // Invalid month
            "cache-v1/123456789012/2025-08/invalid-type.json.gz",
            "not-cache/123456789012/2025-08/mtd-costs.json.gz" // Wrong prefix
        ]
        
        for invalidKey in invalidKeys {
            let parsed = CacheKeyGenerator.parseKey(invalidKey)
            #expect(parsed == nil, "Key '\(invalidKey)' should be invalid")
        }
    }
    
    @Test func testCacheKeyRoundTrip() async throws {
        let originalAccountId = "123456789012"
        let originalYear = 2025
        let originalMonth = 8
        let originalDataType = CacheDataType.fullData
        
        let key = CacheKeyGenerator.generateKey(
            accountId: originalAccountId,
            year: originalYear,
            month: originalMonth,
            dataType: originalDataType
        )
        
        let parsed = CacheKeyGenerator.parseKey(key)
        #expect(parsed != nil)
        #expect(parsed?.accountId == originalAccountId)
        #expect(parsed?.year == originalYear)
        #expect(parsed?.month == originalMonth)
        #expect(parsed?.dataType == originalDataType)
    }
    
    // MARK: - Team Cache Configuration Tests
    
    @Test func testTeamCacheConfigValidation() async throws {
        // Valid configuration
        var validConfig = TeamCacheConfig(
            enabled: true,
            s3BucketName: "my-team-cache-bucket",
            s3Region: "us-east-1"
        )
        #expect(validConfig.isValid)
        
        // Invalid - enabled but empty bucket name
        var invalidConfig = TeamCacheConfig(
            enabled: true,
            s3BucketName: "",
            s3Region: "us-east-1"
        )
        #expect(!invalidConfig.isValid)
        
        // Invalid - enabled but empty region
        invalidConfig = TeamCacheConfig(
            enabled: true,
            s3BucketName: "my-bucket",
            s3Region: ""
        )
        #expect(!invalidConfig.isValid)
        
        // Valid - disabled (bucket name can be empty)
        validConfig = TeamCacheConfig(
            enabled: false,
            s3BucketName: "",
            s3Region: ""
        )
        #expect(!validConfig.isValid) // Still invalid because enabled is required for validity
    }
    
    @Test func testTeamCacheConfigDefaults() async throws {
        let config = TeamCacheConfig()
        
        #expect(!config.enabled)
        #expect(config.s3BucketName.isEmpty)
        #expect(config.s3Region == "us-east-1")
        #expect(config.cachePrefix == "awscost-team-cache")
        #expect(config.ttlOverride == nil)
        #expect(!config.isValid)
    }
    
    // MARK: - Cache Metadata Tests
    
    @Test func testCacheMetadataExpiration() async throws {
        let ttl: TimeInterval = 3600 // 1 hour
        let pastDate = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let expiredMetadata = CacheMetadata(
            createdAt: pastDate,
            ttl: ttl,
            cacheKey: "test-key"
        )
        #expect(expiredMetadata.isExpired)
        
        let validMetadata = CacheMetadata(
            createdAt: Date(),
            ttl: ttl,
            cacheKey: "test-key"
        )
        #expect(!validMetadata.isExpired)
    }
    
    @Test func testCacheMetadataDefaults() async throws {
        let metadata = CacheMetadata(
            ttl: 3600,
            cacheKey: "test-key"
        )
        
        #expect(metadata.createdBy == "AWSCostMonitor")
        #expect(abs(metadata.createdAt.timeIntervalSinceNow) < 1) // Created just now
        #expect(metadata.ttl == 3600)
        #expect(metadata.cacheKey == "test-key")
        #expect(metadata.compressedSize == nil)
        #expect(metadata.uncompressedSize == nil)
    }
    
    // MARK: - Remote Cache Entry Tests
    
    @Test func testRemoteCacheEntryCreation() async throws {
        let dailyCosts = [
            DailyCost(date: Date(), amount: 10.50, currency: "USD"),
            DailyCost(date: Date().addingTimeInterval(-86400), amount: 15.25, currency: "USD")
        ]
        
        let serviceCosts = [
            ServiceCost(serviceName: "EC2", amount: 20.00, currency: "USD"),
            ServiceCost(serviceName: "S3", amount: 5.75, currency: "USD")
        ]
        
        let metadata = CacheMetadata(ttl: 3600, cacheKey: "test-cache-key")
        
        let entry = RemoteCacheEntry(
            profileName: "test-profile",
            accountId: "123456789012",
            mtdTotal: 25.75,
            currency: "USD",
            dailyCosts: dailyCosts,
            serviceCosts: serviceCosts,
            startDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            endDate: Date(),
            metadata: metadata
        )
        
        #expect(entry.profileName == "test-profile")
        #expect(entry.accountId == "123456789012")
        #expect(entry.mtdTotal == 25.75)
        #expect(entry.currency == "USD")
        #expect(entry.dailyCosts.count == 2)
        #expect(entry.serviceCosts.count == 2)
        #expect(entry.version == "1.0")
    }
    
    // MARK: - Cache Operation Result Tests
    
    @Test func testCacheOperationResultSuccess() async throws {
        let metadata = CacheMetadata(ttl: 3600, cacheKey: "test-key")
        let entry = RemoteCacheEntry(
            profileName: "test",
            accountId: "123",
            mtdTotal: 100,
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date(),
            metadata: metadata
        )
        
        let result = CacheOperationResult.success(entry)
        #expect(result.isSuccessful)
        #expect(result.entry != nil)
        #expect(result.entry?.profileName == "test")
    }
    
    @Test func testCacheOperationResultNotFound() async throws {
        let result = CacheOperationResult.notFound
        #expect(!result.isSuccessful)
        #expect(result.entry == nil)
    }
    
    @Test func testCacheOperationResultExpired() async throws {
        let metadata = CacheMetadata(ttl: 3600, cacheKey: "test-key")
        let entry = RemoteCacheEntry(
            profileName: "test",
            accountId: "123",
            mtdTotal: 100,
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date(),
            metadata: metadata
        )
        
        let result = CacheOperationResult.expired(entry)
        #expect(!result.isSuccessful)
        #expect(result.entry != nil)
        #expect(result.entry?.profileName == "test")
    }
    
    @Test func testCacheOperationResultError() async throws {
        let result = CacheOperationResult.error(.bucketNotFound)
        #expect(!result.isSuccessful)
        #expect(result.entry == nil)
    }
    
    // MARK: - Cache Statistics Tests
    
    @Test func testCacheStatisticsInitialization() async throws {
        let stats = CacheStatistics()
        
        #expect(stats.totalEntries == 0)
        #expect(stats.totalSizeBytes == 0)
        #expect(stats.lastAccessTime == nil)
        #expect(stats.cacheHits == 0)
        #expect(stats.cacheMisses == 0)
        #expect(stats.errors == 0)
        #expect(stats.hitRatio == 0.0)
    }
    
    @Test func testCacheStatisticsHitRatio() async throws {
        var stats = CacheStatistics()
        
        // Test with no hits or misses
        #expect(stats.hitRatio == 0.0)
        
        // Record some hits and misses
        stats.recordHit()
        stats.recordHit()
        stats.recordMiss()
        
        #expect(stats.cacheHits == 2)
        #expect(stats.cacheMisses == 1)
        #expect(abs(stats.hitRatio - 0.666666666666667) < 0.000001)
        #expect(stats.lastAccessTime != nil)
    }
    
    @Test func testCacheStatisticsErrorRecording() async throws {
        var stats = CacheStatistics()
        
        stats.recordError()
        stats.recordError()
        
        #expect(stats.errors == 2)
    }
}