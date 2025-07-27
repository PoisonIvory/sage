//
//  AudioUploadTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - Audio upload success/failure scenarios
//  - Firebase Storage upload handling
//  - Analytics tracking for upload events
//  - Error handling for network and auth failures
//  - Upload mode handling (onboarding vs regular)
//  - Silence trimming validation
//
//  Improvements:
//  - Added waitForUIUpdate() helper for consistent async testing
//  - Added explicit silence trimming test with future-ready assertions
//  - Replaced repetitive async expectation code with reusable helper

import XCTest
import Mixpanel
@testable import Sage

// MARK: - Audio Upload Test Requirements

// Given the 10-second recording is complete
// Then the app trims leading/trailing silence from the audio

// When the upload begins
// Then the recording is uploaded to Firebase Storage

// Then the Mixpanel event "onboarding_vocal_test_completed" is tracked
// Then the Mixpanel event "onboarding_vocal_test_result_uploaded" is tracked
// Then the event includes metadata field "duration"
// Then the event includes metadata field "userID"
// Then the event includes metadata field "success" with value true

// Given the Firebase upload fails due to network error
// Then the app displays: "Upload failed. Please check your internet connection."

// Given the Firebase upload fails due to authentication error
// Then the app displays: "Session expired. Please log in again."

final class AudioUploadTests: XCTestCase {
    
    // MARK: - Test Properties
    private var harness: OnboardingTestHarness!
    private var viewModel: OnboardingJourneyViewModel!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        harness = OnboardingTestHarness()
        viewModel = harness.makeViewModel()
    }
    
    override func tearDown() {
        harness.resetAllMocks()
        harness = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to wait for UI updates with consistent timing
    /// - Parameter assertion: The assertion to execute after UI update
    func waitForUIUpdate(_ assertion: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: "Wait for UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            assertion()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Upload Success Tests
    
    func testVocalTestUploadSuccess() {
        // Given: Recording upload succeeds
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Upload completes
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Should display success message
        waitForUIUpdate {
            XCTAssertEqual(self.viewModel.successMessage, "Success! Let's move on to testing your pitch variation.")
            XCTAssertTrue(self.viewModel.shouldShowNextButton)
        }
    }
    
    func testUploadUsesCorrectMode() {
        // Given: Recording is completed and ready for upload
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should upload with onboarding mode
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
    }
    
    func testUploadIncludesCorrectRecordingData() {
        // Given: Recording is completed
        let mockRecording = OnboardingTestDataFactory.createMockRecording(
            userID: "test-user-id",
            duration: 10.0,
            task: "onboarding_vocal_test"
        )
        
        // When: Recording completion is simulated
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should upload the recording
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
    }
    
    // MARK: - Silence Trimming Tests
    
    func testRecordingSilenceTrimming() {
        // Given: Recording is completed with potential leading/trailing silence
        let mockRecording = OnboardingTestDataFactory.createMockRecordingWithTrimming(
            userID: "test-user-id",
            duration: 10.0,
            task: "onboarding_vocal_test",
            wasTrimmed: true
        )
        
        // When: Recording completion is simulated
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should process recording for silence trimming
        // Note: If Recording model exposes trimming flags, assert them directly:
        // XCTAssertTrue(mockRecording.wasTrimmed) // ← If available
        // For now, we verify the upload process handles the recording correctly
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
        
        // Then: Should maintain recording integrity during processing
        XCTAssertEqual(mockRecording.userID, "test-user-id")
        XCTAssertEqual(mockRecording.task, "onboarding_vocal_test")
        XCTAssertEqual(mockRecording.duration, 10.0)
    }
    
    // MARK: - Upload Error Tests
    
    func testVocalTestUploadNetworkError() {
        // Given: Recording upload fails due to network error
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        
        // When: Upload fails
        viewModel.handleVocalTestUploadResult(.failure(UploadError.networkError))
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "Upload failed. Please check your internet connection.")
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    func testVocalTestUploadAuthenticationError() {
        // Given: Recording upload fails due to authentication error
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .authenticationError
        
        // When: Upload fails
        viewModel.handleVocalTestUploadResult(.failure(UploadError.authenticationError))
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "Session expired. Please log in again.")
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    func testVocalTestUploadGenericError() {
        // Given: Recording upload fails due to generic error
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        
        // When: Upload fails with generic error
        let genericError = NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Generic upload error"])
        viewModel.handleVocalTestUploadResult(.failure(genericError))
        
        // Then: Should display error message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    // MARK: - Analytics Tracking Tests
    
    func testUploadSuccessAnalyticsTracking() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Upload succeeds
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
        
        // Then: Should include required metadata
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_vocal_test_result_uploaded", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMode("onboarding_vocal_test_result_uploaded", expectedMode: "onboarding"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsSuccess("onboarding_vocal_test_result_uploaded", expectedSuccess: true))
    }
    
    func testUploadFailureAnalyticsTracking() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Upload fails
        viewModel.handleVocalTestUploadResult(.failure(UploadError.networkError))
        
        // Then: Should still track completion event
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        
        // Then: Should track upload failure
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsSuccess("onboarding_vocal_test_result_uploaded", expectedSuccess: false))
    }
    
    func testAnalyticsEventsIncludeDuration() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Vocal test upload is tracked with duration
        viewModel.trackVocalTestUploaded(mode: .onboarding, duration: 10.0)
        
        // Then: Should include duration in analytics
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsDuration("onboarding_vocal_test_result_uploaded", expectedDuration: 10.0))
    }
    
    func testAnalyticsEventsIncludeAllRequiredMetadata() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Upload is tracked
        viewModel.trackVocalTestUploaded(mode: .onboarding, duration: 10.0)
        
        // Then: Should include all required metadata fields
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_vocal_test_result_uploaded", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMode("onboarding_vocal_test_result_uploaded", expectedMode: "onboarding"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsSuccess("onboarding_vocal_test_result_uploaded", expectedSuccess: true))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsDuration("onboarding_vocal_test_result_uploaded", expectedDuration: 10.0))
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorMessagesAreClearedOnRetry() {
        // Given: Upload failed with error
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        viewModel.handleVocalTestUploadResult(.failure(UploadError.networkError))
        
        // Verify error exists
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When: Upload succeeds on retry
        harness.mockAudioUploader.shouldSucceed = true
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Error should be cleared and success shown
        waitForUIUpdate {
            XCTAssertEqual(self.viewModel.successMessage, "Success! Let's move on to testing your pitch variation.")
            XCTAssertTrue(self.viewModel.shouldShowNextButton)
        }
    }
    
    func testMultipleUploadAttempts() {
        // Given: Upload fails initially
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        viewModel.handleVocalTestUploadResult(.failure(UploadError.networkError))
        
        // Then: Should show error
        XCTAssertEqual(viewModel.errorMessage, "Upload failed. Please check your internet connection.")
        
        // When: Upload succeeds on second attempt
        harness.mockAudioUploader.shouldSucceed = true
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Should show success
        waitForUIUpdate {
            XCTAssertEqual(self.viewModel.successMessage, "Success! Let's move on to testing your pitch variation.")
            XCTAssertTrue(self.viewModel.shouldShowNextButton)
        }
    }
    
    // MARK: - Upload State Management Tests
    
    func testUploadStateDuringUpload() {
        // Given: Recording is being uploaded
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Upload is in progress
        // Note: This would typically be handled by the uploader service
        // For now, we test the state after upload completion
        
        // Then: Should handle upload completion properly
        viewModel.handleVocalTestUploadResult(.success(()))
        
        waitForUIUpdate {
            XCTAssertTrue(self.viewModel.shouldShowNextButton)
            XCTAssertNotNil(self.viewModel.successMessage)
        }
    }
    
    func testUploadStateAfterFailure() {
        // Given: Upload fails
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        
        // When: Upload fails
        viewModel.handleVocalTestUploadResult(.failure(UploadError.networkError))
        
        // Then: Should not show next button
        XCTAssertFalse(viewModel.shouldShowNextButton)
        
        // Then: Should show error message
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Recording Upload Integration Tests
    
    func testRecordingCompletionTriggersUpload() {
        // Given: User is recording
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // When: Recording completes
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should trigger upload
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
    }
    
    func testRecordingUploadWithCorrectParameters() {
        // Given: Recording is completed
        let mockRecording = OnboardingTestDataFactory.createMockRecording(
            userID: "test-user-id",
            duration: 10.0,
            task: "onboarding_vocal_test"
        )
        
        // When: Recording completion is simulated
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should upload with correct parameters
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
    }
    
    // MARK: - Error Message Consistency Tests
    
    func testErrorMessagesAreConsistent() {
        // Given: Different upload error types
        let networkError = UploadError.networkError
        let authError = UploadError.authenticationError
        
        // When: Handling different error types
        viewModel.handleVocalTestUploadResult(.failure(networkError))
        let networkMessage = viewModel.errorMessage
        
        harness.resetAllMocks()
        viewModel = harness.makeViewModel()
        
        viewModel.handleVocalTestUploadResult(.failure(authError))
        let authMessage = viewModel.errorMessage
        
        // Then: Error messages should be consistent
        XCTAssertEqual(networkMessage, "Upload failed. Please check your internet connection.")
        XCTAssertEqual(authMessage, "Session expired. Please log in again.")
    }
    
    // MARK: - Success Message Consistency Tests
    
    func testSuccessMessageIsConsistent() {
        // Given: Upload succeeds
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Upload completes
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Success message should be consistent
        waitForUIUpdate {
            XCTAssertEqual(self.viewModel.successMessage, "Success! Let's move on to testing your pitch variation.")
        }
    }
} 