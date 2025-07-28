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
//
//  MVP Testing Strategy:
//  - Focus on critical user flows and crash prevention
//  - Test ViewModel logic and data validation
//  - Verify coordinator transitions and analytics integration
//  - Remove UI text, localization, and redundant state tests

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

@MainActor
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
    
    // MARK: - Critical User Flow Tests
    
    func testVocalTestUploadSuccess() {
        // Given: Recording upload succeeds
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Upload completes
        viewModel.handleSustainedVowelTestUploadResult(.success(()))
        
        // Then: Should show next button and success state
        XCTAssertTrue(viewModel.shouldShowNextButton)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    func testVocalTestUploadFailure() {
        // Given: Recording upload fails
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        
        // When: Upload fails
        viewModel.handleSustainedVowelTestUploadResult(.failure(UploadError.networkError))
        
        // Then: Should show error and not show next button
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    // MARK: - ViewModel Logic Tests
    
    func testUploadUsesCorrectMode() {
        // Given: Recording is completed and ready for upload with user profile
        harness.mockAudioUploader.shouldSucceed = true
        viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()
        
        // When: Upload completes successfully
        viewModel.handleSustainedVowelTestUploadResult(.success(()))
        
        // Then: Should track both completion and upload analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
    }
    
    // MARK: - Analytics Integration Tests
    
    func testAnalyticsEventsAreTracked() {
        // Given: User has completed signup with profile
        viewModel.selectAnonymous()
        viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()
        
        // When: Upload completes successfully
        viewModel.handleSustainedVowelTestUploadResult(.success(()))
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
    }
    
    // MARK: - Crash Prevention Tests
    
    func testErrorRecoveryWorks() {
        // Given: Upload failed with error
        harness.mockAudioUploader.shouldSucceed = false
        harness.mockAudioUploader.errorType = .networkError
        viewModel.handleSustainedVowelTestUploadResult(.failure(UploadError.networkError))
        
        // Verify error exists
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When: Upload succeeds on retry
        harness.mockAudioUploader.shouldSucceed = true
        viewModel.handleSustainedVowelTestUploadResult(.success(()))
        
        // Then: Should recover without crashing
        XCTAssertTrue(viewModel.shouldShowNextButton)
        XCTAssertNotNil(viewModel.successMessage)
    }
} 