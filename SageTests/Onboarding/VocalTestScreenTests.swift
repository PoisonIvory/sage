//
//  VocalTestScreenTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - UI content verification for vocal test screen
//  - Microphone permission handling
//  - Recording flow and state management
//  - Navigation from vocal test to next screen
//  - Error handling for permission and recording issues
//
//  Improvements:
//  - Consolidated redundant content tests
//  - Merged navigation tests for better maintainability
//  - Combined analytics tests into focused scenarios
//  - Removed overzealous state checks
//  - Focused on essential vocal test functionality

import XCTest
@testable import Sage

// MARK: - Vocal Test Screen Test Requirements

// Given the user is navigated to View 2
// Then the UI displays the instruction text: 
// "This test measures the rate and stability of vocal cord vibrations, both of which are affected by changes in hormones."
// Then the UI displays a prompt: "Please say 'ahh' for 10 seconds."
// Then the UI displays a button labeled "Begin"

// When the view loads
// Then the app checks microphone permission

// Given microphone access has not been granted
// When permission is requested
// Then the OS microphone permission prompt is shown

// Given the user denies microphone access
// Then the app displays a message: "Microphone access is required. Enable it in Settings to continue."

// Given microphone access is granted
// When the user taps the microphone icon
// Then the app begins a 10-second audio recording
// Then the UI displays a countdown timer
// Then the UI displays a progress bar
// Then the UI optionally displays a waveform animation

@MainActor
final class VocalTestScreenTests: XCTestCase {
    
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
    
    // MARK: - UI Content Tests
    
    func testVocalTestUIContentIsValid() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // Then: Should display correct instruction text
        XCTAssertEqual(viewModel.vocalTestInstruction, "This test measures the rate and stability of vocal cord vibrations, both of which are affected by changes in hormones.")
        
        // Then: Should display correct prompt
        XCTAssertEqual(viewModel.vocalTestPrompt, "Please say 'ahh' for 10 seconds.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.beginButtonTitle, "Begin")
    }
    
    // MARK: - Microphone Permission Tests
    
    func testMicrophonePermissionCheckOnViewLoad() {
        // Given: User navigates to vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: View appears
        viewModel.onVocalTestViewAppear()
        
        // Then: Should check microphone permission
        XCTAssertTrue(harness.mockMicrophonePermissionManager.didCheckPermission)
    }
    
    func testMicrophonePermissionGrantedFlow() {
        // Given: Microphone permission is granted
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.currentStep = .vocalTest
        
        // When: View appears
        viewModel.onVocalTestViewAppear()
        
        // Then: Should update permission status
        XCTAssertEqual(viewModel.microphonePermissionStatus, .granted)
        
        // When: User starts vocal test
        viewModel.startVocalTest()
        
        // Then: Should start recording
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
    
    func testMicrophonePermissionDeniedFlow() {
        // Given: Microphone permission is denied
        harness.mockMicrophonePermissionManager.permissionGranted = false
        viewModel.currentStep = .vocalTest
        
        // When: View appears
        viewModel.onVocalTestViewAppear()
        
        // Then: Should update permission status
        XCTAssertEqual(viewModel.microphonePermissionStatus, .denied)
        
        // Then: Should show error message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Microphone access is required") ?? false)
    }
    
    // MARK: - Recording Flow Tests
    
    func testVocalTestRecordingFlow() {
        // Given: User has permission and is on vocal test screen
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        viewModel.currentStep = .vocalTest
        
        // When: User starts vocal test
        viewModel.startVocalTest()
        
        // Then: Should start recording
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
        XCTAssertTrue(viewModel.recordingState.showCountdown)
        XCTAssertTrue(viewModel.recordingState.showProgressBar)
        XCTAssertTrue(viewModel.recordingState.showWaveform)
        
        // When: Recording completes
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should transition to completed state
        let expectation = XCTestExpectation(description: "Recording state transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.viewModel.isRecording)
            XCTAssertFalse(self.viewModel.recordingState.showCountdown)
            XCTAssertFalse(self.viewModel.recordingState.showProgressBar)
            XCTAssertFalse(self.viewModel.recordingState.showWaveform)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationFromVocalTestToReadingPrompt() {
        // Given: Vocal test is complete and successful
        viewModel.currentStep = .vocalTest
        viewModel.shouldShowNextButton = true
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should navigate to reading prompt screen
        XCTAssertEqual(viewModel.currentStep, .readingPrompt)
    }
    
    func testNextButtonStateManagement() {
        // Given: User is recording
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // Then: Should not show next button during recording
        XCTAssertFalse(viewModel.shouldShowNextButton)
        
        // Given: Recording upload succeeds
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Upload completes
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Should display success message and show next button
        let expectation = XCTestExpectation(description: "Upload success UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.successMessage, "Success! Let's move on to testing your pitch variation.")
            XCTAssertTrue(self.viewModel.shouldShowNextButton)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Recording Cleanup Tests
    
    func testRecordingCleanupOnViewDisappear() {
        // Given: Recording is in progress
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // When: View disappears
        viewModel.onVocalTestViewDisappear()
        
        // Then: Should stop recording
        XCTAssertTrue(harness.mockAudioRecorder.didStopRecording)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(viewModel.recordingState.showCountdown)
        XCTAssertFalse(viewModel.recordingState.showProgressBar)
        XCTAssertFalse(viewModel.recordingState.showWaveform)
    }
    
    // MARK: - Upload and Analytics Tests
    
    func testVocalTestUploadAndAnalytics() {
        // Given: User has completed signup and recording
        viewModel.selectAnonymous()
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioUploader.shouldSucceed = true
        
        // When: Recording upload completes
        viewModel.handleVocalTestUploadResult(.success(()))
        
        // Then: Should upload recording with onboarding mode
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_vocal_test_completed", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMode("onboarding_vocal_test_completed", expectedMode: "onboarding"))
    }
    
    // MARK: - Error Handling Tests
    
    func testRecordingInterruption() {
        // Given: Recording is in progress
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // When: Recording is interrupted (view disappears)
        viewModel.onVocalTestViewDisappear()
        
        // Then: Should stop recording
        XCTAssertTrue(harness.mockAudioRecorder.didStopRecording)
        XCTAssertFalse(viewModel.isRecording)
    }
    
    // MARK: - Screen State Tests
    
    func testVocalTestScreenInitialState() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // Then: Should not be recording initially
        XCTAssertFalse(viewModel.isRecording)
        
        // Then: Should not show next button initially
        XCTAssertFalse(viewModel.shouldShowNextButton)
        
        // Then: Should not have error messages initially
        XCTAssertNil(viewModel.errorMessage)
    }
} 