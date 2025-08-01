//
//  AuthenticationErrorTests.swift
//  SageTests
//
//  Tests for AuthenticationError domain errors
//

import XCTest
@testable import Sage

final class AuthenticationErrorTests: XCTestCase {
    
    // MARK: - Error Creation Tests
    
    func testAuthenticationErrorCreation() {
        // Given: Authentication error cases
        let invalidCredentials = AuthenticationError.invalidCredentials
        let networkError = AuthenticationError.networkError
        
        // When: Accessing error properties
        let credentialsCode = invalidCredentials.errorCode
        let credentialsMessage = invalidCredentials.userMessage
        let credentialsRetry = invalidCredentials.shouldRetry
        
        // Then: Properties should be correctly set
        XCTAssertEqual(credentialsCode, "AUTH_001")
        XCTAssertEqual(credentialsMessage, "Invalid email or password")
        XCTAssertFalse(credentialsRetry)
        
        XCTAssertEqual(networkError.errorCode, "AUTH_005")
        XCTAssertTrue(networkError.shouldRetry)
    }
    
    func testAuthenticationErrorUserActions() {
        // Given: Authentication errors requiring user action
        let userNotFound = AuthenticationError.userNotFound
        let emailInUse = AuthenticationError.emailAlreadyInUse
        let weakPassword = AuthenticationError.weakPassword
        
        // When: Checking retry behavior
        let userNotFoundRetry = userNotFound.retryBehavior
        let emailInUseRetry = emailInUse.retryBehavior
        let weakPasswordRetry = weakPassword.retryBehavior
        
        // Then: All should require user action
        XCTAssertEqual(userNotFoundRetry, .afterUserAction(actionHint: "Create account or check email"))
        XCTAssertEqual(emailInUseRetry, .afterUserAction(actionHint: "Use different email or sign in"))
        XCTAssertEqual(weakPasswordRetry, .afterUserAction(actionHint: "Use stronger password"))
    }
    
    // MARK: - Retry Behavior Tests
    

    
    // MARK: - Result Type Tests
    
    func testResultRetryBehavior() {
        // Given: A result with error
        let result: Result<String, AuthenticationError> = .failure(.networkError)
        
        // When: Accessing retry behavior
        let retryBehavior = result.retryBehavior
        
        // Then: Should have retry behavior
        XCTAssertNotNil(retryBehavior)
        XCTAssertEqual(retryBehavior, .after(delay: 3.0))
    }
    
    func testResultIsSuccess() {
        // Given: Success and failure results
        let successResult: Result<String, AuthenticationError> = .success("test")
        let failureResult: Result<String, AuthenticationError> = .failure(.unknown)
        
        // When: Checking success status
        let successIsSuccess = successResult.isSuccess
        let failureIsSuccess = failureResult.isSuccess
        
        // Then: Should correctly identify success/failure
        XCTAssertTrue(successIsSuccess)
        XCTAssertFalse(failureIsSuccess)
    }
} 