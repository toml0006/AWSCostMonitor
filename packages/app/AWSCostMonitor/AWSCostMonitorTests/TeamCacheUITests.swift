//
//  TeamCacheUITests.swift
//  AWSCostMonitorTests
//
//  Team Cache UI tests
//

import XCTest
import SwiftUI
@testable import AWSCostMonitor

class TeamCacheUITests: XCTestCase {
    var awsManager: AWSManager!
    
    override func setUp() {
        super.setUp()
        awsManager = AWSManager()
    }
    
    override func tearDown() {
        awsManager = nil
        super.tearDown()
    }
    
    func testTeamCacheSettingsTabCreation() {
        // Test that TeamCacheSettingsTab can be created without crashing
        let settingsTab = TeamCacheSettingsTab()
            .environmentObject(awsManager)
        
        XCTAssertNotNil(settingsTab)
    }
    
    func testCacheStatisticsFormatting() {
        // Test the byte formatting functionality
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        
        let testBytes = 1024 * 150 // 150 KB
        let result = formatter.string(fromByteCount: Int64(testBytes))
        XCTAssertTrue(result.contains("KB") || result.contains("MB"))
    }
    
    func testCacheStatisticsModel() {
        // Test the CacheStatistics model calculations
        var stats = CacheStatistics()
        
        // Test initial state
        XCTAssertEqual(stats.hitRatio, 0.0)
        XCTAssertEqual(stats.totalEntries, 0)
        XCTAssertEqual(stats.cacheHits, 0)
        XCTAssertEqual(stats.cacheMisses, 0)
        
        // Test hit ratio calculation
        stats.recordHit()
        stats.recordHit()
        stats.recordMiss()
        
        XCTAssertEqual(stats.cacheHits, 2)
        XCTAssertEqual(stats.cacheMisses, 1)
        XCTAssertEqual(stats.hitRatio, 2.0/3.0, accuracy: 0.001)
        
        // Test error recording
        stats.recordError()
        XCTAssertEqual(stats.errors, 1)
    }
    
    func testTeamCacheConfigModel() {
        // Test the TeamCacheConfig model
        var config = TeamCacheConfig()
        
        // Test default state
        XCTAssertFalse(config.enabled)
        XCTAssertFalse(config.isValid) // Should be invalid with empty bucket name
        
        // Test valid configuration
        config.enabled = true
        config.s3BucketName = "test-bucket"
        config.s3Region = "us-east-1"
        
        XCTAssertTrue(config.isValid)
        
        // Test invalid configuration (empty bucket)
        config.s3BucketName = ""
        XCTAssertFalse(config.isValid)
    }
    
    func testRemoteCacheEntryCreation() {
        // Test RemoteCacheEntry creation
        let metadata = CacheMetadata(ttl: 3600, cacheKey: "test-key")
        let entry = RemoteCacheEntry(
            profileName: "test-profile",
            accountId: "123456789012",
            mtdTotal: Decimal(100.50),
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date(),
            metadata: metadata
        )
        
        XCTAssertEqual(entry.profileName, "test-profile")
        XCTAssertEqual(entry.accountId, "123456789012")
        XCTAssertEqual(entry.mtdTotal, Decimal(100.50))
        XCTAssertEqual(entry.currency, "USD")
        XCTAssertFalse(entry.metadata.isExpired) // Should not be expired immediately
    }
    
    func testCacheKeyGeneration() {
        // Test cache key generation
        let key = CacheKeyGenerator.generateKey(
            accountId: "123456789012",
            year: 2025,
            month: 8,
            dataType: .mtdCosts
        )
        
        XCTAssertEqual(key, "cache-v1/123456789012/2025-08/mtd-costs.json.gz")
        
        // Test key parsing
        if let parsed = CacheKeyGenerator.parseKey(key) {
            XCTAssertEqual(parsed.accountId, "123456789012")
            XCTAssertEqual(parsed.year, 2025)
            XCTAssertEqual(parsed.month, 8)
            XCTAssertEqual(parsed.dataType, .mtdCosts)
        } else {
            XCTFail("Failed to parse generated cache key")
        }
    }
    
    func testCacheOperationResult() {
        // Test CacheOperationResult behavior
        let metadata = CacheMetadata(ttl: 3600, cacheKey: "test-key")
        let entry = RemoteCacheEntry(
            profileName: "test",
            accountId: "123456789012",
            mtdTotal: Decimal(0),
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date(),
            metadata: metadata
        )
        
        let successResult = CacheOperationResult.success(entry)
        XCTAssertTrue(successResult.isSuccessful)
        XCTAssertNotNil(successResult.entry)
        
        let notFoundResult = CacheOperationResult.notFound
        XCTAssertFalse(notFoundResult.isSuccessful)
        XCTAssertNil(notFoundResult.entry)
        
        let expiredResult = CacheOperationResult.expired(entry)
        XCTAssertFalse(expiredResult.isSuccessful)
        XCTAssertNotNil(expiredResult.entry)
    }
}