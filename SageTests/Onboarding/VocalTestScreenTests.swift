//
//  VocalTestScreenTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - Microphone permission handling
//  - Recording start/stop functionality
//  - Recording state management
//  - Navigation from vocal test to reading prompt
//  - Analytics tracking for recording events
//
//  MVP Testing Strategy:
//  - Focus on critical user flows and crash prevention
//  - Test ViewModel logic and data validation
//  - Verify coordinator transitions and analytics integration
//  - Remove UI text, localization, and redundant state tests

import XCTest
import Mixpanel
@testable import Sage

// MARK: - Vocal Test Screen Test Requirements

// Given the user is on the vocal test screen
// When they tap "Start Recording"
// Then the app requests microphone permission
// Then the recording begins
// Then the UI shows recording state

// Given the user grants microphone permission
// When they tap "Start Recording"
// Then the recording starts successfully
// Then the Mixpanel event "onboarding_vocal_test_started" is tracked

// Given the recording is in progress
// When the user taps "Stop Recording"
// Then the recording stops
// Then the recording is processed
// Then the Mixpanel event "onboarding_vocal_test_completed" is tracked

// Given the recording is complete
// When the user taps "Next"
// Then the user is navigated to the reading prompt screen

// Given the user denies microphone permission
// When they tap "Start Recording"
// Then the app displays: "Microphone access is required for voice analysis."

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
    
    // MARK: - Critical User Flow Tests
    
    func testVocalTestRecordingFlow() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: User starts recording
        viewModel.startVocalTest()
        
        // Then: Should request permission and start recording
        XCTAssertTrue(harness.mockMicrophonePermissionManager.didCheckPermission)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(viewModel.recordingState.showCountdown)
    }
    
    func testVocalTestRecordingCompletion() {
        // Given: Recording is in progress
        viewModel.currentStep = .vocalTest
        viewModel.startVocalTest()
        
        // When: User stops recording
        harness.mockAudioRecorder.stop()
        
        // Then: Should stop recording and process
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStopRecording)
    }
    
    func testNavigationFromVocalTestToReadingPrompt() {
        // Given: Recording is complete
        viewModel.currentStep = .vocalTest
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // When: User taps next
        viewModel.selectNext()
        
        // Then: Should navigate to reading prompt
        XCTAssertEqual(viewModel.currentStep, .readingPrompt)
    }
    
    // MARK: - ViewModel Logic Tests
    
    func testMicrophonePermissionGrantedFlow() {
        // Given: Microphone permission is granted
        harness.mockMicrophonePermissionManager.permissionGranted = true
        
        // When: User starts recording
        viewModel.startVocalTest()
        
        // Then: Should start recording successfully
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
    
    func testMicrophonePermissionDeniedFlow() {
        // Given: Microphone permission is denied
        harness.mockMicrophonePermissionManager.permissionGranted = false
        
        // When: User starts recording
        viewModel.startVocalTest()
        
        // Then: Should handle permission denial gracefully
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Analytics Integration Tests
    
    func testVocalTestAnalyticsTracking() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: User starts recording
        viewModel.startVocalTest()
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_started"))
    }
    
    // MARK: - Crash Prevention Tests
    
    func testRecordingStateTransitions() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .vocalTest
        
        // When: User starts and stops recording multiple times
        viewModel.startVocalTest()
        harness.mockAudioRecorder.stop()
        viewModel.startVocalTest()
        harness.mockAudioRecorder.stop()
        
        // Then: Should handle state transitions without crashing
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStopRecording)
    }
} 