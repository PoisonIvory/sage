//
//  VoiceAnalysisApplicationService.swift
//  Sage
//
//  Application service for voice analysis operations following DDD principles
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation
import Combine
import Mixpanel

// MARK: - Application Service Protocol
protocol VoiceAnalysisApplicationServiceProtocol {
    func recordVoiceSample(promptId: String, duration: TimeInterval) async -> DomainResult<Recording>
    func analyzeVoiceSample(_ recording: Recording) async -> DomainResult<VocalBiomarkers>
    func getVoiceInsights(for userId: String) async -> DomainResult<[VocalBiomarkers]>
    func getLatestVoiceInsight(for userId: String) async -> DomainResult<VocalBiomarkers?>
    func deleteVoiceSample(_ recording: Recording) async -> DomainResult<Void>
    func validateRecording(_ recording: Recording) -> DomainResult<Recording>
}

// MARK: - Application Service Implementation
final class VoiceAnalysisApplicationService: VoiceAnalysisApplicationServiceProtocol {
    
    // MARK: - Dependencies
    private let audioRecorder: AudioRecordingManaging
    private let voiceAnalyzer: any VocalAnalysisService
    private let repository: VoiceAnalysisRepositoryProtocol
    private let validator: RecordingValidatorProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Initialization
    init(audioRecorder: AudioRecordingManaging = AudioRecorder.shared,
         voiceAnalyzer: any VocalAnalysisService,
         repository: VoiceAnalysisRepositoryProtocol = VoiceAnalysisRepository(),
         validator: RecordingValidatorProtocol = RecordingValidator(),
         analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.audioRecorder = audioRecorder
        self.voiceAnalyzer = voiceAnalyzer
        self.repository = repository
        self.validator = validator
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Methods
    func recordVoiceSample(promptId: String, duration: TimeInterval) async -> DomainResult<Recording> {
        Logger.debug("Starting voice sample recording for prompt: \(promptId)")
        
        // Validate prompt ID
        guard !promptId.isEmpty else {
            return .failure(VoiceAnalysisError.recordingFailed(reason: "Invalid prompt ID"))
        }
        
        // Check microphone permission
        let permissionResult = await checkMicrophonePermission()
        if permissionResult.isFailure {
            return .failure(VoiceAnalysisError.permissionDenied)
        }
        
        // Start recording
        let recordingResult = await startRecording(promptId: promptId, duration: duration)
        if recordingResult.isFailure {
            return recordingResult
        }
        
        guard let recording = recordingResult.value else {
            return .failure(VoiceAnalysisError.recordingFailed(reason: "No recording created"))
        }
        
        // Validate recording quality
        let validationResult = validateRecording(recording)
        if validationResult.isFailure {
            return validationResult.mapError { _ in VoiceAnalysisError.recordingFailed(reason: "Recording validation failed") }
        }
        
        // Save recording
        let saveResult = await repository.saveRecording(recording)
        if saveResult.isFailure {
            return saveResult
        }
        
        // Track analytics
        let properties: [String: MixpanelType] = [
            "prompt_id": promptId,
            "duration": duration,
            "recording_id": recording.id.uuidString
        ]
        analyticsService.track("voice_sample_recorded", properties: properties, origin: "VoiceAnalysisApplicationService")
        
        Logger.debug("Voice sample recording completed: \(recording.id)")
        return .success(recording)
    }
    
    func analyzeVoiceSample(_ recording: Recording) async -> DomainResult<VocalBiomarkers> {
        Logger.debug("Starting voice analysis for recording: \(recording.id)")
        
        // Validate recording exists
        let validationResult = validateRecording(recording)
        if validationResult.isFailure {
            return .failure(VoiceAnalysisError.analysisFailed(reason: "Invalid recording"))
        }
        
        // Perform analysis
        do {
            let voiceRecording = recording.toVoiceRecording()
            let analysisResult = try await voiceAnalyzer.analyzeVoice(recording: voiceRecording)
            
            // Extract biomarkers from the analysis result
            guard let biomarkers = analysisResult.comprehensiveAnalysis else {
                return .failure(VoiceAnalysisError.analysisFailed(reason: "No comprehensive analysis results"))
            }
            
            // Save analysis results
            let saveResult = await repository.saveAnalysisResult(biomarkers)
            if saveResult.isFailure {
                Logger.error("Failed to save analysis results for recording \(recording.id)")
                // Don't fail the operation if save fails
            }
            
            // Track analytics
            let properties: [String: MixpanelType] = [
                "recording_id": recording.id.uuidString,
                "f0_mean": biomarkers.f0.mean,
                "confidence": biomarkers.f0.confidence
            ]
            analyticsService.track("voice_analysis_completed", properties: properties, origin: "VoiceAnalysisApplicationService")
            
            Logger.debug("Voice analysis completed for recording: \(recording.id)")
            return .success(biomarkers)
            
        } catch {
            Logger.error("Voice analysis failed for recording \(recording.id): \(error.localizedDescription)")
            return .failure(VoiceAnalysisError.analysisFailed(reason: error.localizedDescription))
        }
    }
    
    func getVoiceInsights(for userId: String) async -> DomainResult<[VocalBiomarkers]> {
        Logger.debug("Fetching voice insights for user: \(userId)")
        
        guard !userId.isEmpty else {
            return .failure(VoiceAnalysisError.unknown)
        }
        
        let result = await repository.getAnalysisResults(for: userId)
        
        if result.isSuccess {
            let properties: [String: MixpanelType] = [
                "user_id": userId,
                "insight_count": Double(result.value?.count ?? 0)
            ]
            analyticsService.track("voice_insights_fetched", properties: properties, origin: "VoiceAnalysisApplicationService")
        }
        
        return result
    }
    
    func getLatestVoiceInsight(for userId: String) async -> DomainResult<VocalBiomarkers?> {
        Logger.debug("Fetching latest voice insight for user: \(userId)")
        
        guard !userId.isEmpty else {
            return .failure(VoiceAnalysisError.unknown)
        }
        
        let result = await repository.getLatestAnalysis(for: userId)
        
        if result.isSuccess, result.value != nil {
            let properties: [String: MixpanelType] = [
                "user_id": userId
            ]
            analyticsService.track("latest_voice_insight_fetched", properties: properties, origin: "VoiceAnalysisApplicationService")
        }
        
        return result
    }
    
    func deleteVoiceSample(_ recording: Recording) async -> DomainResult<Void> {
        Logger.debug("Deleting voice sample: \(recording.id)")
        
        let result = await repository.deleteRecording(recording)
        
        if result.isSuccess {
            let properties: [String: MixpanelType] = [
                "recording_id": recording.id.uuidString
            ]
            analyticsService.track("voice_sample_deleted", properties: properties, origin: "VoiceAnalysisApplicationService")
        }
        
        return result
    }
    
    func validateRecording(_ recording: Recording) -> DomainResult<Recording> {
        Logger.debug("Validating recording: \(recording.id)")
        
        let validationResult = validator.validateFull(recording: recording)
        
        if validationResult.isValid {
            return .success(recording)
        } else {
            return .failure(VoiceAnalysisError.validationFailed(reasons: validationResult.reasons))
        }
    }
    
    // MARK: - Private Methods
    private func checkMicrophonePermission() async -> DomainResult<Void> {
        // TODO: Implement microphone permission check
        return .success(())
    }
    
    private func startRecording(promptId: String, duration: TimeInterval) async -> DomainResult<Recording> {
        // TODO: Implement actual recording logic
        let recording = Recording(
            userID: "test_user",
            sessionTime: Date(),
            task: promptId,
            fileURL: URL(fileURLWithPath: "/path/to/recording.wav"),
            filename: "recording.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "iOS 15.0",
            appVersion: "1.0.0",
            duration: duration
        )
        return .success(recording)
    }
}

// MARK: - Service Protocols
// Use existing VocalAnalysisService protocol from HybridVocalAnalysisService.swift

protocol RecordingValidatorProtocol {
    func validateFull(recording: Recording) -> RecordingValidationResult
}

// AnalyticsServiceProtocol is already defined in OnboardingProtocols.swift

// RecordingValidationResult is already defined in RecordingValidator.swift 