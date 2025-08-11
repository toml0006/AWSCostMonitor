//
//  Errors.swift
//  AWSCostMonitor
//
//  Error definitions
//

import Foundation

// Custom errors for AWS cost fetching
enum AWSCostFetchError: Error {
    case credentialsNotFound(String)
}

