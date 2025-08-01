//
//  DomainErrorProtocolTests.swift
//  SageTests
//
//  Tests for DomainError protocol and shared functionality
//

import XCTest
@testable import Sage

final class DomainErrorProtocolTests: XCTestCase {
    
    // MARK: - Protocol Conformance Tests
    
    func testDomainErrorProtocolConformance() {
        // Given: Different domain error types
        let voiceError = VoiceAnalysisError.unknown
        let authError = AuthenticationError.unknown
        let onboardingError = OnboardingError.unknown
        let baselineError = VocalBaselineError.unknown
        
        // When: Checking protocol conformance
        let voiceIsDomainError = voiceError is DomainError
        let authIsDomainError = authError is DomainError
        let onboardingIsDomainError = onboardingError is DomainError
        let baselineIsDomainError = baselineError is DomainError
        
        // Then: All should conform to DomainError protocol
        XCTAssertTrue(voiceIsDomainError)
        XCTAssertTrue(authIsDomainError)
        XCTAssertTrue(onboardingIsDomainError)
        XCTAssertTrue(baselineIsDomainError)
    }
    
    func testDomainErrorBackwardCompatibility() {
        // Given: Domain errors
        let voiceError = VoiceAnalysisError.recordingFailed(reason: "Test")
        let authError = AuthenticationError.invalidCredentials
        
        // When: Using backward compatibility property
        let voiceShouldRetry = voiceError.shouldRetry
        let authShouldRetry = authError.shouldRetry
        
        // Then: shouldRetry should work correctly
        XCTAssertTrue(voiceShouldRetry)
        XCTAssertFalse(authShouldRetry)
    }
    
    // MARK: - RetryBehavior Tests
    

    
    // MARK: - Result Type Extension Tests
    
    func testResultRetryBehavior() {
        // Given: A result with error
        let result: Result<String, VoiceAnalysisError> = .failure(.timeout)
        
        // When: Accessing retry behavior
        let retryBehavior = result.retryBehavior
        
        // Then: Should have retry behavior
        XCTAssertNotNil(retryBehavior)
        XCTAssertEqual(retryBehavior, .after(delay: 2.0))
    }
    
    func testResultSuccessAndRetryBehavior() {
        // Given: Success and failure results with different error types
        let successResult: Result<String, VoiceAnalysisError> = .success("test")
        let failureResult: Result<String, VoiceAnalysisError> = .failure(.unknown)
        let retryResult: Result<String, VoiceAnalysisError> = .failure(.recordingFailed(reason: "Test"))
        let noRetryResult: Result<String, AuthenticationError> = .failure(.invalidCredentials)
        
        // When: Checking success status and retry behavior
        let successIsSuccess = successResult.isSuccess
        let failureIsSuccess = failureResult.isSuccess
        let retryShouldRetry = retryResult.shouldRetry
        let noRetryShouldRetry = noRetryResult.shouldRetry
        
        // Then: Should correctly identify success/failure and retry behavior
        XCTAssertTrue(successIsSuccess)
        XCTAssertFalse(failureIsSuccess)
        XCTAssertTrue(retryShouldRetry)
        XCTAssertFalse(noRetryShouldRetry)
    }
} 