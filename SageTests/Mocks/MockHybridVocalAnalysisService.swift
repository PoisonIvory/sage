import Foundation
import Combine
@testable import Sage

/// Mock implementation of HybridVocalAnalysisService for testing
/// Provides controlled test behavior for voice analysis scenarios
@MainActor
class MockHybridVocalAnalysisService: HybridVocalAnalysisService {
    
    // MARK: - Test Control Properties
    
    var analyzeVoiceCalled = false
    var lastAnalyzedRecording: VoiceRecording?
    var shouldFailAnalysis = false
    var shouldFailValidation = false
    var mockAnalysisResult: VocalAnalysisResult?
    var analyzeVoiceExpectation: XCTestExpectation?
    
    // MARK: - Mock Implementation
    
    override func analyzeVoice(recording: VoiceRecording, bypassQualityCheck: Bool = false) async throws -> VocalAnalysisResult {
        analyzeVoiceCalled = true
        lastAnalyzedRecording = recording
        analyzeVoiceExpectation?.fulfill()
        
        if shouldFailAnalysis {
            throw VocalAnalysisError.localAnalysisFailed(NSError(domain: "Test", code: -1))
        }
        
        if shouldFailValidation {
            throw VocalAnalysisError.invalidAudioQuality("Invalid audio")
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
            // Mock implementation - can be customized for specific tests
            continuation.finish()
        }
    }
    
    override func stopListening() {
        // Mock implementation
    }
    
    // MARK: - Test Helper Methods
    
    func simulateStateChange(_ state: VocalAnalysisState) {
        currentState = state
    }
    
    func simulateBiomarkersUpdate(_ biomarkers: VocalBiomarkers) {
        // Simulate biomarkers update through the results stream
    }
    
    func reset() {
        analyzeVoiceCalled = false
        lastAnalyzedRecording = nil
        shouldFailAnalysis = false
        shouldFailValidation = false
        mockAnalysisResult = nil
        analyzeVoiceExpectation = nil
        currentState = .idle
    }
} 