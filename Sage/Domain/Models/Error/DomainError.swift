//
//  DomainError.swift
//  Sage
//
//  Base domain error protocol and utilities
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Retry Behavior
enum RetryBehavior {
    case never
    case immediately
    case after(delay: TimeInterval)
    case afterUserAction(actionHint: String)
    
    var shouldRetry: Bool {
        switch self {
        case .never:
            return false
        case .immediately, .after, .afterUserAction:
            return true
        }
    }
    
    var retryDelay: TimeInterval {
        switch self {
        case .never, .immediately, .afterUserAction:
            return 0
        case .after(let delay):
            return delay
        }
    }
    
    var actionHint: String? {
        switch self {
        case .afterUserAction(let hint):
            return hint
        case .never, .immediately, .after:
            return nil
        }
    }
}

// MARK: - Domain Error Protocol
protocol DomainError: Error, LocalizedError {
    var errorCode: String { get }
    var userMessage: String { get }
    var technicalDetails: String { get }
    var retryBehavior: RetryBehavior { get }
    
    // Backward compatibility
    var shouldRetry: Bool { get }
}

// MARK: - Error Utilities
extension DomainError {
    func logError(context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        let retryInfo = formatRetryInfo()
        Logger.error("\(contextPrefix)[\(errorCode)] \(userMessage) | \(technicalDetails) | \(retryInfo)", category: .general)
    }
    
    private func formatRetryInfo() -> String {
        switch retryBehavior {
        case .never:
            return "retry: never"
        case .immediately:
            return "retry: immediately"
        case .after(let delay):
            return "retry: after \(Int(delay))s"
        case .afterUserAction(let actionHint):
            return "retry: after user action (\(actionHint))"
        }
    }
}

// MARK: - Backward Compatibility
extension DomainError {
    var shouldRetry: Bool {
        return retryBehavior.shouldRetry
    }
}

// MARK: - Result Type Extensions
extension Result where Failure: DomainError {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let error): return error.userMessage
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .success: return false
        case .failure(let error): return error.shouldRetry
        }
    }
    
    var retryBehavior: RetryBehavior? {
        switch self {
        case .success: return nil
        case .failure(let error): return error.retryBehavior
        }
    }
} 