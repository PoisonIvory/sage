//
//  HybridVocalAnalysisServiceTests.swift
//  SageTests
//
//  Tests for the hybrid vocal analysis service that orchestrates local and cloud analysis
//

import XCTest
import Combine
@testable import Sage

@MainActor
final class HybridVocalAnalysisServiceTests: XCTestCase {
    
    private var sut: HybridVocalAnalysisService!
    private var mockLocalAnalyzer: MockLocalVoiceAnalyzer!
    private var mockCloudService: MockCloudVoiceAnalysisService!
    private var mockFirestoreListener: MockVocalResultsListener!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockLocalAnalyzer = MockLocalVoiceAnalyzer()
        mockCloudService = MockCloudVoiceAnalysisService()
        mockFirestoreListener = MockVocalResultsListener()
        
        sut = HybridVocalAnalysisService(
            localAnalyzer: mockLocalAnalyzer,
            cloudService: mockCloudService,
            firestoreListener: mockFirestoreListener
        )
        
        cancellables = []
    }
    
    override func tearDown() async throws {
        sut.stopListening()
        cancellables = nil
        sut = nil
        mockLocalAnalyzer = nil
        mockCloudService = nil
        mockFirestoreListener = nil
        
        try await super.tearDown()
    }
    
    // MARK: - User Flow Tests
    
    func testUserStartsVoiceAnalysis() async throws {
        // Given: User has completed a voice recording
        let recording = createTestRecording()
        
        // When: User initiates voice analysis
        let result = try await sut.analyzeVoice(recording: recording)
        
        // Then: Should receive immediate local analysis results
        XCTAssertEqual(result.recordingId, recording.id)
        XCTAssertEqual(result.status, .localComplete)
        XCTAssertNotNil(result.localMetrics)
        XCTAssertTrue(mockLocalAnalyzer.analyzeImmediateCalled)
    }
    
    func testUserReceivesCloudAnalysisResults() async throws {
        // Given: User has completed voice analysis with local results
        let recording = createTestRecording()
        let biomarkers = createTestBiomarkers()
        
        let updateExpectation = expectation(description: "Receive cloud analysis results")
        
        // When: User waits for comprehensive analysis
        let stream = sut.subscribeToResults()
        
        Task {
            for await receivedBiomarkers in stream {
                if receivedBiomarkers.stability.score == biomarkers.stability.score {
                    updateExpectation.fulfill()
                    break
                }
            }
        }
        
        // Simulate cloud processing completion
        mockFirestoreListener.simulateUpdate(biomarkers)
        
        // Then: Should receive comprehensive voice biomarkers
        await fulfillment(of: [updateExpectation], timeout: 2.0)
        XCTAssertTrue(mockCloudService.uploadAndAnalyzeCalled)
    }
    
    func testUserSeesAnalysisProgress() async throws {
        // Given: User has started voice analysis
        let recording = createTestRecording()
        let stateExpectation = expectation(description: "Analysis progress updates")
        stateExpectation.expectedFulfillmentCount = 2 // idle -> localAnalyzing -> localComplete
        
        var states: [VocalAnalysisState] = []
        sut.$currentState
            .sink { state in
                states.append(state)
                if states.count <= 2 {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: User monitors analysis progress
        _ = try await sut.analyzeVoice(recording: recording)
        
        // Then: Should see progress from idle to local analysis to completion
        await fulfillment(of: [stateExpectation], timeout: 2.0)
        XCTAssertEqual(states[0], .idle)
        XCTAssertEqual(states[1], .localAnalyzing)
    }
    
    func testUserHandlesAnalysisError() async throws {
        // Given: User has a recording with poor audio quality
        let recording = createTestRecording()
        mockLocalAnalyzer.shouldFailValidation = true
        
        // When: User attempts to analyze poor quality recording
        do {
            _ = try await sut.analyzeVoice(recording: recording)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then: Should receive clear error message about audio quality
            if case VocalAnalysisError.invalidAudioQuality = error {
                XCTAssertEqual(sut.currentState, .error("Local analysis failed: Audio quality insufficient: Invalid audio"))
            } else {
                XCTFail("Expected invalidAudioQuality error, got \(error)")
            }
        }
    }
    
    func testUserStopsListeningForUpdates() {
        // Given: User is receiving real-time analysis updates
        
        // When: User stops listening for updates
        sut.stopListening()
        
        // Then: Should stop receiving updates and return to idle state
        XCTAssertTrue(mockFirestoreListener.stopListeningCalled)
        XCTAssertEqual(sut.currentState, .idle)
    }
    
    // MARK: - Helper Methods
    
    private func createTestRecording() -> VoiceRecording {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.wav")
        return VoiceRecording(
            id: "test-recording-123",
            audioURL: tempURL,
            duration: 5.0,
            userId: "test-user-456"
        )
    }
    
    private func createTestBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 220.5, std: 15.2, confidence: 88.5)
        let jitter = JitterMeasures(local: 0.824, absolute: 0.002, rap: 0.756, ppq5: 0.891)
        let shimmer = ShimmerMeasures(local: 3.245, db: 0.282, apq3: 2.876, apq5: 3.521)
        let hnr = HNRAnalysis(mean: 19.2, std: 2.1)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(
            score: 82.5,
            components: StabilityComponents(
                f0Score: 35.4,
                jitterScore: 16.5,
                shimmerScore: 15.6,
                hnrScore: 15.0
            )
        )
        let metadata = VoiceAnalysisMetadata(
            recordingDuration: 5.0,
            sampleRate: 48000.0,
            voicedRatio: 0.85,
            analysisTimestamp: Date(),
            analysisSource: .cloudParselmouth
        )
        
        return VocalBiomarkers(
            f0: f0,
            voiceQuality: voiceQuality,
            stability: stability,
            metadata: metadata
        )
    }
}

// MARK: - Mock Classes

class MockLocalVoiceAnalyzer: LocalVoiceAnalyzer {
    var validateAudioQualityCalled = false
    var analyzeImmediateCalled = false
    var shouldFailValidation = false
    var mockMetrics = BasicVoiceMetrics(
        f0Mean: 220.5,
        f0Std: 15.0,
        confidence: 85.0,
        analysisDate: Date()
    )
    
    override func validateAudioQuality(audioURL: URL) throws -> AudioQualityResult {
        validateAudioQualityCalled = true
        if shouldFailValidation {
            return AudioQualityResult(isValid: false, reason: "Invalid audio")
        }
        return AudioQualityResult(isValid: true, reason: nil)
    }
    
    override func analyzeImmediate(audioURL: URL) async throws -> BasicVoiceMetrics {
        analyzeImmediateCalled = true
        return mockMetrics
    }
}

class MockCloudVoiceAnalysisService: CloudVoiceAnalysisService {
    var uploadAndAnalyzeCalled = false
    var lastUploadedRecordingId: String?
    var uploadExpectation: XCTestExpectation?
    var failureCount = 0
    var uploadAttempts = 0
    
    override func uploadAndAnalyze(recording: VoiceRecording) async throws {
        uploadAttempts += 1
        lastUploadedRecordingId = recording.id
        
        if failureCount > 0 {
            failureCount -= 1
            throw VocalAnalysisError.networkError(NSError(domain: "Test", code: -1))
        }
        
        uploadAndAnalyzeCalled = true
        uploadExpectation?.fulfill()
    }
}

class MockVocalResultsListener: VocalResultsListener {
    var startListeningCalled = false
    var stopListeningCalled = false
    var listeningRecordingId: String?
    
    override func startListening(for recordingId: String) {
        startListeningCalled = true
        listeningRecordingId = recordingId
    }
    
    override func stopListening() {
        stopListeningCalled = true
    }
    
    func simulateUpdate(_ biomarkers: VocalBiomarkers) {
        resultsPublisher.send(biomarkers)
    }
}