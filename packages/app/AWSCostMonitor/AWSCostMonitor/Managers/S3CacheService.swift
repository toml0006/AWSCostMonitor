//
//  S3CacheService.swift
//  AWSCostMonitor
//
//  S3-based remote cache service for team cache functionality
//

import Foundation
import OSLog
import AWSS3
import AWSClientRuntime
import Compression
import ClientRuntime

// MARK: - S3CacheService Protocol

protocol S3CacheServiceProtocol {
    func getObject(key: String) async throws -> CacheOperationResult
    func putObject(key: String, entry: RemoteCacheEntry) async throws
    func headObject(key: String) async throws -> Bool
    func deleteObject(key: String) async throws
    func listObjects(prefix: String) async throws -> [String]
}

// MARK: - S3CacheService Implementation

@MainActor
class S3CacheService: ObservableObject, S3CacheServiceProtocol {
    private let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "S3CacheService")
    private let config: TeamCacheConfig
    private let s3Client: S3Client
    private let retryPolicy: RetryPolicy
    
    @Published var statistics = CacheStatistics()
    @Published var isConnected = false
    @Published var lastError: CacheError?
    
    init(config: TeamCacheConfig) throws {
        guard config.isValid else {
            throw CacheError.invalidConfiguration
        }
        
        self.config = config
        self.retryPolicy = RetryPolicy()
        
        // Initialize S3 client with region and credentials
        let s3Config = try S3Client.S3ClientConfiguration(
            region: config.s3Region
        )
        self.s3Client = S3Client(config: s3Config)
        
        logger.info("S3CacheService initialized for bucket: \(config.s3BucketName), region: \(config.s3Region)")
    }
    
    // MARK: - Public Interface
    
    func getObject(key: String) async throws -> CacheOperationResult {
        let fullKey = buildFullKey(key)
        logger.debug("Getting object from S3: \(fullKey)")
        
        return try await retryPolicy.execute { [weak self] in
            guard let self = self else { throw CacheError.cacheCorrupted }
            
            do {
                let input = GetObjectInput(
                    bucket: self.config.s3BucketName,
                    key: fullKey
                )
                
                let output = try await self.s3Client.getObject(input: input)
                
                guard let body = output.body else {
                    self.logger.warning("S3 object body is empty for key: \(fullKey)")
                    self.statistics.recordMiss()
                    return .notFound
                }
                
                // Convert ByteStream to Data
                guard case let .data(bodyData) = body, let data = bodyData else {
                    throw CacheError.serializationError(NSError(domain: "S3CacheServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to read body data from S3 response"]))
                }
                
                // Decompress and deserialize
                let entry = try self.deserializeCacheEntry(from: data)
                
                // Check if expired
                if entry.metadata.isExpired {
                    self.logger.info("Cache entry expired for key: \(fullKey)")
                    self.statistics.recordMiss()
                    return .expired(entry)
                }
                
                self.logger.debug("Successfully retrieved cache entry for key: \(fullKey)")
                self.statistics.recordHit()
                self.isConnected = true
                return .success(entry)
                
            } catch let error {
                return try self.handleS3Error(error, operation: "getObject", key: fullKey)
            }
        }
    }
    
    func putObject(key: String, entry: RemoteCacheEntry) async throws {
        let fullKey = buildFullKey(key)
        logger.debug("Putting object to S3: \(fullKey)")
        
        try await retryPolicy.execute { [weak self] in
            guard let self = self else { throw CacheError.cacheCorrupted }
            
            do {
                // Serialize and compress the entry
                let data = try self.serializeCacheEntry(entry)
                
                let input = PutObjectInput(
                    body: .data(data),
                    bucket: self.config.s3BucketName,
                    key: fullKey,
                    metadata: [
                        "cache-version": entry.version,
                        "profile-name": entry.profileName,
                        "account-id": entry.accountId,
                        "created-by": entry.metadata.createdBy,
                        "ttl": String(entry.metadata.ttl)
                    ],
                    serverSideEncryption: .aes256 // Enable server-side encryption
                )
                
                _ = try await self.s3Client.putObject(input: input)
                
                self.logger.debug("Successfully stored cache entry for key: \(fullKey)")
                self.statistics.totalEntries += 1
                self.statistics.totalSizeBytes += data.count
                self.isConnected = true
                
            } catch let error {
                throw try self.mapS3Error(error, operation: "putObject", key: fullKey)
            }
        }
    }
    
    func headObject(key: String) async throws -> Bool {
        let fullKey = buildFullKey(key)
        logger.debug("Checking object existence in S3: \(fullKey)")
        
        return try await retryPolicy.execute { [weak self] in
            guard let self = self else { throw CacheError.cacheCorrupted }
            
            do {
                let input = HeadObjectInput(
                    bucket: self.config.s3BucketName,
                    key: fullKey
                )
                
                _ = try await self.s3Client.headObject(input: input)
                self.isConnected = true
                return true
                
            } catch let error {
                // Check if it's a no such key error (this would need proper error handling based on actual AWS SDK structure)
                if error.localizedDescription.contains("NoSuchKey") || error.localizedDescription.contains("NotFound") {
                    return false
                }
                throw try self.mapS3Error(error, operation: "headObject", key: fullKey)
            }
        }
    }
    
    func deleteObject(key: String) async throws {
        let fullKey = buildFullKey(key)
        logger.debug("Deleting object from S3: \(fullKey)")
        
        try await retryPolicy.execute { [weak self] in
            guard let self = self else { throw CacheError.cacheCorrupted }
            
            do {
                let input = DeleteObjectInput(
                    bucket: self.config.s3BucketName,
                    key: fullKey
                )
                
                _ = try await self.s3Client.deleteObject(input: input)
                
                self.logger.debug("Successfully deleted cache entry for key: \(fullKey)")
                self.statistics.totalEntries = max(0, self.statistics.totalEntries - 1)
                self.isConnected = true
                
            } catch let error {
                // Check if it's a no such key error
                if error.localizedDescription.contains("NoSuchKey") || error.localizedDescription.contains("NotFound") {
                    // Object doesn't exist, consider it successful
                    return
                }
                throw try self.mapS3Error(error, operation: "deleteObject", key: fullKey)
            }
        }
    }
    
    func listObjects(prefix: String) async throws -> [String] {
        let fullPrefix = buildFullKey(prefix)
        logger.debug("Listing objects in S3 with prefix: \(fullPrefix)")
        
        return try await retryPolicy.execute { [weak self] in
            guard let self = self else { throw CacheError.cacheCorrupted }
            
            do {
                let input = ListObjectsV2Input(
                    bucket: self.config.s3BucketName,
                    maxKeys: 1000, // Limit to prevent huge responses
                    prefix: fullPrefix
                )
                
                let output = try await self.s3Client.listObjectsV2(input: input)
                
                let keys = output.contents?.compactMap { object in
                    // Remove the prefix from the returned keys
                    object.key?.replacingOccurrences(of: "\(self.config.cachePrefix)/", with: "")
                } ?? []
                
                self.logger.debug("Found \(keys.count) objects with prefix: \(fullPrefix)")
                self.isConnected = true
                return keys.sorted()
                
            } catch let error {
                throw try self.mapS3Error(error, operation: "listObjects", key: fullPrefix)
            }
        }
    }
    
    // MARK: - Force Refresh Operations
    
    func forceRefreshCache(key: String, entry: RemoteCacheEntry) async throws {
        logger.info("Force refresh: bypassing cache for key: \(key)")
        
        // Delete existing cache entry first
        try await deleteObject(key: key)
        
        // Store fresh data
        try await putObject(key: key, entry: entry)
        
        logger.debug("Force refresh completed for key: \(key)")
    }
    
    func clearAllCache(prefix: String = "") async throws {
        logger.info("Clearing all cache with prefix: \(prefix)")
        
        let keysToDelete = try await listObjects(prefix: prefix)
        
        for key in keysToDelete {
            try await deleteObject(key: key)
        }
        
        // Reset statistics
        statistics = CacheStatistics()
        
        logger.info("Cleared \(keysToDelete.count) cache entries")
    }
    
    // MARK: - Connection Testing
    
    func testConnection() async throws {
        logger.info("Testing S3 connection to bucket: \(self.config.s3BucketName)")
        
        do {
            // Test basic connectivity with a head bucket operation
            let input = HeadBucketInput(bucket: config.s3BucketName)
            _ = try await s3Client.headBucket(input: input)
            
            isConnected = true
            lastError = nil
            logger.info("S3 connection test successful")
            
        } catch let error {
            isConnected = false
            let mappedError = try mapS3Error(error, operation: "testConnection", key: config.s3BucketName)
            lastError = mappedError
            throw mappedError
        } catch {
            isConnected = false
            let networkError = CacheError.networkError(error)
            lastError = networkError
            throw networkError
        }
    }
    
    // MARK: - Statistics and Status
    
    func clearStatistics() {
        statistics = CacheStatistics()
        logger.info("Cache statistics cleared")
    }
    
    func getStatus() -> (connected: Bool, statistics: CacheStatistics, lastError: CacheError?) {
        return (isConnected, statistics, lastError)
    }
    
    // MARK: - Private Helpers
    
    private func buildFullKey(_ key: String) -> String {
        return "\(config.cachePrefix)/\(key)"
    }
    
    private func serializeCacheEntry(_ entry: RemoteCacheEntry) throws -> Data {
        do {
            let jsonData = try JSONEncoder().encode(entry)
            
            // Compress the data
            let compressedData = try jsonData.compressed(using: COMPRESSION_LZFSE)
            
            logger.debug("Serialized and compressed cache entry: \(jsonData.count) -> \(compressedData.count) bytes")
            return compressedData
            
        } catch {
            logger.error("Failed to serialize cache entry: \(error.localizedDescription)")
            throw CacheError.serializationError(error)
        }
    }
    
    private func deserializeCacheEntry(from data: Data) throws -> RemoteCacheEntry {
        do {
            // Decompress the data
            let decompressedData = try data.decompressed(using: COMPRESSION_LZFSE)
            
            // Deserialize JSON
            let entry = try JSONDecoder().decode(RemoteCacheEntry.self, from: decompressedData)
            
            logger.debug("Deserialized and decompressed cache entry: \(data.count) -> \(decompressedData.count) bytes")
            return entry
            
        } catch {
            logger.error("Failed to deserialize cache entry: \(error.localizedDescription)")
            throw CacheError.serializationError(error)
        }
    }
    
    private func handleS3Error(_ error: Error, operation: String, key: String) throws -> CacheOperationResult {
        if error.localizedDescription.contains("NoSuchKey") || error.localizedDescription.contains("NotFound") {
            logger.debug("Object not found in S3: \(key)")
            statistics.recordMiss()
            return .notFound
        }
        
        let mappedError = try mapS3Error(error, operation: operation, key: key)
        throw mappedError
    }
    
    private func mapS3Error(_ error: Error, operation: String, key: String) throws -> CacheError {
        isConnected = false
        
        let mappedError: CacheError
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("nosuchbucket") || errorDescription.contains("bucket") && errorDescription.contains("not") {
            mappedError = .bucketNotFound
        } else if errorDescription.contains("accessdenied") || errorDescription.contains("forbidden") {
            mappedError = .accessDenied
        } else if errorDescription.contains("nosuchkey") || errorDescription.contains("notfound") {
            // This should be handled by the caller
            mappedError = .cacheCorrupted
        } else {
            mappedError = .networkError(error)
        }
        
        logger.error("S3 error in \(operation) for key \(key): \(error.localizedDescription)")
        statistics.recordError()
        lastError = mappedError
        
        return mappedError
    }
}

// MARK: - Retry Policy

private class RetryPolicy {
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let backoffMultiplier: Double
    private let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "RetryPolicy")
    
    init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
    
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry certain types of errors
                if let cacheError = error as? CacheError {
                    switch cacheError {
                    case .bucketNotFound, .accessDenied, .invalidConfiguration, .invalidCacheKey:
                        throw error // Don't retry these
                    default:
                        break // Retry other errors
                    }
                }
                
                // Don't retry on the last attempt
                guard attempt < self.maxRetries else { break }
                
                // Calculate exponential backoff delay
                let delay = min(baseDelay * pow(backoffMultiplier, Double(attempt)), maxDelay)
                logger.info("Retrying operation after \(delay)s (attempt \(attempt + 1)/\(self.maxRetries + 1))")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        if let lastError = lastError {
            throw lastError
        } else {
            throw CacheError.cacheCorrupted
        }
    }
}

// MARK: - Data Compression Extensions

private extension Data {
    func compressed(using algorithm: compression_algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, count,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, algorithm
            )
            
            guard compressedSize > 0 else {
                throw CacheError.compressionError(NSError(domain: "CompressionError", code: -1))
            }
            
            return Data(bytes: buffer, count: compressedSize)
        }
    }
    
    func decompressed(using algorithm: compression_algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            // Estimate decompressed size (up to 4x compressed size)
            let maxDecompressedSize = count * 4
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxDecompressedSize)
            defer { buffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                buffer, maxDecompressedSize,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, algorithm
            )
            
            guard decompressedSize > 0 else {
                throw CacheError.compressionError(NSError(domain: "DecompressionError", code: -1))
            }
            
            return Data(bytes: buffer, count: decompressedSize)
        }
    }
}