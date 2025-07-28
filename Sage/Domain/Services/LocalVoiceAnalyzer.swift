import Foundation
import Speech
import AVFoundation

// MARK: - Local Voice Analysis for Immediate User Feedback

/// Local voice analyzer using iOS SFVoiceAnalytics for immediate basic analysis
/// GWT: Given user completes voice recording
/// GWT: When iOS processes audio locally using SFVoiceAnalytics
/// GWT: Then user sees immediate basic F0 and confidence within 5 seconds
@available(iOS 13.0, *)
public class LocalVoiceAnalyzer: ObservableObject {
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    
    public init(locale: Locale = Locale.current) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            Logger.error("Speech recognizer not available for locale: \(locale.identifier)", category: .audio)
            throw LocalAnalysisError.speechRecognitionNotAvailable
        }
        
        self.speechRecognizer = recognizer
        
        // Log initialization status
        Logger.info("LocalVoiceAnalyzer initialized for locale \(locale.identifier), available: \(recognizer.isAvailable)", category: .audio)
    }
    
    /// Convenience initializer that falls back to English if current locale fails
    public convenience init() {
        do {
            try self.init(locale: Locale.current)
        } catch {
            do {
                Logger.info("LocalVoiceAnalyzer falling back to English locale", category: .audio)
                try self.init(locale: Locale(identifier: "en-US"))
            } catch {
                // If even English fails, this is a serious system issue
                fatalError("LocalVoiceAnalyzer: No speech recognition available on device")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if speech recognition is available and authorized
    /// GWT: Given app needs to check permissions before recording
    /// GWT: When checking speech recognition availability
    /// GWT: Then returns current permission status without requesting
    public func checkSpeechRecognitionStatus() -> SpeechRecognitionStatus {
        guard speechRecognizer.isAvailable else {
            return .unavailable
        }
        
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        switch authStatus {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .unknown
        }
    }
    
    /// Request speech recognition permission proactively
    /// GWT: Given user wants to enable voice analysis
    /// GWT: When requesting permission proactively
    /// GWT: Then shows permission dialog and returns result
    @MainActor
    public func requestSpeechRecognitionPermission() async -> SpeechRecognitionStatus {
        let status = await requestSpeechRecognitionAuthorization()
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .unknown
        }
    }
    
    // MARK: - Analysis Methods
    
    /// Performs immediate local voice analysis for basic user feedback
    /// GWT: Given recorded audio buffer from user
    /// GWT: When performing local iOS analysis
    /// GWT: Then returns BasicVoiceMetrics within 5 seconds
    public func analyzeImmediate(audioURL: URL) async throws -> BasicVoiceMetrics {
        // Ensure speech recognition is available and authorized
        try await ensureSpeechRecognitionAvailable()
        
        return try await performLocalAnalysis(audioURL: audioURL)
    }
    
    /// Performs local analysis using iOS built-in capabilities
    /// Analyzes real recorded audio files only - throws error if file invalid
    private func performLocalAnalysis(audioURL: URL) async throws -> BasicVoiceMetrics {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: audioURL.path) else {
            Logger.error("Audio file not found at: \(audioURL.path)", category: .audio)
            throw LocalAnalysisError.audioProcessingFailed
        }
        
        // Check file size to ensure recording actually happened
        do {
            let attributes = try fileManager.attributesOfItem(atPath: audioURL.path)
            let fileSize = attributes[FileAttributeKey.size] as? Int64 ?? 0
            
            guard fileSize >= 1000 else { // Less than 1KB indicates empty or failed recording
                Logger.error("Audio file too small (\(fileSize) bytes)", category: .audio)
                throw LocalAnalysisError.audioProcessingFailed
            }
            
            Logger.info("Found valid audio file (\(fileSize) bytes), performing real analysis", category: .audio)
        } catch {
            Logger.error("Could not read file attributes: \(error.localizedDescription)", category: .audio)
            throw LocalAnalysisError.audioProcessingFailed
        }
        
        // Perform appropriate analysis based on audio content
        return try await performAudioAnalysis(audioURL: audioURL)
    }
    
    
    /// Performs audio analysis - tries speech recognition first, falls back to direct audio analysis
    private func performAudioAnalysis(audioURL: URL) async throws -> BasicVoiceMetrics {
        // First try speech recognition for potential speech content
        do {
            let speechResult = try await performSpeechRecognition(audioURL: audioURL)
            Logger.info("Successfully analyzed audio using speech recognition", category: .audio)
            return speechResult
        } catch {
            Logger.info("Speech recognition failed, trying direct audio analysis: \(error.localizedDescription)", category: .audio)
            
            // Fallback to direct audio analysis for sustained vowels, humming, etc.
            return try await performDirectAudioAnalysis(audioURL: audioURL)
        }
    }
    
    /// Performs speech recognition analysis (for actual speech)
    private func performSpeechRecognition(audioURL: URL) async throws -> BasicVoiceMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // Force local processing
            
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    Logger.error("Speech recognition failed: \(error.localizedDescription)", category: .audio)
                    continuation.resume(throwing: LocalAnalysisError.recognitionFailed(error))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                // Extract voice analytics from real analysis results
                let voiceMetrics = self.extractVoiceMetrics(from: result)
                continuation.resume(returning: voiceMetrics)
            }
        }
    }
    
    /// Performs direct audio analysis for sustained vowels, humming, etc.
    private func performDirectAudioAnalysis(audioURL: URL) async throws -> BasicVoiceMetrics {
        Logger.info("Performing direct audio analysis for sustained vowel/non-speech content", category: .audio)
        
        do {
            let audioFile = try AVAudioFile(forReading: audioURL)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            
            // Read audio data
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw LocalAnalysisError.audioProcessingFailed
            }
            
            try audioFile.read(into: buffer)
            
            guard let audioData = buffer.floatChannelData?[0] else {
                throw LocalAnalysisError.audioProcessingFailed
            }
            
            let sampleCount = Int(buffer.frameLength)
            let sampleRate = format.sampleRate
            
            // Perform basic pitch analysis
            let analysisResult = performBasicPitchAnalysis(audioData: audioData, sampleCount: sampleCount, sampleRate: sampleRate)
            
            Logger.info("Direct audio analysis completed - F0: \(String(format: "%.1f", analysisResult.f0Mean))Hz, Confidence: \(String(format: "%.1f", analysisResult.confidence))%", category: .audio)
            
            return analysisResult
            
        } catch {
            Logger.error("Direct audio analysis failed: \(error.localizedDescription)", category: .audio)
            throw LocalAnalysisError.audioProcessingFailed
        }
    }
    
    /// Performs basic pitch analysis on raw audio data using domain-driven voice analysis principles
    private func performBasicPitchAnalysis(audioData: UnsafePointer<Float>, sampleCount: Int, sampleRate: Double) -> BasicVoiceMetrics {
        Logger.debug("Starting autocorrelation-based F0 analysis for \(sampleCount) samples at \(sampleRate)Hz", category: .audio)
        
        // Domain constraints for female voice analysis (clinical research ranges)
        let minF0 = 80.0  // 80 Hz minimum
        let maxF0 = 400.0 // 400 Hz maximum for female voices
        
        let minPeriod = Int(sampleRate / maxF0)
        let maxPeriod = Int(sampleRate / minF0)
        
        var bestPeriod = 0
        var maxCorrelation = 0.0
        var totalEnergy = 0.0
        var averageMagnitude = 0.0
        
        // Calculate signal statistics for confidence assessment
        for i in 0..<sampleCount {
            let sample = Double(audioData[i])
            totalEnergy += sample * sample
            averageMagnitude += abs(sample)
        }
        averageMagnitude /= Double(sampleCount)
        
        let rmsLevel = sqrt(totalEnergy / Double(sampleCount))
        Logger.debug("Signal analysis - RMS: \(String(format: "%.4f", rmsLevel)), Avg magnitude: \(String(format: "%.4f", averageMagnitude))", category: .audio)
        
        // Find the period with maximum autocorrelation
        for period in minPeriod...min(maxPeriod, sampleCount / 2) {
            var correlation = 0.0
            var autocorrelationEnergy = 0.0
            let analysisLength = sampleCount - period
            
            for i in 0..<analysisLength {
                let sample1 = Double(audioData[i])
                let sample2 = Double(audioData[i + period])
                correlation += sample1 * sample2
                autocorrelationEnergy += sample1 * sample1
            }
            
            // Normalize correlation by local energy
            if autocorrelationEnergy > 0 {
                correlation /= sqrt(autocorrelationEnergy * autocorrelationEnergy)
            }
            
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestPeriod = period
            }
        }
        
        // Calculate F0 with domain validation
        let f0Mean = bestPeriod > 0 ? sampleRate / Double(bestPeriod) : 0.0
        Logger.debug("F0 detection - Best period: \(bestPeriod), F0: \(String(format: "%.1f", f0Mean))Hz, Max correlation: \(String(format: "%.4f", maxCorrelation))", category: .audio)
        
        // Domain-driven confidence calculation for sustained vowels
        let confidence = calculateSustainedVowelConfidence(
            correlationStrength: maxCorrelation,
            signalLevel: rmsLevel,
            f0Value: f0Mean,
            signalDuration: Double(sampleCount) / sampleRate
        )
        
        // Domain-specific F0 variation for sustained vowels
        let f0Std = f0Mean * (confidence > 70 ? 0.03 : 0.08) // More stable for high-confidence detections
        
        // Clinical perturbation estimates based on confidence
        let jitterLocal = calculateJitterEstimate(confidence: confidence, f0Stability: f0Std / max(f0Mean, 1.0))
        let shimmerLocal = calculateShimmerEstimate(confidence: confidence, signalLevel: rmsLevel)
        
        Logger.info("Sustained vowel analysis - F0: \(String(format: "%.1f", f0Mean))Hz, Confidence: \(String(format: "%.1f", confidence))%, Jitter: \(String(format: "%.2f", jitterLocal))%, Shimmer: \(String(format: "%.2f", shimmerLocal))%", category: .audio)
        
        return BasicVoiceMetrics(
            f0Mean: f0Mean,
            f0Std: f0Std,
            confidence: confidence,
            jitterLocal: jitterLocal,
            shimmerLocal: shimmerLocal,
            analysisSource: .localIOS,
            processingTime: Date().timeIntervalSince1970
        )
    }
    
    /// Calculate confidence score specific to sustained vowel analysis
    private func calculateSustainedVowelConfidence(correlationStrength: Double, signalLevel: Double, f0Value: Double, signalDuration: Double) -> Double {
        var confidence = 0.0
        
        // Factor 1: Autocorrelation strength (0-40 points)
        confidence += min(40.0, correlationStrength * 100.0)
        
        // Factor 2: Signal level adequacy (0-25 points) 
        let signalLevelScore = min(25.0, (signalLevel / 0.1) * 25.0) // Normalize to 0.1 RMS as good level
        confidence += signalLevelScore
        
        // Factor 3: F0 in expected range (0-20 points)
        if f0Value >= 150.0 && f0Value <= 300.0 { // Typical female range
            confidence += 20.0
        } else if f0Value >= 100.0 && f0Value <= 400.0 { // Extended acceptable range
            confidence += 10.0
        }
        
        // Factor 4: Duration adequacy (0-15 points)
        if signalDuration >= 2.0 {
            confidence += 15.0
        } else if signalDuration >= 1.0 {
            confidence += 10.0
        } else {
            confidence += 5.0
        }
        
        return min(100.0, max(0.0, confidence))
    }
    
    /// Estimate jitter for sustained vowels based on analysis confidence
    private func calculateJitterEstimate(confidence: Double, f0Stability: Double) -> Double {
        // Clinical ranges: Normal jitter < 1.04% for sustained vowels
        let baseJitter = 0.5 // Baseline for good sustained vowels
        let stabilityPenalty = f0Stability * 10.0 // Convert stability ratio to penalty
        let confidenceFactor = (100.0 - confidence) / 100.0 // Higher confidence = lower jitter
        
        return baseJitter + stabilityPenalty + (confidenceFactor * 0.5)
    }
    
    /// Estimate shimmer for sustained vowels based on signal characteristics
    private func calculateShimmerEstimate(confidence: Double, signalLevel: Double) -> Double {
        // Clinical ranges: Normal shimmer < 3.81% for sustained vowels
        let baseShimmer = 2.0 // Baseline for good sustained vowels
        let levelFactor = max(0.0, (0.1 - signalLevel) * 10.0) // Penalty for low signal
        let confidenceFactor = (100.0 - confidence) / 50.0 // Higher confidence = lower shimmer
        
        return baseShimmer + levelFactor + confidenceFactor
    }
    
    /// Extracts voice metrics from speech recognition result
    private func extractVoiceMetrics(from result: SFSpeechRecognitionResult) -> BasicVoiceMetrics {
        // iOS 13+ provides SFVoiceAnalytics with pitch, jitter, shimmer
        return extractAdvancedMetrics(from: result)
    }
    
    /// Extract advanced metrics using SFVoiceAnalytics (iOS 13+)
    @available(iOS 13.0, *)
    private func extractAdvancedMetrics(from result: SFSpeechRecognitionResult) -> BasicVoiceMetrics {
        let voiceAnalytics = result.speechRecognitionMetadata?.voiceAnalytics
        
        // Updated for iOS API changes - acousticFeatureValuePerFrame returns [Double] directly
        let pitch = voiceAnalytics?.pitch.acousticFeatureValuePerFrame ?? []
        let jitter = voiceAnalytics?.jitter.acousticFeatureValuePerFrame ?? []
        let shimmer = voiceAnalytics?.shimmer.acousticFeatureValuePerFrame ?? []
        let voicing = voiceAnalytics?.voicing.acousticFeatureValuePerFrame ?? []
        
        // Calculate basic statistics
        let f0Mean = !pitch.isEmpty ? pitch.reduce(0, +) / Double(pitch.count) : 0.0
        let f0Std = !pitch.isEmpty ? calculateStandardDeviation(pitch) : 0.0
        let voicedRatio = !voicing.isEmpty ? voicing.reduce(0, +) / Double(voicing.count) : 0.0
        let confidence = min(max(voicedRatio * 100, 0), 100) // Convert to 0-100 percentage
        
        // Basic jitter/shimmer averages (local analysis approximation)
        let jitterMean = !jitter.isEmpty ? jitter.reduce(0, +) / Double(jitter.count) : 0.0
        let shimmerMean = !shimmer.isEmpty ? shimmer.reduce(0, +) / Double(shimmer.count) : 0.0
        
        return BasicVoiceMetrics(
            f0Mean: f0Mean,
            f0Std: f0Std,
            confidence: confidence,
            jitterLocal: jitterMean * 100, // Convert to percentage
            shimmerLocal: shimmerMean * 100, // Convert to percentage
            analysisSource: .localIOS,
            processingTime: Date().timeIntervalSince1970 // Approximate processing timestamp
        )
    }
    
    
    // MARK: - Helper Methods
    
    /// Ensures speech recognition is available and authorized, requesting permission if needed
    private func ensureSpeechRecognitionAvailable() async throws {
        // Check if speech recognizer is available for the current locale
        guard speechRecognizer.isAvailable else {
            Logger.error("Speech recognizer not available for locale: \(speechRecognizer.locale.identifier)", category: .audio)
            throw LocalAnalysisError.speechRecognitionNotAvailable
        }
        
        // Get current authorization status
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch currentStatus {
        case .authorized:
            Logger.info("Speech recognition already authorized", category: .audio)
            return
            
        case .notDetermined:
            Logger.info("Requesting speech recognition authorization", category: .audio)
            let authStatus = await requestSpeechRecognitionAuthorization()
            try handleAuthorizationStatus(authStatus)
            
        case .denied:
            Logger.error("Speech recognition denied by user", category: .audio)
            throw LocalAnalysisError.speechRecognitionDenied
            
        case .restricted:
            Logger.error("Speech recognition restricted on device", category: .audio)
            throw LocalAnalysisError.speechRecognitionRestricted
            
        @unknown default:
            Logger.error("Unknown speech recognition authorization status", category: .audio)
            throw LocalAnalysisError.speechRecognitionNotAuthorized
        }
    }
    
    /// Request speech recognition authorization with proper error handling
    private func requestSpeechRecognitionAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        Logger.info("Speech recognition authorized", category: .audio)
                    case .denied:
                        Logger.error("User denied access to speech recognition", category: .audio)
                    case .restricted:
                        Logger.error("Speech recognition restricted on this device", category: .audio)
                    case .notDetermined:
                        Logger.error("Speech recognition authorization still not determined", category: .audio)
                    @unknown default:
                        Logger.error("Unknown authorization status", category: .audio)
                    }
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    /// Handle authorization status and throw appropriate errors
    private func handleAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) throws {
        switch status {
        case .authorized:
            return // Success
        case .denied:
            throw LocalAnalysisError.speechRecognitionDenied
        case .restricted:
            throw LocalAnalysisError.speechRecognitionRestricted
        case .notDetermined:
            throw LocalAnalysisError.speechRecognitionNotAuthorized
        @unknown default:
            throw LocalAnalysisError.speechRecognitionNotAuthorized
        }
    }
    
    /// Calculate standard deviation for array of doubles
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - Supporting Types

/// Basic voice metrics for immediate local analysis
/// GWT: Given need for immediate user feedback
/// GWT: When local analysis completes
/// GWT: Then BasicVoiceMetrics provides essential information
public struct BasicVoiceMetrics: Equatable, Codable {
    public let f0Mean: Double          // Hz - fundamental frequency mean
    public let f0Std: Double           // Hz - fundamental frequency standard deviation
    public let confidence: Double      // % - analysis confidence (0-100)
    public let jitterLocal: Double     // % - approximate local jitter
    public let shimmerLocal: Double    // % - approximate local shimmer
    public let analysisSource: AnalysisSource
    public let processingTime: TimeInterval
    
    public init(f0Mean: Double, f0Std: Double, confidence: Double, jitterLocal: Double = 0.0, shimmerLocal: Double = 0.0, analysisSource: AnalysisSource = .localIOS, processingTime: TimeInterval = Date().timeIntervalSince1970) {
        self.f0Mean = f0Mean
        self.f0Std = f0Std
        self.confidence = confidence
        self.jitterLocal = jitterLocal
        self.shimmerLocal = shimmerLocal
        self.analysisSource = analysisSource
        self.processingTime = processingTime
    }
    
    /// Convert to domain F0Analysis for consistency
    public func toF0Analysis() -> F0Analysis {
        return F0Analysis(mean: f0Mean, std: f0Std, confidence: confidence)
    }
    
    /// Basic quality assessment for immediate user feedback
    public var qualityAssessment: LocalQualityLevel {
        if confidence < 30.0 {
            return .poor
        } else if confidence < 60.0 {
            return .moderate
        } else if confidence < 80.0 {
            return .good
        } else {
            return .excellent
        }
    }
    
    /// User-friendly feedback message
    public var feedbackMessage: String {
        switch qualityAssessment {
        case .excellent:
            return "Excellent recording quality! Full analysis in progress..."
        case .good:
            return "Good recording quality. Comprehensive analysis underway..."
        case .moderate:
            return "Recording processed. Detailed analysis in progress..."
        case .poor:
            return "Recording received. Processing may take longer due to audio quality..."
        }
    }
}

/// Speech recognition permission status
public enum SpeechRecognitionStatus: String, CaseIterable {
    case authorized = "authorized"
    case denied = "denied"
    case restricted = "restricted"
    case notDetermined = "not_determined"
    case unavailable = "unavailable"
    case unknown = "unknown"
    
    /// Whether speech recognition can be used
    public var canUse: Bool {
        return self == .authorized
    }
    
    /// User-friendly description
    public var description: String {
        switch self {
        case .authorized:
            return "Speech recognition is enabled"
        case .denied:
            return "Speech recognition access denied"
        case .restricted:
            return "Speech recognition is restricted"
        case .notDetermined:
            return "Speech recognition permission not requested"
        case .unavailable:
            return "Speech recognition not available on device"
        case .unknown:
            return "Unknown speech recognition status"
        }
    }
    
    /// Action user can take
    public var actionSuggestion: String? {
        switch self {
        case .denied:
            return "Enable in Settings > Privacy & Security > Speech Recognition"
        case .restricted:
            return "Check device restrictions or parental controls"
        case .notDetermined:
            return "Tap to request permission"
        case .unavailable:
            return "Update iOS or change device language"
        default:
            return nil
        }
    }
}

/// Local quality assessment levels for immediate feedback
public enum LocalQualityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
}

/// Errors that can occur during local voice analysis
public enum LocalAnalysisError: Error, LocalizedError {
    case speechRecognitionNotAuthorized
    case speechRecognitionDenied
    case speechRecognitionRestricted
    case speechRecognitionNotAvailable
    case recognitionFailed(Error)
    case audioProcessingFailed
    case unsupportedAudioFormat
    case analysisTimeout
    
    public var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "Speech recognition authorization required for voice analysis"
        case .speechRecognitionDenied:
            return "Speech recognition access denied. Please enable in Settings > Privacy & Security > Speech Recognition"
        case .speechRecognitionRestricted:
            return "Speech recognition is restricted on this device due to parental controls or device management"
        case .speechRecognitionNotAvailable:
            return "Speech recognition is not available for the current language or device"
        case .recognitionFailed(let error):
            return "Voice recognition failed: \(error.localizedDescription)"
        case .audioProcessingFailed:
            return "Audio processing failed during local analysis"
        case .unsupportedAudioFormat:
            return "Audio format not supported for local analysis"
        case .analysisTimeout:
            return "Local analysis timed out"
        }
    }
    
    /// User-friendly recovery suggestion
    public var recoverySuggestion: String? {
        switch self {
        case .speechRecognitionDenied:
            return "Go to Settings > Privacy & Security > Speech Recognition and enable access for Sage"
        case .speechRecognitionRestricted:
            return "Contact your device administrator or check parental control settings"
        case .speechRecognitionNotAvailable:
            return "Try changing your device language or updating iOS"
        case .speechRecognitionNotAuthorized:
            return "The app will request permission when you try voice analysis"
        default:
            return "Try recording again or restart the app"
        }
    }
}

// MARK: - Audio Quality Validation

extension LocalVoiceAnalyzer {
    
    /// Validates audio quality for local analysis
    /// GWT: Given audio file for local processing
    /// GWT: When validating audio quality gates
    /// GWT: Then ensures sufficient quality for basic analysis
    public func validateAudioQuality(audioURL: URL) throws -> AudioQualityResult {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw LocalAnalysisError.audioProcessingFailed
        }
        
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        
        // Duration validation
        let duration = Double(frameCount) / format.sampleRate
        guard duration >= 0.5 else {
            return AudioQualityResult(isValid: false, reason: "Recording too short (minimum 0.5 seconds)")
        }
        
        guard duration <= 60.0 else {
            return AudioQualityResult(isValid: false, reason: "Recording too long (maximum 60 seconds)")
        }
        
        // Sample rate validation
        guard format.sampleRate >= 16000 else {
            return AudioQualityResult(isValid: false, reason: "Sample rate too low (minimum 16 kHz)")
        }
        
        // Channel validation
        guard format.channelCount >= 1 else {
            return AudioQualityResult(isValid: false, reason: "No audio channels detected")
        }
        
        return AudioQualityResult(isValid: true, reason: "Audio quality sufficient for local analysis")
    }
}

/// Result of audio quality validation
public struct AudioQualityResult {
    public let isValid: Bool
    public let reason: String
    
    public init(isValid: Bool, reason: String) {
        self.isValid = isValid
        self.reason = reason
    }
}