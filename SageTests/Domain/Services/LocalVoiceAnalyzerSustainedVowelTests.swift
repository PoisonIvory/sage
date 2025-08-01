import XCTest
import AVFoundation
@testable import Sage

/// Tests for LocalVoiceAnalyzer sustained vowel analysis
/// GWT: Given need to test sustained vowel analysis
/// GWT: When LocalVoiceAnalyzer processes sustained vowel recordings
/// GWT: Then should provide meaningful F0 analysis without speech recognition
@MainActor
final class LocalVoiceAnalyzerSustainedVowelTests: XCTestCase {
    
    var analyzer: LocalVoiceAnalyzer!
    
    override func setUp() {
        super.setUp()
        analyzer = LocalVoiceAnalyzer()
    }
    
    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }
    
    // MARK: - Direct Audio Analysis Tests
    
    func testDirectAudioAnalysisWithValidAudio() async throws {
        // GWT: Given a test audio file with sustained vowel content
        // GWT: When performing direct audio analysis
        // GWT: Then should return meaningful F0 results
        
        let testAudioURL = try createTestSustainedVowelAudio()
        
        let result = try await analyzer.analyzeImmediate(audioURL: testAudioURL)
        
        // Should provide results even if speech recognition fails
        XCTAssertGreaterThan(result.f0Mean, 0, "Should detect some fundamental frequency")
        XCTAssertGreaterThanOrEqual(result.confidence, 0, "Confidence should be non-negative")
        XCTAssertEqual(result.analysisSource, .localIOS, "Should indicate local iOS analysis")
        
        // Clean up
        try? FileManager.default.removeItem(at: testAudioURL)
    }
    
    func testAnalysisWithEmptyAudio() async {
        // GWT: Given an empty or very quiet audio file
        // GWT: When performing analysis
        // GWT: Then should handle gracefully with low confidence
        
        do {
            let testAudioURL = try createSilentAudio()
            let result = try await analyzer.analyzeImmediate(audioURL: testAudioURL)
            
            // Should complete but with low confidence
            XCTAssertLessThan(result.confidence, 30, "Silent audio should have low confidence")
            
            // Clean up
            try? FileManager.default.removeItem(at: testAudioURL)
        } catch {
            // This is acceptable for silent audio
            XCTAssertTrue(error is LocalAnalysisError, "Should throw LocalAnalysisError for problematic audio")
        }
    }
    
    func testAnalysisWithNonExistentFile() async {
        // GWT: Given a non-existent audio file
        // GWT: When performing analysis
        // GWT: Then should throw appropriate error
        
        let nonExistentURL = URL(fileURLWithPath: "/tmp/non_existent_audio.wav")
        
        do {
            _ = try await analyzer.analyzeImmediate(audioURL: nonExistentURL)
            XCTFail("Should have thrown an error for non-existent file")
        } catch LocalAnalysisError.audioProcessingFailed {
            // Expected error
        } catch {
            XCTFail("Should have thrown LocalAnalysisError.audioProcessingFailed, got: \(error)")
        }
    }
    
    // MARK: - Audio Quality Validation Tests
    
    func testAudioQualityValidation() throws {
        // GWT: Given audio quality validation
        // GWT: When validating test audio
        // GWT: Then should provide quality assessment
        
        let testAudioURL = try createTestSustainedVowelAudio()
        
        let qualityResult = try analyzer.validateAudioQuality(audioURL: testAudioURL)
        
        XCTAssertTrue(qualityResult.isValid, "Test audio should pass quality validation")
        XCTAssertFalse(qualityResult.reason.isEmpty, "Should provide quality assessment reason")
        
        // Clean up
        try? FileManager.default.removeItem(at: testAudioURL)
    }
    
    // MARK: - Test Audio Generation Helpers
    
    private func createTestSustainedVowelAudio() throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_sustained_vowel_\(UUID().uuidString).wav")
        
        // Create a simple sustained vowel-like audio file
        let sampleRate = 44100.0
        let duration = 3.0 // 3 seconds
        let frequency = 220.0 // A3 note, good for female voice
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Generate a sine wave with some variation to simulate sustained vowel
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let amplitude = 0.3 * (1.0 + 0.1 * sin(2.0 * Double.pi * 5.0 * time)) // Add slight amplitude variation
            let phase = 2.0 * Double.pi * frequency * time + 0.05 * sin(2.0 * Double.pi * 10.0 * time) // Add slight frequency variation
            samples[i] = Float(amplitude * sin(phase))
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createSilentAudio() throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_silent_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let duration = 2.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create silent audio (all zeros)
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            samples[i] = 0.0
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    // MARK: - Integration Tests
    
    func testSustainedVowelAnalysisFlow() async throws {
        // GWT: Given a complete sustained vowel analysis flow
        // GWT: When user records and analyzes sustained vowel
        // GWT: Then should provide clinically relevant results
        
        let testAudioURL = try createTestSustainedVowelAudio()
        
        // Test the full flow
        let qualityResult = try analyzer.validateAudioQuality(audioURL: testAudioURL)
        XCTAssertTrue(qualityResult.isValid, "Audio should pass quality check")
        
        let analysisResult = try await analyzer.analyzeImmediate(audioURL: testAudioURL)
        
        // Verify results are clinically reasonable for female voice
        XCTAssertGreaterThan(analysisResult.f0Mean, 150, "F0 should be in reasonable range for female voice")
        XCTAssertLessThan(analysisResult.f0Mean, 350, "F0 should not be too high")
        XCTAssertGreaterThan(analysisResult.confidence, 20, "Should have reasonable confidence")
        
        // Test quality assessment
        let qualityLevel = analysisResult.qualityAssessment
        XCTAssertTrue([.excellent, .good, .moderate].contains(qualityLevel), 
                      "Should provide reasonable quality assessment")
        
        // Clean up
        try? FileManager.default.removeItem(at: testAudioURL)
    }
}