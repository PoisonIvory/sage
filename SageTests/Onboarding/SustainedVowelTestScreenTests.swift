//
//  SustainedVowelTestScreenTests.swift
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
final class SustainedVowelTestScreenTests: XCTestCase {
    
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
    
    func testSustainedVowelTestRecordingFlow() {
        // Given: User is on vocal test screen
        viewModel.currentStep = .sustainedVowelTest
        
        // When: User starts recording
        viewModel.startSustainedVowelTest()
        
        // Then: Should request permission and start recording
        XCTAssertTrue(harness.mockMicrophonePermissionManager.didCheckPermission)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(viewModel.recordingState.showCountdown)
    }
    
    func testSustainedVowelTestRecordingCompletion() {
        // Given: Recording is in progress with permission granted
        viewModel.currentStep = .sustainedVowelTest
        viewModel.microphonePermissionStatus = .granted
        viewModel.startSustainedVowelTest()
        
        // When: Recording completes (via completion handler)
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should stop recording and process
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
    
    func testNavigationFromSustainedVowelTestToReadingPrompt() {
        // Given: Recording is complete
        viewModel.currentStep = .sustainedVowelTest
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
        viewModel.microphonePermissionStatus = .granted
        
        // When: User starts recording
        viewModel.startSustainedVowelTest()
        
        // Then: Should start recording successfully
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
    
    func testMicrophonePermissionDeniedFlow() {
        // Given: Microphone permission is denied
        viewModel.microphonePermissionStatus = .denied
        
        // When: User starts recording
        viewModel.startSustainedVowelTest()
        
        // Then: Should handle permission denial gracefully
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Analytics Integration Tests
    
    func testSustainedVowelTestAnalyticsTracking() {
        // Given: User is on vocal test screen with profile
        viewModel.currentStep = .sustainedVowelTest
        viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()
        
        // When: Recording completes and uploads successfully
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        viewModel.handleSustainedVowelTestUploadResult(.success(()))
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_completed"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_vocal_test_result_uploaded"))
    }
    
    // MARK: - Crash Prevention Tests
    
    func testRecordingStateTransitions() {
        // Given: User is on vocal test screen with permission granted
        viewModel.currentStep = .sustainedVowelTest
        viewModel.microphonePermissionStatus = .granted
        
        // When: User starts recording and it completes
        viewModel.startSustainedVowelTest()
        let mockRecording = OnboardingTestDataFactory.createMockRecording()
        harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)
        
        // Then: Should handle state transitions without crashing
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(harness.mockAudioRecorder.didStartRecording)
    }
} 