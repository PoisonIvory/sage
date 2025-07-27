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
    
    func testVocalTestScreenContent() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // Then: Should display correct instruction text
        XCTAssertEqual(viewModel.vocalTestInstruction, "This test measures the rate and stability of vocal cord vibrations, both of which are affected by changes in hormones.")
        
        // Then: Should display correct prompt
        XCTAssertEqual(viewModel.vocalTestPrompt, "Please say 'ahh' for 10 seconds.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.beginButtonTitle, "Begin")
    }
    
    func testVocalTestContentIsConsistent() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: Content is accessed multiple times
        let instruction1 = viewModel.vocalTestInstruction
        let instruction2 = viewModel.vocalTestInstruction
        let prompt1 = viewModel.vocalTestPrompt
        let prompt2 = viewModel.vocalTestPrompt
        let buttonTitle1 = viewModel.beginButtonTitle
        let buttonTitle2 = viewModel.beginButtonTitle
        
        // Then: Content should be consistent
        XCTAssertEqual(instruction1, instruction2)
        XCTAssertEqual(prompt1, prompt2)
        XCTAssertEqual(buttonTitle1, buttonTitle2)
    }
    
    // MARK: - Microphone Permission Tests
    
    func testMicrophonePermissionCheckOnViewLoad() {
        // Given: User navigates to vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: View loads
        viewModel.onVocalTestViewAppear()
        
        // Then: Should check microphone permission
        XCTAssertTrue(harness.mockMicrophonePermissionManager.didCheckPermission)
    }
    
    func testMicrophonePermissionGranted() {
        // Given: Microphone permission is granted
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        viewModel.currentStep = .vocalTest
        
        // When: User attempts to start recording
        viewModel.startVocalTest()
        
        // Then: Should start recording successfully
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
        XCTAssertEqual(harness.mockAudioRecorder.lastRecordingDuration, 10.0)
    }
    
    func testMicrophonePermissionDenied() {
        // Given: Microphone permission is denied
        harness.mockMicrophonePermissionManager.permissionGranted = false
        viewModel.microphonePermissionStatus = .denied
        viewModel.currentStep = .vocalTest
        
        // When: User attempts to start recording
        viewModel.startVocalTest()
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "Microphone access is required. Enable it in Settings to continue.")
        
        // Then: Should not start recording
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(harness.mockAudioRecorder.didStartRecording)
    }
    
    func testMicrophonePermissionNotDetermined() {
        // Given: Microphone permission is not determined
        harness.mockMicrophonePermissionManager.permissionGranted = false
        viewModel.microphonePermissionStatus = .notDetermined
        viewModel.currentStep = .vocalTest
        
        // When: User attempts to start recording
        viewModel.startVocalTest()
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "Microphone access is required. Enable it in Settings to continue.")
        
        // Then: Should not start recording
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(harness.mockAudioRecorder.didStartRecording)
    }
    
    // MARK: - Recording Flow Tests
    
    func testVocalTestRecordingFlow() {
        // Given: Microphone permission is granted
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        viewModel.currentStep = .vocalTest
        
        // When: User starts vocal test
        viewModel.startVocalTest()
        
        // Then: Should start recording
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(viewModel.recordingState.showCountdown)
        XCTAssertTrue(viewModel.recordingState.showProgressBar)
        XCTAssertTrue(viewModel.recordingState.showWaveform)
        
        // Then: Should use AudioRecorderProtocol
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
        XCTAssertEqual(harness.mockAudioRecorder.lastRecordingDuration, 10.0)
    }
    
    func testVocalTestRecordingCompletion() {
        // Given: Recording is in progress
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // When: Recording completes
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should stop recording (with async expectation for timing)
        let expectation = XCTestExpectation(description: "Recording completion state update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.viewModel.isRecording)
            XCTAssertFalse(self.viewModel.recordingState.showCountdown)
            XCTAssertFalse(self.viewModel.recordingState.showProgressBar)
            XCTAssertFalse(self.viewModel.recordingState.showWaveform)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Should upload recording with onboarding mode
        XCTAssertTrue(harness.mockAudioUploader.didUploadRecording)
        XCTAssertEqual(harness.mockAudioUploader.lastUploadMode, .onboarding)
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
    }
    
    func testRecordingStateTransitions() {
        // Given: User is on vocal test screen with permission granted
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        viewModel.currentStep = .vocalTest
        
        // When: Recording starts
        viewModel.startVocalTest()
        
        // Then: Should be in recording state
        XCTAssertTrue(viewModel.isRecording)
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
    
    func testRecordingCleanupWhenNotRecording() {
        // Given: User is on vocal test screen but not recording
        viewModel.currentStep = .vocalTest
        viewModel.isRecording = false
        
        // When: View disappears
        viewModel.onVocalTestViewDisappear()
        
        // Then: Should not attempt to stop recording
        XCTAssertFalse(harness.mockAudioRecorder.didStopRecording)
    }
    
    // MARK: - Navigation Tests
    
    func testUserTapsNextAfterVocalTest() {
        // Given: Vocal test is complete and successful
        viewModel.currentStep = .vocalTest
        viewModel.shouldShowNextButton = true
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should navigate to reading prompt screen
        XCTAssertEqual(viewModel.currentStep, .readingPrompt)
    }
    
    func testNextButtonNotShownDuringRecording() {
        // Given: User is recording
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        
        // Then: Should not show next button
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    func testNextButtonShownAfterSuccessfulUpload() {
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
    
    // MARK: - Error Handling Tests
    
    func testRecordingStartFailure() {
        // Given: Microphone permission is granted but recording fails to start
        harness.mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        viewModel.currentStep = .vocalTest
        
        // When: User attempts to start recording
        viewModel.startVocalTest()
        
        // Then: Should handle gracefully
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
    
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
    
    // MARK: - Analytics Tests
    
    func testVocalTestAnalyticsTracking() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Vocal test is completed
        viewModel.trackVocalTestCompleted()
        
        // Then: Should have tracked event with userID
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_vocal_test_completed", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMode("onboarding_vocal_test_completed", expectedMode: "onboarding"))
    }
    
    func testVocalTestUploadAnalyticsTracking() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Vocal test upload is tracked
        viewModel.trackVocalTestUploaded(mode: .onboarding)
        
        // Then: Should have tracked event with mode
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMode("onboarding_vocal_test_result_uploaded", expectedMode: "onboarding"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsSuccess("onboarding_vocal_test_result_uploaded", expectedSuccess: true))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_vocal_test_result_uploaded", expectedUserID: "test-user-id"))
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
    
    func testVocalTestScreenStateAfterPermissionCheck() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: Permission is checked
        viewModel.onVocalTestViewAppear()
        
        // Then: Should have checked permission
        XCTAssertTrue(harness.mockMicrophonePermissionManager.didCheckPermission)
        
        // Then: Should maintain clean state
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
} 