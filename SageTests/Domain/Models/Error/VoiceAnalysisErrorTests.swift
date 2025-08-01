//
//  VoiceAnalysisErrorTests.swift
//  SageTests
//
//  Tests for VoiceAnalysisError domain errors
//

import XCTest
@testable import Sage

final class VoiceAnalysisErrorTests: XCTestCase {
    
    // MARK: - Error Creation Tests
    
    func testVoiceAnalysisErrorCreation() {
        // Given: Voice analysis error cases
        let recordingError = VoiceAnalysisError.mockRecordingFailed
        let uploadError = VoiceAnalysisError.uploadFailed(reason: "Upload failed")
        let networkError = VoiceAnalysisError.mockNetworkError
        
        // When: Accessing error properties
        let recordingCode = recordingError.errorCode
        let recordingMessage = recordingError.userMessage
        let recordingDetails = recordingError.technicalDetails
        let recordingRetry = recordingError.shouldRetry
        
        // Then: Properties should be correctly set
        XCTAssertEqual(recordingCode, "VOICE_001")
        XCTAssertEqual(recordingMessage, "Unable to record your voice. Please try again.")
        XCTAssertTrue(recordingDetails.contains("Invalid prompt ID"))
        XCTAssertTrue(recordingRetry)
        
        XCTAssertEqual(uploadError.errorCode, "VOICE_002")
        XCTAssertEqual(networkError.errorCode, "VOICE_005")
        XCTAssertFalse(networkError.shouldRetry)
    }
    
    func testVoiceAnalysisErrorWithAssociatedValues() {
        // Given: Voice analysis errors with associated values
        let recordingError = VoiceAnalysisError.mockRecordingFailed
        let validationError = VoiceAnalysisError.mockValidationFailed
        
        // When: Accessing technical details
        let recordingDetails = recordingError.technicalDetails
        let validationDetails = validationError.technicalDetails
        
        // Then: Associated values should be included
        XCTAssertTrue(recordingDetails.contains("Invalid prompt ID"))
        XCTAssertTrue(validationDetails.contains("Recording too short"))
        XCTAssertTrue(validationDetails.contains("Background noise detected"))
    }
    

    
    // MARK: - Result Type Tests
    
    func testResultRetryBehavior() {
        // Given: A result with error
        let result: Result<String, VoiceAnalysisError> = .failure(.timeout)
        
        // When: Accessing retry behavior
        let retryBehavior = result.retryBehavior
        
        // Then: Should have retry behavior
        XCTAssertNotNil(retryBehavior)
        XCTAssertEqual(retryBehavior, .after(delay: 2.0))
    }
    

} 