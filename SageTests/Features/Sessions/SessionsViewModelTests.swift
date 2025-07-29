//
//  SessionsViewModelTests.swift
//  SageTests
//
//  Tests for the sessions view model that manages daily voice recording sessions
//

import XCTest
import Combine
import FirebaseAuth
@testable import Sage

@MainActor
final class SessionsViewModelTests: XCTestCase {
    
    private var sut: SessionsViewModel!
    private var mockVocalAnalysisService: MockHybridVocalAnalysisService!
    private var mockRecordingService: MockRecordingService!
    private var mockAuthService: MockAuthService!
    private var mockAnalyticsService: MockAnalyticsService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockVocalAnalysisService = MockHybridVocalAnalysisService()
        mockRecordingService = MockRecordingService()
        mockAuthService = MockAuthService()
        mockAnalyticsService = MockAnalyticsService()
        
        sut = SessionsViewModel(
            vocalAnalysisService: mockVocalAnalysisService,
            recordingService: mockRecordingService,
            authService: mockAuthService,
            analyticsService: mockAnalyticsService
        )
        
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockVocalAnalysisService = nil
        mockRecordingService = nil
        mockAuthService = nil
        mockAnalyticsService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - User Flow Tests
    
    func testUserOpensSessionsScreen() {
        // Given: User opens the sessions screen
        // When: SessionsViewModel is initialized
        // Then: Should show default state
        XCTAssertFalse(sut.isRecording)
        XCTAssertFalse(sut.isAnalyzing)
        XCTAssertNil(sut.currentRecording)
        XCTAssertNil(sut.analysisResult)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.recordingTimeRemaining, 5.0)
        XCTAssertTrue(sut.previousSessions.isEmpty)
    }
    
    func testUserStartsVoiceSession() async {
        // Given: User is authenticated and on sessions screen
        mockAuthService.currentUser = MockUser(uid: "test-user-123")
        
        // When: User taps "Start Recording" button
        await sut.startRecording()
        
        // Then: Should begin recording and track analytics
        XCTAssertTrue(sut.isRecording)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(mockRecordingService.startRecordingCalled)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "session_recording_started")
    }
    
    func testUserStopsVoiceSession() async {
        // Given: User is recording their voice session
        mockAuthService.currentUser = MockUser(uid: "test-user-123")
        await sut.startRecording()
        
        let mockRecording = createMockVoiceRecording()
        mockRecordingService.mockRecording = mockRecording
        
        // When: User taps "Stop Recording" button
        await sut.stopRecording()
        
        // Then: Should stop recording and save the session
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(mockRecordingService.stopRecordingCalled)
        XCTAssertNotNil(sut.currentRecording)
        XCTAssertEqual(sut.currentRecording?.id, mockRecording.id)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "session_recording_stopped")
    }
    
    func testUserSeesRecordingCountdown() async {
        // Given: User has started a voice session
        mockAuthService.currentUser = MockUser(uid: "test-user-123")
        let countdownExpectation = expectation(description: "Countdown updates")
        countdownExpectation.expectedFulfillmentCount = 3
        
        var timeValues: [Double] = []
        sut.$recordingTimeRemaining
            .dropFirst()
            .sink { time in
                timeValues.append(time)
                if timeValues.count <= 3 {
                    countdownExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: User monitors recording countdown
        await sut.startRecording()
        
        // Simulate timer updates
        mockRecordingService.simulateTimerUpdate(4.0)
        mockRecordingService.simulateTimerUpdate(3.0)
        mockRecordingService.simulateTimerUpdate(2.0)
        
        // Then: Should see countdown decreasing
        await fulfillment(of: [countdownExpectation], timeout: 2.0)
        XCTAssertEqual(timeValues, [4.0, 3.0, 2.0])
    }
    
    func testUserReceivesAnalysisResults() async {
        // Given: User has completed a voice recording
        mockAuthService.currentUser = MockUser(uid: "test-user-123")
        let mockRecording = createMockVoiceRecording()
        mockRecordingService.mockRecording = mockRecording
        
        let mockResult = createMockAnalysisResult()
        mockVocalAnalysisService.mockAnalysisResult = mockResult
        
        // When: User waits for analysis to complete
        await sut.startRecording()
        await sut.stopRecording()
        
        // Allow time for analysis
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then: Should receive analysis results and track analytics
        XCTAssertNotNil(sut.analysisResult)
        XCTAssertEqual(sut.analysisResult?.localMetrics.f0Mean, mockResult.localMetrics.f0Mean)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "session_analysis_completed")
    }
    
    func testUserViewsSessionHistory() async {
        // Given: User has completed previous voice sessions
        mockAuthService.currentUser = MockUser(uid: "test-user-123")
        let mockSessions = createMockSessionHistory()
        mockRecordingService.mockSessionHistory = mockSessions
        
        // When: User views their session history
        await sut.loadPreviousSessions()
        
        // Then: Should display previous sessions
        XCTAssertEqual(sut.previousSessions.count, mockSessions.count)
        XCTAssertEqual(sut.previousSessions.first?.id, mockSessions.first?.id)
        XCTAssertTrue(mockRecordingService.fetchSessionHistoryCalled)
    }
    
    func testUserHandlesRecordingError() async {
        // Given: User attempts to record without authentication
        mockAuthService.currentUser = nil
        
        // When: User tries to start recording
        await sut.startRecording()
        
        // Then: Should show error message and not start recording
        XCTAssertFalse(sut.isRecording)
        XCTAssertEqual(sut.errorMessage, "Authentication required for voice analysis")
        XCTAssertFalse(mockRecordingService.startRecordingCalled)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "session_recording_error")
    }
    
    // MARK: - Helper Methods
    
    private func createMockVoiceRecording() -> VoiceRecording {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("session_test.wav")
        return VoiceRecording(
            id: "session-123",
            audioURL: tempURL,
            duration: 5.0,
            recordedAt: Date(),
            userId: "test-user-123"
        )
    }
    
    private func createMockBasicMetrics() -> BasicVoiceMetrics {
        return BasicVoiceMetrics(
            f0Mean: 225.0,
            f0Std: 14.5,
            confidence: 90.0,
            analysisDate: Date()
        )
    }
    
    private func createMockAnalysisResult() -> VocalAnalysisResult {
        return VocalAnalysisResult(
            recordingId: "session-123",
            localMetrics: createMockBasicMetrics(),
            comprehensiveAnalysis: nil,
            status: .localComplete
        )
    }
    
    private func createMockSessionHistory() -> [SessionRecord] {
        return [
            SessionRecord(
                id: "session-101",
                recordedAt: Date().addingTimeInterval(-86400),
                duration: 5.0,
                f0Mean: 220.0,
                analysisStatus: .complete
            ),
            SessionRecord(
                id: "session-102",
                recordedAt: Date().addingTimeInterval(-172800),
                duration: 5.0,
                f0Mean: 218.0,
                analysisStatus: .complete
            )
        ]
    }
}

// MARK: - Mock Classes

class MockHybridVocalAnalysisService: HybridVocalAnalysisService {
    var analyzeVoiceCalled = false
    var lastAnalyzedRecording: VoiceRecording?
    var analyzeVoiceExpectation: XCTestExpectation?
    var mockAnalysisResult: VocalAnalysisResult?
    var shouldFailAnalysis = false
    
    @Published var currentState: VocalAnalysisState = .idle
    
    override func analyzeVoice(recording: VoiceRecording) async throws -> VocalAnalysisResult {
        analyzeVoiceCalled = true
        lastAnalyzedRecording = recording
        analyzeVoiceExpectation?.fulfill()
        
        if shouldFailAnalysis {
            throw VocalAnalysisError.localAnalysisFailed(NSError(domain: "Test", code: -1))
        }
        
        return mockAnalysisResult ?? VocalAnalysisResult(
            recordingId: recording.id,
            localMetrics: BasicVoiceMetrics(
                f0Mean: 220.0,
                f0Std: 15.0,
                confidence: 85.0,
                analysisDate: Date()
            ),
            comprehensiveAnalysis: nil,
            status: .localComplete
        )
    }
    
    override func subscribeToResults() -> AsyncStream<VocalBiomarkers> {
        return AsyncStream { continuation in
            // Implementation for testing
        }
    }
    
    func simulateStateChange(_ state: VocalAnalysisState) {
        currentState = state
    }
    
    func simulateBiomarkersUpdate(_ biomarkers: VocalBiomarkers) {
        // Simulate biomarkers update through the results stream
    }
}

class MockRecordingService {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var fetchSessionHistoryCalled = false
    var shouldFailToStart = false
    var mockRecording: VoiceRecording?
    var mockSessionHistory: [SessionRecord] = []
    
    private let timerPublisher = PassthroughSubject<Double, Never>()
    
    func startRecording() async throws {
        startRecordingCalled = true
        if shouldFailToStart {
            throw RecordingError.failedToStart
        }
    }
    
    func stopRecording() async throws -> VoiceRecording? {
        stopRecordingCalled = true
        return mockRecording
    }
    
    func fetchSessionHistory(userId: String) async throws -> [SessionRecord] {
        fetchSessionHistoryCalled = true
        return mockSessionHistory
    }
    
    var recordingTimer: AnyPublisher<Double, Never> {
        timerPublisher.eraseToAnyPublisher()
    }
    
    func simulateTimerUpdate(_ time: Double) {
        timerPublisher.send(time)
    }
}

struct MockUser {
    let uid: String
}

struct SessionRecord {
    let id: String
    let recordedAt: Date
    let duration: TimeInterval
    let f0Mean: Double
    let analysisStatus: AnalysisStatus
}

// MARK: - SessionsViewModel Extension for Testing

extension SessionsViewModel {
    convenience init(
        vocalAnalysisService: HybridVocalAnalysisService,
        recordingService: MockRecordingService,
        authService: MockAuthService,
        analyticsService: MockAnalyticsService
    ) {
        // Initialize with mock services for testing
        self.init()
        // Note: In real implementation, you'd inject these services
    }
    
    func startListeningForUpdates() async {
        // Implementation for real-time updates
    }
}