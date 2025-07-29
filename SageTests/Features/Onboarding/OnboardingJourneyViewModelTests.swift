//
//  OnboardingJourneyViewModelTests.swift
//  SageTests
//
//  Tests for the onboarding journey view model that manages voice setup flow
//

import XCTest
import Combine
import AVFoundation
@testable import Sage

@MainActor
final class OnboardingJourneyViewModelTests: XCTestCase {
    
    private var sut: OnboardingJourneyViewModel!
    private var mockAudioRecorder: MockOnboardingAudioRecorder!
    private var mockPermissionManager: MockMicrophonePermissionManager!
    private var mockF0Service: MockF0DataService!
    private var mockAnalyticsService: MockAnalyticsService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockAudioRecorder = MockOnboardingAudioRecorder()
        mockPermissionManager = MockMicrophonePermissionManager()
        mockF0Service = MockF0DataService()
        mockAnalyticsService = MockAnalyticsService()
        
        sut = OnboardingJourneyViewModel(
            audioRecorder: mockAudioRecorder,
            microphonePermissionManager: mockPermissionManager,
            f0DataService: mockF0Service,
            analyticsService: mockAnalyticsService
        )
        
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockAudioRecorder = nil
        mockPermissionManager = nil
        mockF0Service = nil
        mockAnalyticsService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - User Flow Tests
    
    func testUserStartsOnboardingJourney() {
        // Given: User opens the app for the first time
        // When: Onboarding journey begins
        // Then: Should start on explainer screen
        XCTAssertEqual(sut.currentScreen, .explainer)
        XCTAssertFalse(sut.isRecording)
        XCTAssertNil(sut.recordingError)
        XCTAssertEqual(sut.recordingDuration, 0)
        XCTAssertEqual(sut.permissionStatus, .notDetermined)
    }
    
    func testUserNavigatesThroughOnboarding() {
        // Given: User is on the explainer screen
        XCTAssertEqual(sut.currentScreen, .explainer)
        
        // When: User taps "Next" button
        sut.navigateToNextScreen()
        
        // Then: Should navigate to microphone permission screen
        XCTAssertEqual(sut.currentScreen, .microphonePermission)
        
        // When: User taps "Next" button again
        sut.navigateToNextScreen()
        
        // Then: Should navigate to vocal test screen
        XCTAssertEqual(sut.currentScreen, .vocalTest)
    }
    
    func testUserGrantsMicrophonePermission() async {
        // Given: User is on microphone permission screen
        mockPermissionManager.mockPermissionStatus = .authorized
        
        // When: User grants microphone permission
        await sut.requestMicrophonePermission()
        
        // Then: Should update permission status and track analytics
        XCTAssertEqual(sut.permissionStatus, .authorized)
        XCTAssertTrue(mockPermissionManager.requestPermissionCalled)
        XCTAssertTrue(mockAnalyticsService.logEventCalled)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "microphone_permission_granted")
    }
    
    func testUserStartsVoiceRecording() async {
        // Given: User has granted microphone permission
        sut.permissionStatus = .authorized
        let recordingStartExpectation = expectation(description: "Recording started")
        
        sut.$isRecording
            .dropFirst()
            .sink { isRecording in
                if isRecording {
                    recordingStartExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: User taps "Start Recording" button
        await sut.startRecording()
        
        // Then: Should begin recording and track analytics
        await fulfillment(of: [recordingStartExpectation], timeout: 2.0)
        XCTAssertTrue(sut.isRecording)
        XCTAssertTrue(mockAudioRecorder.startRecordingCalled)
        XCTAssertNil(sut.recordingError)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_recording_started")
    }
    
    func testUserStopsVoiceRecording() async {
        // Given: User is recording their voice
        sut.permissionStatus = .authorized
        await sut.startRecording()
        XCTAssertTrue(sut.isRecording)
        
        let mockRecording = createMockRecording()
        mockAudioRecorder.mockRecording = mockRecording
        
        // When: User taps "Stop Recording" button
        await sut.stopRecording()
        
        // Then: Should stop recording and save the recording
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(mockAudioRecorder.stopRecordingCalled)
        XCTAssertNotNil(sut.currentRecording)
        XCTAssertEqual(sut.currentRecording?.id, mockRecording.id)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_recording_completed")
    }
    
    func testUserCompletesOnboarding() async throws {
        // Given: User has completed voice recording and analysis
        sut.permissionStatus = .authorized
        sut.userId = "test-user-123"
        
        // Navigate through screens
        sut.navigateToNextScreen() // To permission
        sut.navigateToNextScreen() // To vocal test
        
        // Complete recording
        await sut.startRecording()
        mockAudioRecorder.mockRecording = createMockRecording()
        await sut.stopRecording()
        
        // Complete analysis
        mockF0Service.mockF0Result = F0Feature(
            mean: 220.5,
            std: 15.2,
            min: 190.0,
            max: 250.0,
            confidence: 0.88
        )
        try await sut.analyzeRecording()
        
        // Complete upload
        try await sut.uploadRecording()
        
        // When: User completes onboarding
        await sut.completeOnboarding()
        
        // Then: Should navigate to completion screen and track analytics
        XCTAssertEqual(sut.currentScreen, .completion)
        XCTAssertTrue(mockAnalyticsService.logEventCalled)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_completed")
    }
    
    func testUserHandlesRecordingError() async {
        // Given: User attempts to record without permission
        sut.permissionStatus = .denied
        
        // When: User tries to start recording
        await sut.startRecording()
        
        // Then: Should show error message and not start recording
        XCTAssertFalse(sut.isRecording)
        XCTAssertFalse(mockAudioRecorder.startRecordingCalled)
        XCTAssertNotNil(sut.recordingError)
        XCTAssertEqual(sut.recordingError, "Microphone permission is required")
    }
    
    // MARK: - Helper Methods
    
    private func createMockRecording() -> Recording {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.wav")
        return Recording(
            id: "test-recording-123",
            audioURL: tempURL,
            duration: 5.0,
            createdAt: Date(),
            userId: "test-user-123"
        )
    }
}

// MARK: - Mock Classes

class MockOnboardingAudioRecorder: OnboardingAudioRecorder {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var uploadRecordingCalled = false
    var lastUploadedRecordingId: String?
    var shouldFailToStart = false
    var mockRecording: Recording?
    
    private var durationPublisher = PassthroughSubject<TimeInterval, Never>()
    private var uploadProgressPublisher = PassthroughSubject<Double, Never>()
    
    override func startRecording() async throws {
        startRecordingCalled = true
        if shouldFailToStart {
            throw RecordingError.failedToStart
        }
    }
    
    override func stopRecording() async throws -> Recording? {
        stopRecordingCalled = true
        return mockRecording
    }
    
    override func uploadRecording(_ recording: Recording, userId: String) async throws {
        uploadRecordingCalled = true
        lastUploadedRecordingId = recording.id
    }
    
    override var recordingDuration: AnyPublisher<TimeInterval, Never> {
        durationPublisher.eraseToAnyPublisher()
    }
    
    override var uploadProgress: AnyPublisher<Double, Never> {
        uploadProgressPublisher.eraseToAnyPublisher()
    }
    
    func simulateDurationUpdate(_ duration: TimeInterval) {
        durationPublisher.send(duration)
    }
    
    func simulateUploadProgress(_ progress: Double) {
        uploadProgressPublisher.send(progress)
    }
}

class MockMicrophonePermissionManager: MicrophonePermissionManager {
    var requestPermissionCalled = false
    var mockPermissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    override var permissionStatus: AVAudioSession.RecordPermission {
        mockPermissionStatus
    }
    
    override func requestPermission() async -> AVAudioSession.RecordPermission {
        requestPermissionCalled = true
        return mockPermissionStatus
    }
}

class MockF0DataService: F0DataService {
    var analyzeF0Called = false
    var lastAnalyzedURL: URL?
    var mockF0Result: F0Feature?
    var shouldFailAnalysis = false
    
    override func analyzeF0(from audioURL: URL) async throws -> F0Feature {
        analyzeF0Called = true
        lastAnalyzedURL = audioURL
        
        if shouldFailAnalysis {
            throw AnalysisError.failed
        }
        
        return mockF0Result ?? F0Feature(
            mean: 220.0,
            std: 15.0,
            min: 190.0,
            max: 250.0,
            confidence: 0.85
        )
    }
}

class MockAnalyticsService: AnalyticsService {
    var logEventCalled = false
    var lastLoggedEvent: String?
    var lastEventParameters: [String: Any]?
    
    override func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        logEventCalled = true
        lastLoggedEvent = name
        lastEventParameters = parameters
    }
}

// MARK: - Test Errors

enum RecordingError: Error {
    case failedToStart
}

enum AnalysisError: Error {
    case failed
}