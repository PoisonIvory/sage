//
//  Result.swift
//  Sage
//
//  Standardized Result type following DDD principles
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Domain Result Type
enum DomainResult<T> {
    case success(T)
    case failure(DomainError)
    
    // MARK: - Initializers
    init(_ value: T) {
        self = .success(value)
    }
    
    init(_ error: DomainError) {
        self = .failure(error)
    }
    
    // MARK: - Computed Properties
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var value: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
    
    var error: DomainError? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    var userMessage: String? {
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
    
    // MARK: - Functional Methods
    func map<U>(_ transform: (T) -> U) -> DomainResult<U> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func flatMap<U>(_ transform: (T) -> DomainResult<U>) -> DomainResult<U> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func mapError(_ transform: (DomainError) -> DomainError) -> DomainResult<T> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
    
    // MARK: - Side Effect Methods
    @discardableResult
    func onSuccess(_ action: (T) -> Void) -> DomainResult<T> {
        if case .success(let value) = self {
            action(value)
        }
        return self
    }
    
    @discardableResult
    func onFailure(_ action: (DomainError) -> Void) -> DomainResult<T> {
        if case .failure(let error) = self {
            action(error)
        }
        return self
    }
    
    @discardableResult
    func onComplete(_ action: (DomainResult<T>) -> Void) -> DomainResult<T> {
        action(self)
        return self
    }
    
    // MARK: - Logging
    @discardableResult
    func logResult(context: String = "", file: String = #file, function: String = #function, line: Int = #line) -> DomainResult<T> {
        switch self {
        case .success(let value):
            Logger.debug("\(context) Success: \(String(describing: value))")
        case .failure(let error):
            error.logError(context: context, file: file, function: function, line: line)
        }
        return self
    }
}

// MARK: - Async Result Extensions
extension DomainResult {
    static func async<U>(_ operation: @escaping () async throws -> U) async -> DomainResult<U> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            // Convert system errors to domain errors
            let domainError = Self.convertSystemError(error)
            return .failure(domainError)
        }
    }
    
    private static func convertSystemError(_ error: Error) -> DomainError {
        // Convert common system errors to domain errors
        switch error {
        case let nsError as NSError:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return VoiceAnalysisError.networkUnavailable
            case NSURLErrorTimedOut:
                return VoiceAnalysisError.timeout
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return VoiceAnalysisError.networkUnavailable
            default:
                return VoiceAnalysisError.unknown
            }
        default:
            return VoiceAnalysisError.unknown
        }
    }
}

// MARK: - Convenience Initializers
extension DomainResult {
    // Convenience initializers are already available as enum cases
}

// MARK: - Equatable Conformance
extension DomainResult: Equatable where T: Equatable {
    static func == (lhs: DomainResult<T>, rhs: DomainResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.errorCode == rhsError.errorCode
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible
extension DomainResult: CustomStringConvertible {
    var description: String {
        switch self {
        case .success(let value):
            return "Success(\(value))"
        case .failure(let error):
            return "Failure(\(error.errorCode): \(error.technicalDetails))"
        }
    }
} 