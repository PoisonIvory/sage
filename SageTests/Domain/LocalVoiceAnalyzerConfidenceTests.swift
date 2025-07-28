import XCTest
import AVFoundation
@testable import Sage

/// Test-Driven Development for confidence calculation improvements
/// BDD: Given sustained vowel analysis, When calculating confidence, Then should provide meaningful scores
/// DDD: Focus on voice analysis domain logic for confidence scoring
@MainActor
final class LocalVoiceAnalyzerConfidenceTests: XCTestCase {
    
    var analyzer: LocalVoiceAnalyzer!
    
    override func setUp() {
        super.setUp()
        analyzer = LocalVoiceAnalyzer()
    }
    
    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }
    
    // MARK: - BDD: Confidence Scoring Behavior
    
    func testSustainedVowelShouldHaveReasonableConfidence() async throws {
        // Given a good quality sustained vowel recording
        let testAudioURL = try createHighQualitySustainedVowel()
        
        // When analyzing the sustained vowel
        let result = try await analyzer.analyzeImmediate(audioURL: testAudioURL)
        
        // Then confidence should be meaningful (not near zero)
        XCTAssertGreaterThan(result.confidence, 20.0, 
                           "High quality sustained vowel should have confidence > 20%")
        XCTAssertLessThan(result.confidence, 100.0, 
                         "Confidence should be realistic, not perfect")
        
        // And F0 should be in expected range for female voice
        XCTAssertGreaterThan(result.f0Mean, 150.0, "F0 should be in female range")
        XCTAssertLessThan(result.f0Mean, 300.0, "F0 should not be too high")
        
        // Clean up
        try? FileManager.default.removeItem(at: testAudioURL)
    }
    
    func testNoisyAudioShouldHaveLowerConfidence() async throws {
        // Given a noisy sustained vowel recording
        let testAudioURL = try createNoisySustainedVowel()
        
        // When analyzing the noisy audio
        let result = try await analyzer.analyzeImmediate(audioURL: testAudioURL)
        
        // Then confidence should be lower but not zero
        XCTAssertGreaterThan(result.confidence, 5.0, 
                           "Even noisy audio should have some confidence")
        XCTAssertLessThan(result.confidence, 50.0, 
                         "Noisy audio should have reduced confidence")
        
        // Clean up
        try? FileManager.default.removeItem(at: testAudioURL)
    }
    
    func testConfidenceCorrelatesWithSignalQuality() async throws {
        // Given multiple audio samples of different qualities
        let highQualityURL = try createHighQualitySustainedVowel()
        let mediumQualityURL = try createMediumQualitySustainedVowel()
        let lowQualityURL = try createNoisySustainedVowel()
        
        // When analyzing each sample
        let highResult = try await analyzer.analyzeImmediate(audioURL: highQualityURL)
        let mediumResult = try await analyzer.analyzeImmediate(audioURL: mediumQualityURL)
        let lowResult = try await analyzer.analyzeImmediate(audioURL: lowQualityURL)
        
        // Then confidence should correlate with quality
        XCTAssertGreaterThan(highResult.confidence, mediumResult.confidence,
                           "High quality should have higher confidence than medium")
        XCTAssertGreaterThan(mediumResult.confidence, lowResult.confidence,
                           "Medium quality should have higher confidence than low")
        
        // Clean up
        try? FileManager.default.removeItem(at: highQualityURL)
        try? FileManager.default.removeItem(at: mediumQualityURL)
        try? FileManager.default.removeItem(at: lowQualityURL)
    }
    
    // MARK: - DDD: Domain-Specific Test Audio Generation
    
    private func createHighQualitySustainedVowel() throws -> URL {
        return try createSustainedVowelAudio(
            frequency: 220.0,      // A3 - typical female speaking F0
            amplitude: 0.5,        // Good volume
            noiseLevel: 0.01,      // Very low noise
            duration: 3.0,         // Adequate length
            frequencyStability: 0.02 // Very stable pitch
        )
    }
    
    private func createMediumQualitySustainedVowel() throws -> URL {
        return try createSustainedVowelAudio(
            frequency: 200.0,      // Slightly lower
            amplitude: 0.3,        // Medium volume
            noiseLevel: 0.05,      // Some noise
            duration: 2.5,         // Shorter
            frequencyStability: 0.05 // Less stable
        )
    }
    
    private func createNoisySustainedVowel() throws -> URL {
        return try createSustainedVowelAudio(
            frequency: 180.0,      // Lower F0
            amplitude: 0.2,        // Quieter
            noiseLevel: 0.15,      // High noise
            duration: 2.0,         // Short
            frequencyStability: 0.1 // Unstable pitch
        )
    }
    
    private func createSustainedVowelAudio(
        frequency: Double,
        amplitude: Double,
        noiseLevel: Double,
        duration: Double,
        frequencyStability: Double
    ) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_vowel_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameValue(frameCount)
        
        let samples = buffer.floatChannelData![0]
        
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Add natural frequency variation
            let freqVariation = 1.0 + frequencyStability * sin(2.0 * Double.pi * 3.0 * time)
            let currentFreq = frequency * freqVariation
            
            // Add natural amplitude variation (breathing effect)
            let ampVariation = 1.0 + 0.1 * sin(2.0 * Double.pi * 1.5 * time)
            let currentAmp = amplitude * ampVariation
            
            // Generate sustained vowel signal
            let signal = currentAmp * sin(2.0 * Double.pi * currentFreq * time)
            
            // Add noise
            let noise = noiseLevel * (Float.random(in: -1.0...1.0))
            
            samples[i] = Float(signal) + noise
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
}