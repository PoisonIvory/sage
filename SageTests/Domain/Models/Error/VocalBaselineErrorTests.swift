//
//  VocalBaselineErrorTests.swift
//  SageTests
//
//  Tests for VocalBaselineError domain errors
//

import XCTest
@testable import Sage

final class VocalBaselineErrorTests: XCTestCase {
    
    // MARK: - Error Creation Tests
    
    func testVocalBaselineErrorCreation() {
        // Given: Vocal baseline error cases
        let incompleteAnalysis = VocalBaselineError.incompleteAnalysis
        let clinicalValidationFailed = VocalBaselineError.clinicalValidationFailed(reason: "Test reason")
        
        // When: Accessing error properties
        let incompleteCode = incompleteAnalysis.errorCode
        let incompleteMessage = incompleteAnalysis.userMessage
        let incompleteRetry = incompleteAnalysis.shouldRetry
        
        // Then: Properties should be correctly set
        XCTAssertEqual(incompleteCode, "BASELINE_001")
        XCTAssertTrue(incompleteMessage.contains("Voice analysis is still in progress"))
        XCTAssertTrue(incompleteRetry)
        
        XCTAssertEqual(clinicalValidationFailed.errorCode, "BASELINE_002")
        XCTAssertTrue(clinicalValidationFailed.userMessage.contains("Test reason"))
        XCTAssertFalse(clinicalValidationFailed.shouldRetry)
    }
    
    func testVocalBaselineErrorWithAssociatedValues() {
        // Given: Vocal baseline errors with associated values
        let clinicalError = VocalBaselineError.clinicalValidationFailed(reason: "F0 confidence too low")
        let repositoryError = VocalBaselineError.repositoryError(NSError(domain: "Test", code: 1))
        
        // When: Accessing technical details
        let clinicalDetails = clinicalError.technicalDetails
        let repositoryDetails = repositoryError.technicalDetails
        
        // Then: Associated values should be included
        XCTAssertTrue(clinicalDetails.contains("F0 confidence too low"))
        XCTAssertTrue(repositoryDetails.contains("Test"))
    }
    
    // MARK: - Retry Behavior Tests
    

    
    // MARK: - Result Type Tests
    
    func testResultRetryBehavior() {
        // Given: A result with error
        let result: Result<String, VocalBaselineError> = .failure(.incompleteAnalysis)
        
        // When: Accessing retry behavior
        let retryBehavior = result.retryBehavior
        
        // Then: Should have retry behavior
        XCTAssertNotNil(retryBehavior)
        XCTAssertEqual(retryBehavior, .after(delay: 10.0))
    }
    
    func testResultIsSuccess() {
        // Given: Success and failure results
        let successResult: Result<String, VocalBaselineError> = .success("test")
        let failureResult: Result<String, VocalBaselineError> = .failure(.unknown)
        
        // When: Checking success status
        let successIsSuccess = successResult.isSuccess
        let failureIsSuccess = failureResult.isSuccess
        
        // Then: Should correctly identify success/failure
        XCTAssertTrue(successIsSuccess)
        XCTAssertFalse(failureIsSuccess)
    }
} 