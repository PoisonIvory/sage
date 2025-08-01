//
//  OnboardingErrorTests.swift
//  SageTests
//
//  Tests for OnboardingError domain errors
//

import XCTest
@testable import Sage

final class OnboardingErrorTests: XCTestCase {
    
    // MARK: - Error Creation Tests
    
    func testOnboardingErrorCreation() {
        // Given: Onboarding error cases
        let invalidUserInfo = OnboardingError.invalidUserInfo
        let recordingFailed = OnboardingError.onboardingRecordingFailed
        
        // When: Accessing error properties
        let userInfoCode = invalidUserInfo.errorCode
        let userInfoMessage = invalidUserInfo.userMessage
        let userInfoRetry = invalidUserInfo.shouldRetry
        
        // Then: Properties should be correctly set
        XCTAssertEqual(userInfoCode, "ONBOARD_001")
        XCTAssertEqual(userInfoMessage, "Please provide valid information")
        XCTAssertFalse(userInfoRetry)
        
        XCTAssertEqual(recordingFailed.errorCode, "ONBOARD_002")
        XCTAssertTrue(recordingFailed.shouldRetry)
    }
    
    func testOnboardingErrorRetryBehaviors() {
        // Given: Different onboarding error types
        let recordingError = OnboardingError.onboardingRecordingFailed
        let uploadError = OnboardingError.onboardingUploadFailed
        let analysisError = OnboardingError.onboardingAnalysisFailed
        let userInfoError = OnboardingError.invalidUserInfo
        
        // When: Checking retry behaviors
        let recordingRetry = recordingError.retryBehavior
        let uploadRetry = uploadError.retryBehavior
        let analysisRetry = analysisError.retryBehavior
        let userInfoRetry = userInfoError.retryBehavior
        
        // Then: Should have appropriate retry strategies
        XCTAssertEqual(recordingRetry, .immediately)
        XCTAssertEqual(uploadRetry, .after(delay: 2.0))
        XCTAssertEqual(analysisRetry, .after(delay: 3.0))
        XCTAssertEqual(userInfoRetry, .afterUserAction(actionHint: "Correct user information"))
    }
    

    
    // MARK: - Result Type Tests
    
    func testResultRetryBehavior() {
        // Given: A result with error
        let result: Result<String, OnboardingError> = .failure(.onboardingUploadFailed)
        
        // When: Accessing retry behavior
        let retryBehavior = result.retryBehavior
        
        // Then: Should have retry behavior
        XCTAssertNotNil(retryBehavior)
        XCTAssertEqual(retryBehavior, .after(delay: 2.0))
    }
    
    func testResultIsSuccess() {
        // Given: Success and failure results
        let successResult: Result<String, OnboardingError> = .success("test")
        let failureResult: Result<String, OnboardingError> = .failure(.unknown)
        
        // When: Checking success status
        let successIsSuccess = successResult.isSuccess
        let failureIsSuccess = failureResult.isSuccess
        
        // Then: Should correctly identify success/failure
        XCTAssertTrue(successIsSuccess)
        XCTAssertFalse(failureIsSuccess)
    }
} 