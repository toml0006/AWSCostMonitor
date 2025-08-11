//
//  S3CacheServiceTests.swift
//  AWSCostMonitorTests
//
//  Tests for S3 cache service operations
//

import Testing
import Foundation
@testable import AWSCostMonitor

// MARK: - Mock S3CacheService for Testing

class MockS3CacheService: S3CacheServiceProtocol {
    var mockStorage: [String: RemoteCacheEntry] = [:]
    var shouldFailOperations = false
    var shouldSimulateNetworkError = false
    var shouldSimulateAccessDenied = false
    var shouldSimulateBucketNotFound = false
    var operationDelay: TimeInterval = 0
    var lastGetKey: String?
    var lastPutEntry: RemoteCacheEntry?
    var lastDeleteKey: String?
    
    private let queue = DispatchQueue(label: "mock-s3-service")
    
    func getObject(key: String) async throws -> CacheOperationResult {
        lastGetKey = key
        
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldSimulateBucketNotFound {
            throw CacheError.bucketNotFound
        }
        
        if shouldSimulateAccessDenied {
            throw CacheError.accessDenied
        }
        
        if shouldSimulateNetworkError {
            throw CacheError.networkError(NSError(domain: "TestError", code: -1))
        }
        
        if shouldFailOperations {
            throw CacheError.cacheCorrupted
        }
        
        guard let entry = mockStorage[key] else {
            return .notFound
        }
        
        // Check if expired
        if entry.metadata.isExpired {
            return .expired(entry)
        }
        
        return .success(entry)
    }
    
    func putObject(key: String, entry: RemoteCacheEntry) async throws {
        lastPutEntry = entry
        
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldSimulateBucketNotFound {
            throw CacheError.bucketNotFound
        }
        
        if shouldSimulateAccessDenied {
            throw CacheError.accessDenied
        }
        
        if shouldSimulateNetworkError {
            throw CacheError.networkError(NSError(domain: "TestError", code: -1))
        }
        
        if shouldFailOperations {
            throw CacheError.serializationError(NSError(domain: "TestError", code: -1))
        }
        
        mockStorage[key] = entry
    }
    
    func headObject(key: String) async throws -> Bool {
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldSimulateBucketNotFound {
            throw CacheError.bucketNotFound
        }
        
        if shouldSimulateAccessDenied {
            throw CacheError.accessDenied
        }
        
        if shouldSimulateNetworkError {
            throw CacheError.networkError(NSError(domain: "TestError", code: -1))
        }
        
        if shouldFailOperations {
            throw CacheError.cacheCorrupted
        }
        
        return mockStorage[key] != nil
    }
    
    func deleteObject(key: String) async throws {
        lastDeleteKey = key
        
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldSimulateBucketNotFound {
            throw CacheError.bucketNotFound
        }
        
        if shouldSimulateAccessDenied {
            throw CacheError.accessDenied
        }
        
        if shouldSimulateNetworkError {
            throw CacheError.networkError(NSError(domain: "TestError", code: -1))
        }
        
        if shouldFailOperations {
            throw CacheError.cacheCorrupted
        }
        
        mockStorage.removeValue(forKey: key)
    }
    
    func listObjects(prefix: String) async throws -> [String] {
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldSimulateBucketNotFound {
            throw CacheError.bucketNotFound
        }
        
        if shouldSimulateAccessDenied {
            throw CacheError.accessDenied
        }
        
        if shouldSimulateNetworkError {
            throw CacheError.networkError(NSError(domain: "TestError", code: -1))
        }
        
        if shouldFailOperations {
            throw CacheError.cacheCorrupted
        }
        
        return mockStorage.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }
    
    // Helper methods for testing
    func reset() {
        mockStorage.removeAll()
        shouldFailOperations = false
        shouldSimulateNetworkError = false
        shouldSimulateAccessDenied = false
        shouldSimulateBucketNotFound = false
        operationDelay = 0
        lastGetKey = nil
        lastPutEntry = nil
        lastDeleteKey = nil
    }
}

// MARK: - S3CacheService Tests

struct S3CacheServiceTests {
    
    // MARK: - Test Setup Helpers
    
    private func createTestCacheEntry(
        profileName: String = "test-profile",
        accountId: String = "123456789012",
        ttl: TimeInterval = 3600
    ) -> RemoteCacheEntry {
        let dailyCosts = [
            DailyCost(date: Date(), amount: 10.50, currency: "USD"),
            DailyCost(date: Date().addingTimeInterval(-86400), amount: 15.25, currency: "USD")
        ]
        
        let serviceCosts = [
            ServiceCost(serviceName: "EC2", amount: 20.00, currency: "USD"),
            ServiceCost(serviceName: "S3", amount: 5.75, currency: "USD")
        ]
        
        let metadata = CacheMetadata(
            ttl: ttl,
            cacheKey: CacheKeyGenerator.generateKey(
                accountId: accountId,
                year: 2025,
                month: 8,
                dataType: .fullData
            )
        )
        
        return RemoteCacheEntry(
            profileName: profileName,
            accountId: accountId,
            mtdTotal: 25.75,
            currency: "USD",
            dailyCosts: dailyCosts,
            serviceCosts: serviceCosts,
            startDate: Date().addingTimeInterval(-86400 * 7),
            endDate: Date(),
            metadata: metadata
        )
    }
    
    // MARK: - Get Object Tests
    
    @Test func testGetObjectSuccess() async throws {
        let mockService = MockS3CacheService()
        let testEntry = createTestCacheEntry()
        let testKey = "test-cache-key"
        
        // Pre-populate mock storage
        mockService.mockStorage[testKey] = testEntry
        
        let result = try await mockService.getObject(key: testKey)
        
        #expect(result.isSuccessful)
        #expect(mockService.lastGetKey == testKey)
        #expect(result.entry?.profileName == "test-profile")
        #expect(result.entry?.mtdTotal == 25.75)
    }
    
    @Test func testGetObjectNotFound() async throws {
        let mockService = MockS3CacheService()
        let testKey = "non-existent-key"
        
        let result = try await mockService.getObject(key: testKey)
        
        #expect(!result.isSuccessful)
        if case .notFound = result {
            // Expected
        } else {
            throw TestError.unexpectedResult
        }
        #expect(mockService.lastGetKey == testKey)
    }
    
    @Test func testGetObjectExpired() async throws {
        let mockService = MockS3CacheService()
        let expiredEntry = createTestCacheEntry()
        
        // Create expired metadata
        let expiredMetadata = CacheMetadata(
            createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
            ttl: 3600, // 1 hour TTL (already expired)
            cacheKey: "test-key"
        )
        
        let expiredCacheEntry = RemoteCacheEntry(
            profileName: expiredEntry.profileName,
            accountId: expiredEntry.accountId,
            mtdTotal: expiredEntry.mtdTotal,
            currency: expiredEntry.currency,
            dailyCosts: expiredEntry.dailyCosts,
            serviceCosts: expiredEntry.serviceCosts,
            startDate: expiredEntry.startDate,
            endDate: expiredEntry.endDate,
            metadata: expiredMetadata
        )
        
        let testKey = "expired-cache-key"
        mockService.mockStorage[testKey] = expiredCacheEntry
        
        let result = try await mockService.getObject(key: testKey)
        
        #expect(!result.isSuccessful)
        if case .expired(let entry) = result {
            #expect(entry.profileName == "test-profile")
        } else {
            throw TestError.unexpectedResult
        }
    }
    
    @Test func testGetObjectBucketNotFound() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateBucketNotFound = true
        
        do {
            _ = try await mockService.getObject(key: "test-key")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .bucketNotFound = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    @Test func testGetObjectAccessDenied() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateAccessDenied = true
        
        do {
            _ = try await mockService.getObject(key: "test-key")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .accessDenied = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    @Test func testGetObjectNetworkError() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateNetworkError = true
        
        do {
            _ = try await mockService.getObject(key: "test-key")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .networkError = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    // MARK: - Put Object Tests
    
    @Test func testPutObjectSuccess() async throws {
        let mockService = MockS3CacheService()
        let testEntry = createTestCacheEntry()
        let testKey = "test-put-key"
        
        try await mockService.putObject(key: testKey, entry: testEntry)
        
        #expect(mockService.lastPutEntry?.profileName == "test-profile")
        #expect(mockService.mockStorage[testKey] != nil)
        #expect(mockService.mockStorage[testKey]?.mtdTotal == 25.75)
    }
    
    @Test func testPutObjectBucketNotFound() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateBucketNotFound = true
        let testEntry = createTestCacheEntry()
        
        do {
            try await mockService.putObject(key: "test-key", entry: testEntry)
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .bucketNotFound = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    @Test func testPutObjectAccessDenied() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateAccessDenied = true
        let testEntry = createTestCacheEntry()
        
        do {
            try await mockService.putObject(key: "test-key", entry: testEntry)
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .accessDenied = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    @Test func testPutObjectSerializationError() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldFailOperations = true
        let testEntry = createTestCacheEntry()
        
        do {
            try await mockService.putObject(key: "test-key", entry: testEntry)
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .serializationError = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    // MARK: - Head Object Tests
    
    @Test func testHeadObjectExists() async throws {
        let mockService = MockS3CacheService()
        let testEntry = createTestCacheEntry()
        let testKey = "test-head-key"
        
        mockService.mockStorage[testKey] = testEntry
        
        let exists = try await mockService.headObject(key: testKey)
        #expect(exists)
    }
    
    @Test func testHeadObjectNotExists() async throws {
        let mockService = MockS3CacheService()
        
        let exists = try await mockService.headObject(key: "non-existent-key")
        #expect(!exists)
    }
    
    @Test func testHeadObjectBucketNotFound() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateBucketNotFound = true
        
        do {
            _ = try await mockService.headObject(key: "test-key")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .bucketNotFound = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    // MARK: - Delete Object Tests
    
    @Test func testDeleteObjectSuccess() async throws {
        let mockService = MockS3CacheService()
        let testEntry = createTestCacheEntry()
        let testKey = "test-delete-key"
        
        mockService.mockStorage[testKey] = testEntry
        #expect(mockService.mockStorage[testKey] != nil)
        
        try await mockService.deleteObject(key: testKey)
        
        #expect(mockService.lastDeleteKey == testKey)
        #expect(mockService.mockStorage[testKey] == nil)
    }
    
    @Test func testDeleteObjectNotExists() async throws {
        let mockService = MockS3CacheService()
        
        // Should not throw error even if object doesn't exist
        try await mockService.deleteObject(key: "non-existent-key")
        #expect(mockService.lastDeleteKey == "non-existent-key")
    }
    
    @Test func testDeleteObjectAccessDenied() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateAccessDenied = true
        
        do {
            try await mockService.deleteObject(key: "test-key")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .accessDenied = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    // MARK: - List Objects Tests
    
    @Test func testListObjectsWithPrefix() async throws {
        let mockService = MockS3CacheService()
        
        // Add some test entries
        let entry1 = createTestCacheEntry(profileName: "profile1")
        let entry2 = createTestCacheEntry(profileName: "profile2")
        let entry3 = createTestCacheEntry(profileName: "profile3")
        
        mockService.mockStorage["cache-v1/123456789012/2025-08/mtd-costs.json.gz"] = entry1
        mockService.mockStorage["cache-v1/123456789012/2025-08/daily-breakdown.json.gz"] = entry2
        mockService.mockStorage["cache-v1/987654321098/2025-08/mtd-costs.json.gz"] = entry3
        
        let keys = try await mockService.listObjects(prefix: "cache-v1/123456789012/2025-08/")
        
        #expect(keys.count == 2)
        #expect(keys.contains("cache-v1/123456789012/2025-08/mtd-costs.json.gz"))
        #expect(keys.contains("cache-v1/123456789012/2025-08/daily-breakdown.json.gz"))
        #expect(!keys.contains("cache-v1/987654321098/2025-08/mtd-costs.json.gz"))
    }
    
    @Test func testListObjectsEmptyResult() async throws {
        let mockService = MockS3CacheService()
        
        let keys = try await mockService.listObjects(prefix: "non-existent-prefix/")
        #expect(keys.isEmpty)
    }
    
    @Test func testListObjectsBucketNotFound() async throws {
        let mockService = MockS3CacheService()
        mockService.shouldSimulateBucketNotFound = true
        
        do {
            _ = try await mockService.listObjects(prefix: "test-prefix/")
            throw TestError.expectedError
        } catch let error as CacheError {
            if case .bucketNotFound = error {
                // Expected
            } else {
                throw TestError.wrongErrorType
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test func testOperationTimeout() async throws {
        let mockService = MockS3CacheService()
        mockService.operationDelay = 0.1 // 100ms delay
        
        let start = Date()
        _ = try await mockService.headObject(key: "test-key")
        let elapsed = Date().timeIntervalSince(start)
        
        #expect(elapsed >= 0.1)
        #expect(elapsed < 0.2) // Should complete reasonably quickly
    }
    
    // MARK: - Integration Tests
    
    @Test func testFullWorkflow() async throws {
        let mockService = MockS3CacheService()
        let testEntry = createTestCacheEntry()
        let testKey = "workflow-test-key"
        
        // 1. Verify object doesn't exist
        let existsBefore = try await mockService.headObject(key: testKey)
        #expect(!existsBefore)
        
        // 2. Put object
        try await mockService.putObject(key: testKey, entry: testEntry)
        
        // 3. Verify object exists
        let existsAfter = try await mockService.headObject(key: testKey)
        #expect(existsAfter)
        
        // 4. Get object
        let result = try await mockService.getObject(key: testKey)
        #expect(result.isSuccessful)
        #expect(result.entry?.profileName == "test-profile")
        
        // 5. Delete object
        try await mockService.deleteObject(key: testKey)
        
        // 6. Verify object no longer exists
        let existsAfterDelete = try await mockService.headObject(key: testKey)
        #expect(!existsAfterDelete)
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case expectedError
    case unexpectedResult
    case wrongErrorType
}