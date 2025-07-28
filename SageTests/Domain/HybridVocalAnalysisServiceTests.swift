import XCTest
import Combine
@testable import Sage

// MARK: - Comprehensive Test Suite for HybridVocalAnalysisService

@MainActor
class HybridVocalAnalysisServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    private var sut: HybridVocalAnalysisService!
    private var mockLocalAnalyzer: MockLocalVoiceAnalyzer!
    private var mockCloudService: MockCloudVoiceAnalysisService!
    private var mockFirestoreListener: MockVocalResultsListener!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockLocalAnalyzer = MockLocalVoiceAnalyzer()
        mockCloudService = MockCloudVoiceAnalysisService()
        mockFirestoreListener = MockVocalResultsListener()
        cancellables = Set<AnyCancellable>()
        
        sut = HybridVocalAnalysisService(
            localAnalyzer: mockLocalAnalyzer,
            cloudService: mockCloudService,
            firestoreListener: mockFirestoreListener
        )
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sut.stopListening()
        sut = nil
        mockLocalAnalyzer = nil
        mockCloudService = nil
        mockFirestoreListener = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Hybrid Analysis Flow Tests
    
    /// GWT: Given user completes voice recording
    /// GWT: When performing hybrid analysis with successful local processing
    /// GWT: Then receives immediate local results and triggers cloud analysis
    func testSuccessfulHybridAnalysisFlow() async throws {
        // Given: Valid voice recording
        let recording = createTestVoiceRecording()
        let expectedLocalMetrics = BasicVoiceMetrics(
            f0Mean: 220.0,
            f0Std: 15.0,
            confidence: 85.0,
            jitterLocal: 0.8,
            shimmerLocal: 3.0,
            analysisSource: .localIOS,
            processingTime: Date().timeIntervalSince1970
        )
        
        mockLocalAnalyzer.mockValidationResult = AudioQualityResult(isValid: true, reason: "Good quality")
        mockLocalAnalyzer.mockAnalysisResult = expectedLocalMetrics
        
        // When: Performing hybrid analysis
        let result = try await sut.analyzeVoice(recording: recording)
        
        // Then: Should return immediate local results
        XCTAssertEqual(result.recordingId, recording.id, "Result should include recording ID")
        XCTAssertEqual(result.localMetrics, expectedLocalMetrics, "Should return expected local metrics")
        XCTAssertEqual(result.status, .localComplete, "Status should indicate local analysis complete")
        XCTAssertNil(result.comprehensiveAnalysis, "Comprehensive analysis should not be available immediately")
        
        // And: Should trigger cloud analysis
        XCTAssertTrue(mockCloudService.uploadAndAnalyzeCalled, "Should trigger cloud analysis")
        XCTAssertEqual(mockCloudService.lastRecording?.id, recording.id, "Should upload correct recording")
        
        // And: Should start listening for Firestore results
        XCTAssertTrue(mockFirestoreListener.startListeningCalled, "Should start listening for results")
        XCTAssertEqual(mockFirestoreListener.lastRecordingId, recording.id, "Should listen for correct recording ID")
        
        // And: State should reflect local completion
        if case .localComplete(let metrics) = sut.currentState {
            XCTAssertEqual(metrics, expectedLocalMetrics, "State should contain local metrics")
        } else {
            XCTFail("Expected localComplete state, got: \(sut.currentState)")
        }
    }
    
    /// GWT: Given local analysis fails due to poor audio quality
    /// GWT: When attempting hybrid analysis
    /// GWT: Then should fail with appropriate error and not trigger cloud analysis
    func testLocalAnalysisFailureDueToPoorAudioQuality() async {
        // Given: Recording with poor audio quality
        let recording = createTestVoiceRecording()
        mockLocalAnalyzer.mockValidationResult = AudioQualityResult(
            isValid: false, 
            reason: "Recording too short (minimum 0.5 seconds)"
        )
        
        // When: Attempting hybrid analysis
        do {
            _ = try await sut.analyzeVoice(recording: recording)
            XCTFail("Expected analysis to fail due to poor audio quality")
        } catch {
            // Then: Should fail with audio quality error
            if case VocalAnalysisError.invalidAudioQuality(let reason) = error {
                XCTAssertEqual(reason, "Recording too short (minimum 0.5 seconds)", "Should provide specific quality issue")
            } else {
                XCTFail("Expected invalidAudioQuality error, got: \(error)")
            }
        }
        
        // And: Should not trigger cloud analysis
        XCTAssertFalse(mockCloudService.uploadAndAnalyzeCalled, "Should not trigger cloud analysis for invalid audio")
        
        // And: State should reflect error
        if case .error(let message) = sut.currentState {
            XCTAssertTrue(message.contains("Local analysis failed"), "Error state should indicate local analysis failure")
        } else {
            XCTFail("Expected error state, got: \(sut.currentState)")
        }
    }
    
    /// GWT: Given cloud analysis fails after successful local analysis
    /// GWT: When local analysis completes but cloud upload fails
    /// GWT: Then should maintain local results and report cloud error
    func testCloudAnalysisFailureAfterSuccessfulLocalAnalysis() async throws {
        // Given: Successful local analysis but failing cloud service
        let recording = createTestVoiceRecording()
        let localMetrics = BasicVoiceMetrics(
            f0Mean: 210.0,
            f0Std: 18.0,
            confidence: 78.0,
            jitterLocal: 1.2,
            shimmerLocal: 4.5,
            analysisSource: .localIOS,
            processingTime: Date().timeIntervalSince1970
        )
        
        mockLocalAnalyzer.mockValidationResult = AudioQualityResult(isValid: true, reason: "Good quality")
        mockLocalAnalyzer.mockAnalysisResult = localMetrics
        mockCloudService.shouldFailUpload = true
        mockCloudService.uploadError = VocalAnalysisError.networkError(NSError(domain: "test", code: -1, userInfo: nil))
        
        // When: Performing hybrid analysis
        let result = try await sut.analyzeVoice(recording: recording)
        
        // Then: Should still return local results
        XCTAssertEqual(result.localMetrics, localMetrics, "Should preserve local analysis results")
        XCTAssertEqual(result.status, .localComplete, "Status should indicate local completion")
        
        // And: Should eventually show cloud error in state
        // Note: Cloud analysis runs asynchronously, so we need to wait briefly
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        if case .error(let message) = sut.currentState {
            XCTAssertTrue(message.contains("Cloud analysis failed"), "Should report cloud analysis failure")
        } else {
            XCTFail("Expected error state for cloud failure, got: \(sut.currentState)")
        }
    }
    
    // MARK: - Real-time Results Subscription Tests
    
    /// GWT: Given cloud analysis writes results to Firestore
    /// GWT: When subscribing to real-time updates
    /// GWT: Then receives comprehensive VocalBiomarkers when available
    func testRealTimeResultsSubscription() async throws {
        // Given: Service subscribed to results
        let expectation = XCTestExpectation(description: "Receive comprehensive results")
        
        let resultsStream = sut.subscribeToResults()
        let task = Task {
            for await biomarkers in resultsStream {
                // Then: Should receive comprehensive biomarkers
                XCTAssertGreaterThan(biomarkers.f0.mean, 0, "Should receive valid F0 data")
                XCTAssertGreaterThan(biomarkers.stability.score, 0, "Should receive valid stability score")
                XCTAssertEqual(biomarkers.voiceQuality.jitter.local, 0.8, "Should receive expected jitter data")
                expectation.fulfill()
                break
            }
        }
        
        // When: Mock Firestore listener publishes results
        let comprehensiveBiomarkers = createTestVocalBiomarkers()
        mockFirestoreListener.simulateResultsReceived(comprehensiveBiomarkers)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()
    }
    
    /// GWT: Given Firestore listener encounters error
    /// GWT: When subscription fails
    /// GWT: Then should handle error gracefully
    func testRealTimeResultsSubscriptionError() async {
        // Given: Service subscribed to results
        let expectation = XCTestExpectation(description: "Handle subscription error")
        
        let resultsStream = sut.subscribeToResults()
        let task = Task {
            do {
                for await _ in resultsStream {
                    XCTFail("Should not receive results on error")
                }
            } catch {
                // Then: Should handle error gracefully
                expectation.fulfill()
            }
        }
        
        // When: Mock Firestore listener fails
        let testError = NSError(domain: "test.firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firestore connection failed"])
        mockFirestoreListener.simulateError(testError)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()
    }
    
    // MARK: - State Management Tests
    
    /// GWT: Given hybrid analysis service state transitions
    /// GWT: When progressing through analysis phases
    /// GWT: Then should update state appropriately at each phase
    func testStateTransitionsDuringSuccessfulAnalysis() async throws {
        // Given: Service starts in idle state
        XCTAssertEqual(sut.currentState, .idle, "Should start in idle state")
        
        let recording = createTestVoiceRecording()
        let localMetrics = BasicVoiceMetrics(
            f0Mean: 195.0,
            f0Std: 12.0,
            confidence: 90.0,
            jitterLocal: 0.6,
            shimmerLocal: 2.8,
            analysisSource: .localIOS,
            processingTime: Date().timeIntervalSince1970
        )
        
        mockLocalAnalyzer.mockValidationResult = AudioQualityResult(isValid: true, reason: "Excellent quality")
        mockLocalAnalyzer.mockAnalysisResult = localMetrics
        
        // When: Starting analysis
        let analysisTask = Task {
            return try await sut.analyzeVoice(recording: recording)
        }
        
        // Brief delay to allow state transition
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        // Then: Should transition through expected states
        // Note: Due to async nature, we check final state after completion
        let result = try await analysisTask.value
        
        if case .localComplete(let metrics) = sut.currentState {
            XCTAssertEqual(metrics, localMetrics, "Should contain expected local metrics")
        } else {
            XCTFail("Expected localComplete state after local analysis, got: \(sut.currentState)")
        }
        
        // When: Comprehensive results arrive
        let comprehensiveBiomarkers = createTestVocalBiomarkers()
        mockFirestoreListener.simulateResultsReceived(comprehensiveBiomarkers)
        
        // Brief delay for state update
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then: Should transition to complete state
        if case .complete(let biomarkers) = sut.currentState {
            XCTAssertEqual(biomarkers.f0.mean, comprehensiveBiomarkers.f0.mean, "Should contain comprehensive results")
        } else {
            XCTFail("Expected complete state after comprehensive analysis, got: \(sut.currentState)")
        }
    }
    
    // MARK: - Resource Management Tests
    
    /// GWT: Given service needs cleanup
    /// GWT: When stopping listening
    /// GWT: Then should cleanup resources and reset state
    func testResourceCleanupOnStopListening() {
        // Given: Service with active subscriptions
        _ = sut.subscribeToResults()
        mockFirestoreListener.startListeningCalled = true
        
        // When: Stopping listening
        sut.stopListening()
        
        // Then: Should cleanup resources
        XCTAssertTrue(mockFirestoreListener.stopListeningCalled, "Should stop Firestore listener")
        XCTAssertEqual(sut.currentState, .idle, "Should reset to idle state")
    }
    
    // MARK: - Helper Methods
    
    private func createTestVoiceRecording() -> VoiceRecording {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.wav")
        return VoiceRecording(
            id: "test-recording-123",
            audioURL: tempURL,
            duration: 3.0,
            recordedAt: Date(),
            userId: "test-user-456"
        )
    }
    
    private func createTestVocalBiomarkers() -> VocalBiomarkers {
        let f0Analysis = F0Analysis(mean: 215.0, std: 14.0, confidence: 88.0)
        
        let jitterMeasures = JitterMeasures(local: 0.8, absolute: 16.0, rap: 0.7, ppq5: 0.9)
        let shimmerMeasures = ShimmerMeasures(local: 3.2, db: 0.32, apq3: 2.8, apq5: 3.5)
        let hnrAnalysis = HNRAnalysis(mean: 19.5, std: 2.1)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitterMeasures, shimmer: shimmerMeasures, hnr: hnrAnalysis)
        
        let stabilityComponents = StabilityComponents(f0Score: 88.0, jitterScore: 85.0, shimmerScore: 82.0, hnrScore: 79.0)
        let stability = VocalStabilityScore(score: 84.0, components: stabilityComponents)
        
        let metadata = VoiceAnalysisMetadata(
            recordingDuration: 3.0,
            sampleRate: 48000.0,
            voicedRatio: 0.88,
            analysisTimestamp: Date(),
            analysisSource: .cloudParselmouth
        )
        
        return VocalBiomarkers(f0: f0Analysis, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
}

// MARK: - Mock Classes

class MockLocalVoiceAnalyzer: LocalVoiceAnalyzer {
    var mockValidationResult: AudioQualityResult = AudioQualityResult(isValid: true, reason: "Valid")
    var mockAnalysisResult: BasicVoiceMetrics = BasicVoiceMetrics(
        f0Mean: 220.0, f0Std: 15.0, confidence: 85.0, 
        jitterLocal: 0.8, shimmerLocal: 3.0, 
        analysisSource: .localIOS, processingTime: 0.0
    )
    
    override func validateAudioQuality(audioURL: URL) throws -> AudioQualityResult {
        return mockValidationResult
    }
    
    override func analyzeImmediate(audioURL: URL) async throws -> BasicVoiceMetrics {
        if !mockValidationResult.isValid {
            throw LocalAnalysisError.audioProcessingFailed
        }
        return mockAnalysisResult
    }
}

class MockCloudVoiceAnalysisService: CloudVoiceAnalysisService {
    var uploadAndAnalyzeCalled = false
    var lastRecording: VoiceRecording?
    var shouldFailUpload = false
    var uploadError: Error?
    
    override func uploadAndAnalyze(recording: VoiceRecording) async throws {
        uploadAndAnalyzeCalled = true
        lastRecording = recording
        
        if shouldFailUpload {
            throw uploadError ?? VocalAnalysisError.cloudAnalysisFailed(NSError(domain: "test", code: -1, userInfo: nil))
        }
    }
}

class MockVocalResultsListener: VocalResultsListener {
    var startListeningCalled = false
    var stopListeningCalled = false
    var lastRecordingId: String?
    
    override func startListening(for recordingId: String) {
        startListeningCalled = true
        lastRecordingId = recordingId
    }
    
    override func stopListening() {
        stopListeningCalled = true
    }
    
    func simulateResultsReceived(_ biomarkers: VocalBiomarkers) {
        resultsPublisher.send(biomarkers)
    }
    
    func simulateError(_ error: Error) {
        resultsPublisher.send(completion: .failure(error))
    }
}