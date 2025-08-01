import XCTest
import AVFoundation
@testable import Sage

/// Tests for LocalVoiceAnalyzer quality gate functionality
/// GWT: Given need to validate audio quality before analysis
/// GWT: When quality gate checks signal level and audio properties
/// GWT: Then should reject insufficient signals and accept valid audio
@MainActor
final class LocalVoiceAnalyzerQualityGateTests: XCTestCase {
    
    var analyzer: LocalVoiceAnalyzer!
    
    override func setUp() {
        super.setUp()
        analyzer = LocalVoiceAnalyzer()
    }
    
    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }
    
    // MARK: - Quality Gate Signal Level Tests
    
    func testQualityGateRejectsSilentAudio() async throws {
        // Given: Silent audio file (all zeros)
        let silentAudioURL = try createSilentAudio()
        
        // When: Performing analysis with quality gate enabled
        do {
            _ = try await analyzer.analyzeImmediate(audioURL: silentAudioURL, bypassQualityCheck: false)
            XCTFail("Should have thrown insufficientSignalLevel error for silent audio")
        } catch LocalAnalysisError.insufficientSignalLevel(let rmsLevel, let required) {
            // Then: Should reject with appropriate error
            XCTAssertLessThan(rmsLevel, required, "RMS level should be below threshold")
            XCTAssertEqual(required, 0.01, "Required threshold should be 1% (0.01)")
            XCTAssertLessThan(rmsLevel, 0.001, "Silent audio RMS should be very low")
        } catch {
            XCTFail("Should have thrown insufficientSignalLevel, got: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: silentAudioURL)
    }
    
    func testQualityGateRejectsVeryQuietAudio() async throws {
        // Given: Very quiet audio file (0.5% amplitude)
        let quietAudioURL = try createQuietAudio(amplitude: 0.005)
        
        // When: Performing analysis with quality gate enabled
        do {
            _ = try await analyzer.analyzeImmediate(audioURL: quietAudioURL, bypassQualityCheck: false)
            XCTFail("Should have thrown insufficientSignalLevel error for quiet audio")
        } catch LocalAnalysisError.insufficientSignalLevel(let rmsLevel, let required) {
            // Then: Should reject with appropriate error
            XCTAssertLessThan(rmsLevel, required, "RMS level should be below threshold")
            XCTAssertGreaterThan(rmsLevel, 0.001, "Quiet audio should have some signal")
        } catch {
            XCTFail("Should have thrown insufficientSignalLevel, got: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: quietAudioURL)
    }
    
    func testQualityGateAcceptsGoodQualityAudio() async throws {
        // Given: Good quality audio file (5% amplitude)
        let goodAudioURL = try createGoodQualityAudio(amplitude: 0.05)
        
        // When: Performing analysis with quality gate enabled
        let result = try await analyzer.analyzeImmediate(audioURL: goodAudioURL, bypassQualityCheck: false)
        
        // Then: Should accept and provide meaningful results
        XCTAssertGreaterThan(result.f0Mean, 0, "Should detect fundamental frequency")
        XCTAssertGreaterThan(result.confidence, 20, "Should have reasonable confidence")
        XCTAssertEqual(result.analysisSource, .localIOS, "Should indicate local analysis")
        
        // Clean up
        try? FileManager.default.removeItem(at: goodAudioURL)
    }
    
    func testQualityGateBypassWorksForTesting() async throws {
        // Given: Silent audio file that would normally be rejected
        let silentAudioURL = try createSilentAudio()
        
        // When: Performing analysis with quality gate bypassed
        let result = try await analyzer.analyzeImmediate(audioURL: silentAudioURL, bypassQualityCheck: true)
        
        // Then: Should complete analysis despite poor signal quality
        XCTAssertEqual(result.analysisSource, .localIOS, "Should indicate local analysis")
        XCTAssertLessThan(result.confidence, 30, "Should have low confidence for silent audio")
        
        // Clean up
        try? FileManager.default.removeItem(at: silentAudioURL)
    }
    
    func testQualityGateAcceptsLowQualityAudioWithDegradedAnalysis() async throws {
        // GWT: Given audio with low but acceptable signal level
        // GWT: When validating audio quality
        // GWT: Then should accept with degraded quality warning
        
        do {
            let testAudioURL = try createLowQualityAudio()
            let qualityResult = analyzer.validateAudioQuality(audioURL: testAudioURL)
            
            // Should accept but with degraded quality
            XCTAssertTrue(qualityResult.isValid, "Low quality audio should be accepted")
            XCTAssertEqual(qualityResult.quality, .degraded, "Should indicate degraded quality")
            XCTAssertTrue(qualityResult.reason.contains("low but acceptable"), "Should indicate degraded analysis")
            
            // Clean up
            try? FileManager.default.removeItem(at: testAudioURL)
        } catch {
            XCTFail("Should handle low quality audio gracefully: \(error)")
        }
    }
    
    func testQualityGateRejectsVeryWeakAudio() async throws {
        // GWT: Given audio with very weak signal level
        // GWT: When validating audio quality
        // GWT: Then should reject with clear reason
        
        do {
            let testAudioURL = try createVeryWeakAudio()
            let qualityResult = analyzer.validateAudioQuality(audioURL: testAudioURL)
            
            // Should reject very weak audio
            XCTAssertFalse(qualityResult.isValid, "Very weak audio should be rejected")
            XCTAssertTrue(qualityResult.reason.contains("too low"), "Should indicate signal level issue")
            
            // Clean up
            try? FileManager.default.removeItem(at: testAudioURL)
        } catch {
            XCTFail("Should handle very weak audio gracefully: \(error)")
        }
    }
    
    // MARK: - Audio Quality Validation Tests
    
    func testAudioQualityValidationRejectsShortRecording() throws {
        // Given: Audio file that's too short
        let shortAudioURL = try createShortAudio(duration: 0.3)
        
        // When: Validating audio quality
        let qualityResult = try analyzer.validateAudioQuality(audioURL: shortAudioURL)
        
        // Then: Should reject with appropriate reason
        XCTAssertFalse(qualityResult.isValid, "Short recording should be invalid")
        XCTAssertTrue(qualityResult.reason.contains("too short"), "Should mention duration issue")
        
        // Clean up
        try? FileManager.default.removeItem(at: shortAudioURL)
    }
    
    func testAudioQualityValidationRejectsLongRecording() throws {
        // Given: Audio file that's too long
        let longAudioURL = try createLongAudio(duration: 70.0)
        
        // When: Validating audio quality
        let qualityResult = try analyzer.validateAudioQuality(audioURL: longAudioURL)
        
        // Then: Should reject with appropriate reason
        XCTAssertFalse(qualityResult.isValid, "Long recording should be invalid")
        XCTAssertTrue(qualityResult.reason.contains("too long"), "Should mention duration issue")
        
        // Clean up
        try? FileManager.default.removeItem(at: longAudioURL)
    }
    
    func testAudioQualityValidationAcceptsValidRecording() throws {
        // Given: Valid audio file with appropriate duration
        let validAudioURL = try createValidAudio(duration: 5.0)
        
        // When: Validating audio quality
        let qualityResult = try analyzer.validateAudioQuality(audioURL: validAudioURL)
        
        // Then: Should accept with appropriate reason
        XCTAssertTrue(qualityResult.isValid, "Valid recording should pass quality check")
        XCTAssertTrue(qualityResult.reason.contains("sufficient"), "Should indicate quality is sufficient")
        
        // Clean up
        try? FileManager.default.removeItem(at: validAudioURL)
    }
    
    // MARK: - Integration Tests
    
    func testQualityGateIntegrationWithAnalysisFlow() async throws {
        // Given: Valid audio file for complete analysis flow
        let validAudioURL = try createGoodQualityAudio(amplitude: 0.05)
        
        // When: Running complete analysis flow with quality gate
        let qualityResult = try analyzer.validateAudioQuality(audioURL: validAudioURL)
        XCTAssertTrue(qualityResult.isValid, "Audio should pass quality validation")
        
        let analysisResult = try await analyzer.analyzeImmediate(audioURL: validAudioURL, bypassQualityCheck: false)
        
        // Then: Should provide meaningful analysis results
        XCTAssertGreaterThan(analysisResult.f0Mean, 150, "F0 should be in reasonable range")
        XCTAssertLessThan(analysisResult.f0Mean, 350, "F0 should not be too high")
        XCTAssertGreaterThan(analysisResult.confidence, 20, "Should have reasonable confidence")
        
        // Clean up
        try? FileManager.default.removeItem(at: validAudioURL)
    }
    
    // MARK: - Test Audio Creation Helpers
    
    private func createSilentAudio() throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("silent_audio.wav")
        
        // Create silent audio file
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
        
        let frameCount = AVAudioFrameCount(44100 * 2) // 2 seconds
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        audioBuffer.frameLength = frameCount
        
        // Fill with very low amplitude noise
        let samples = audioBuffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            samples[i] = Float.random(in: -0.001...0.001) // Very quiet
        }
        
        try audioFile.write(from: audioBuffer)
        return tempURL
    }
    
    private func createQuietAudio(amplitude: Float) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_quiet_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let duration = 3.0
        let frequency = 220.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create quiet audio with specified amplitude
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let phase = 2.0 * Double.pi * frequency * time
            samples[i] = amplitude * sin(Float(phase))
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createGoodQualityAudio(amplitude: Float) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_good_quality_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let duration = 5.0
        let frequency = 220.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create good quality audio with specified amplitude
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let phase = 2.0 * Double.pi * frequency * time
            samples[i] = amplitude * sin(Float(phase))
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createShortAudio(duration: TimeInterval) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_short_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create short audio
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            samples[i] = 0.1 * sin(Float(i) * 0.1)
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createLongAudio(duration: TimeInterval) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_long_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create long audio
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            samples[i] = 0.1 * sin(Float(i) * 0.1)
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createValidAudio(duration: TimeInterval) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_valid_\(UUID().uuidString).wav")
        
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Create valid audio
        let samples = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            samples[i] = 0.1 * sin(Float(i) * 0.1)
        }
        
        try audioFile.write(from: buffer)
        return tempURL
    }
    
    private func createLowQualityAudio() throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("low_quality_audio.wav")
        
        // Create low quality audio file
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
        
        let frameCount = AVAudioFrameCount(44100 * 2) // 2 seconds
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        audioBuffer.frameLength = frameCount
        
        // Fill with low amplitude signal
        let samples = audioBuffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let frequency = 220.0 // A3 note
            let amplitude = 0.004 // Low amplitude
            samples[i] = Float(amplitude * sin(2.0 * Double.pi * frequency * Double(i) / 44100.0))
        }
        
        try audioFile.write(from: audioBuffer)
        return tempURL
    }
    
    private func createVeryWeakAudio() throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("very_weak_audio.wav")
        
        // Create very weak audio file
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
        
        let frameCount = AVAudioFrameCount(44100 * 2) // 2 seconds
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        audioBuffer.frameLength = frameCount
        
        // Fill with very weak signal
        let samples = audioBuffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let frequency = 220.0 // A3 note
            let amplitude = 0.001 // Very low amplitude
            samples[i] = Float(amplitude * sin(2.0 * Double.pi * frequency * Double(i) / 44100.0))
        }
        
        try audioFile.write(from: audioBuffer)
        return tempURL
    }
} 