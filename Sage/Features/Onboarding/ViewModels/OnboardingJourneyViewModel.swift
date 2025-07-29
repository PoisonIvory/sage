import Foundation
import SwiftUI
import Mixpanel
import AVFoundation

/// ViewModel for the new GWT-compliant onboarding journey
/// - Implements all behavior specified in OnboardingJourneyTests.swift
/// - Uses dependency injection for testability
/// - Follows single responsibility principle with helper methods
@MainActor
final class OnboardingJourneyViewModel: ObservableObject {
    
    // MARK: - Constants
    private let testRecordingDuration: TimeInterval = 10.0
    
    // MARK: - Published State
    @Published var currentStep: OnboardingStep = .signupMethod
    @Published var selectedSignupMethod: SignupMethod?
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isRecording: Bool = false
    @Published var shouldShowNextButton: Bool = false
    @Published var hasCompletedRecording: Bool = false
    
    // MARK: - Permission State
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .unknown
    
    // MARK: - Form Data
    @Published var email: String = ""
    @Published var password: String = ""
    
    // MARK: - Field-Level Error State
    @Published var fieldErrors: [String: String] = [:]
    
    // MARK: - Dependencies
    private let analyticsService: AnalyticsServiceProtocol
    private let authService: AuthServiceProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let microphonePermissionManager: MicrophonePermissionManagerProtocol
    private let vocalAnalysisService: HybridVocalAnalysisService
    private let vocalBaselineService: VocalBaselineServiceProtocol
    private weak var coordinator: OnboardingCoordinatorProtocol?
    private let dateProvider: DateProvider
    
    // MARK: - Private State
    private var currentVoiceRecording: VoiceRecording?
    @Published var currentAnalysisResult: VocalAnalysisResult?
    private var audioRecorder: AVAudioRecorder?
    private var retryCount: Int = 0
    
    // MARK: - Recording State
    @Published var recordingState: RecordingUIState = .idle()
    
    // MARK: - Baseline State (AC-001, AC-002, AC-003)
    @Published var vocalBaseline: Sage.VocalBaseline?
    @Published var hasEstablishedBaseline: Bool = false
    @Published var baselineError: String?
    @Published var onboardingComplete: Bool = false
    @Published var hasComprehensiveAnalysis: Bool = false
    
    // MARK: - Initialization
    init(
        analyticsService: AnalyticsServiceProtocol,
        authService: AuthServiceProtocol,
        userProfileRepository: UserProfileRepositoryProtocol,
        microphonePermissionManager: MicrophonePermissionManagerProtocol,
        vocalAnalysisService: HybridVocalAnalysisService? = nil,
        vocalBaselineService: VocalBaselineServiceProtocol,
        coordinator: OnboardingCoordinatorProtocol?,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.analyticsService = analyticsService
        self.authService = authService
        self.userProfileRepository = userProfileRepository
        self.microphonePermissionManager = microphonePermissionManager
        self.vocalAnalysisService = vocalAnalysisService ?? HybridVocalAnalysisService()
        self.vocalBaselineService = vocalBaselineService
        self.coordinator = coordinator
        self.dateProvider = dateProvider
        Logger.info("[OnboardingJourneyViewModel] Initialized with domain services")
        
        // Start listening for comprehensive analysis results
        setupComprehensiveAnalysisListener()
    }
    
    // MARK: - Signup Flow Methods
    
    /// Handles user selection of "Get Started"
    func selectGetStarted() {
        Logger.debug("[OnboardingJourneyViewModel] User selected Get Started")
        currentStep = .explainer
    }
    
    /// Handles user selection of anonymous signup
    nonisolated func selectAnonymous() {
        Logger.debug("[OnboardingJourneyViewModel] User selected anonymous signup")
        Task { @MainActor in
            clearFieldErrors() // Clear any previous errors
            selectedSignupMethod = .anonymous
            createMinimalUserProfile()
            trackSignupMethodSelected(method: "anonymous")
            trackOnboardingStarted()
            currentStep = .explainer
        }
    }
    
    /// Handles user selection of email signup
    nonisolated func selectEmail() {
        Logger.debug("[OnboardingJourneyViewModel] User selected email signup")
        Task { @MainActor in
            clearFieldErrors() // Clear any previous errors
            selectedSignupMethod = .email
            createMinimalUserProfile()
            trackSignupMethodSelected(method: "email")
            trackOnboardingStarted()
            currentStep = .explainer
        }
    }
    
    // MARK: - View 1: Explainer Methods
    
    /// Handles user tapping "Begin" button on explainer screen
    func selectBegin() {
        Logger.debug("[OnboardingJourneyViewModel] User tapped Begin button")
        currentStep = .sustainedVowelTest
    }
    
    // MARK: - View 2: Vocal Test Methods
    
    /// Called when vocal test view appears
    func onSustainedVowelTestViewAppear() {
        Logger.debug("[OnboardingJourneyViewModel] Vocal test view appeared")
        // Reset state for fresh start
        shouldShowNextButton = false
        checkMicrophonePermission()
    }
    
    /// Called when vocal test view disappears
    func onSustainedVowelTestViewDisappear() {
        Logger.debug("[OnboardingJourneyViewModel] Vocal test view disappeared")
        cancelRecordingIfNeeded()
    }
    
    /// Starts the vocal test recording
    func startSustainedVowelTest() {
        Logger.debug("[OnboardingJourneyViewModel] Starting vocal test")
        
        // Prevent starting a new recording if one has already been completed
        guard !hasCompletedRecording else {
            Logger.debug("[OnboardingJourneyViewModel] Recording already completed, preventing new recording")
            return
        }
        
        // Check permission status first
        switch microphonePermissionStatus {
        case .authorized, .granted:
            beginRecording()
        case .denied:
            Logger.error("[OnboardingJourneyViewModel] Microphone permission denied")
            errorMessage = "Microphone access is required. Enable it in Settings to continue."
        case .restricted:
            Logger.error("[OnboardingJourneyViewModel] Microphone permission restricted")
            errorMessage = "Microphone access is restricted on this device."
        case .unknown, .notDetermined:
            // Request permission first
            microphonePermissionManager.checkPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.microphonePermissionStatus = .authorized
                    self.beginRecording()
                } else {
                    self.microphonePermissionStatus = .denied
                    Logger.error("[OnboardingJourneyViewModel] Microphone permission denied during request")
                    self.errorMessage = "Microphone access is required. Enable it in Settings to continue."
                }
            }
        }
    }
    
    /// Completes the vocal test recording
    func completeSustainedVowelTest() {
        Logger.debug("[OnboardingJourneyViewModel] User requested to complete vocal test")
        // Recording completion is handled automatically by the timer in beginRecording()
        // This method is called when user taps "Stop Recording" but we'll let the timer finish
    }
    
    
    /// Handles user tapping "Next" after vocal test
    func selectNext() {
        Logger.debug("[OnboardingJourneyViewModel] User tapped Next")
        switch currentStep {
        case .sustainedVowelTest:
            currentStep = .readingPrompt
        case .readingPrompt:
            currentStep = .finalStep
        default:
            break
        }
    }
    
    /// Handles user tapping "Finish" on final step
    func selectFinish() {
        Logger.debug("[OnboardingJourneyViewModel] User tapped Finish")
        
        Task {
            // Try to establish baseline if comprehensive analysis is ready
            if hasComprehensiveAnalysis && !hasEstablishedBaseline {
                do {
                    try await establishBaseline()
                    Logger.info("[OnboardingJourneyViewModel] Baseline established during onboarding completion")
                } catch {
                    Logger.warning("[OnboardingJourneyViewModel] Could not establish baseline during completion: \(error.localizedDescription)")
                    // Continue onboarding even if baseline fails - user can establish it later
                }
            } else if !hasComprehensiveAnalysis {
                Logger.info("[OnboardingJourneyViewModel] Comprehensive analysis not ready yet - onboarding will complete without baseline")
            }
            
            // Mark onboarding as completed in UserDefaults
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            Logger.debug("[OnboardingJourneyViewModel] Onboarding completion flag set in UserDefaults")
            
            await MainActor.run {
                currentStep = .completed
                if let profile = userProfile {
                    coordinator?.onboardingDidComplete(userProfile: profile)
                } else {
                    Logger.error("[OnboardingJourneyViewModel] No user profile found during completion")
                }
            }
        }
    }
    
    // MARK: - Error Handling Methods
    
    /// Clears all field-level errors
    /// - Called when user starts new actions or when errors are resolved
    func clearFieldErrors() {
        fieldErrors.removeAll()
        errorMessage = nil
    }
    
    /// Clears specific field error
    /// - Parameter fieldName: Name of the field to clear error for
    func clearFieldError(for fieldName: String) {
        fieldErrors.removeValue(forKey: fieldName)
    }
    
    // MARK: - Recording Cleanup Methods
    
    /// Cancels recording if currently in progress
    /// - Called when user navigates away from vocal test screen
    /// - Ensures proper cleanup of audio resources
    func cancelRecordingIfNeeded() {
        if isRecording {
            Logger.debug("[OnboardingJourneyViewModel] Cancelling recording due to navigation")
            vocalAnalysisService.stopListening()
            isRecording = false
            recordingState = .idle()
            currentVoiceRecording = nil
            currentAnalysisResult = nil
            hasComprehensiveAnalysis = false
        }
    }
    
    // MARK: - User Profile Creation Pipeline
    
    /// Creates a minimal user profile for initial signup
    /// - Used when user selects signup method (anonymous or email)
    /// - Contains only essential data (id, device info, creation date)
    /// - Age and gender are set to default values (0 and empty string)
    private func createMinimalUserProfile() {
        let userId = authService.currentUserId ?? UUID().uuidString
        userProfile = UserProfileValidator.createMinimalProfile(
            userId: userId,
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            dateProvider: dateProvider
        )
        
        // Identify user in analytics
        if let profile = userProfile {
            analyticsService.identifyUser(userId: userId, userProfile: profile)
        }
        
        Logger.debug("[OnboardingJourneyViewModel] Created minimal user profile for \(userId)")
    }
    
    /// Finalizes user profile with complete user data
    /// - Called when user provides age and gender information
    /// - Validates data before updating profile
    /// - Throws validation errors if data is invalid
    /// - Parameter data: Complete user profile data including age and gender
    /// - Throws: ValidationError if data is invalid
    func finalizeUserProfile(with data: UserProfileData) throws {
        Logger.debug("[OnboardingJourneyViewModel] Finalizing user profile with data: age=\(data.age), gender=\(data.gender)")
        
        // Clear previous field errors
        fieldErrors.removeAll()
        
        guard let currentProfile = userProfile else {
            Logger.error("[OnboardingJourneyViewModel] No minimal profile found for finalization")
            let error = ValidationError.ageRequired(fieldName: "profile")
            fieldErrors["profile"] = error.localizedDescription
            throw error
        }
        
        do {
            let finalizedProfile = try UserProfileValidator.createCompleteProfile(
                from: data,
                userId: currentProfile.id,
                deviceModel: currentProfile.deviceModel,
                osVersion: currentProfile.osVersion,
                dateProvider: dateProvider
            )
            
            userProfile = finalizedProfile
            Logger.debug("[OnboardingJourneyViewModel] User profile finalized successfully")
            
            // Update user identification in analytics with finalized profile
            analyticsService.identifyUser(userId: finalizedProfile.id, userProfile: finalizedProfile)
            
            // Track profile finalization analytics
            trackProfileFinalized(profile: finalizedProfile)
            
        } catch let validationError as ValidationError {
            // Handle field-level validation errors
            Logger.error("[OnboardingJourneyViewModel] Validation error during profile finalization: \(validationError.localizedDescription)")
            fieldErrors[validationError.fieldName] = validationError.localizedDescription
            throw validationError
        } catch {
            // Handle other errors
            Logger.error("[OnboardingJourneyViewModel] Unexpected error during profile finalization: \(error.localizedDescription)")
            fieldErrors["general"] = "Unable to save profile. Please try again."
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func checkMicrophonePermission() {
        Logger.debug("[OnboardingJourneyViewModel] Checking microphone permission")
        microphonePermissionManager.checkPermission { [weak self] granted in
            guard let self = self else { return }
            self.microphonePermissionStatus = granted ? .authorized : .denied
            Logger.debug("[OnboardingJourneyViewModel] Microphone permission status: \(self.microphonePermissionStatus)")
        }
    }
    
    private func beginRecording() {
        Logger.debug("[OnboardingJourneyViewModel] Beginning real audio recording")
        isRecording = true
        recordingState = .recording()
        
        Task {
            do {
                // Setup audio session for recording
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
                
                // Create recording URL
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("onboarding_recording_\(UUID().uuidString).wav")
                
                // Configure audio recorder settings
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false
                ]
                
                // Create and start audio recorder
                audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
                audioRecorder?.record()
                
                guard let userId = authService.currentUserId else {
                    throw VocalAnalysisError.userNotAuthenticated
                }
                
                // Create voice recording object
                let voiceRecording = VoiceRecording(
                    audioURL: tempURL,
                    duration: testRecordingDuration,
                    userId: userId
                )
                
                currentVoiceRecording = voiceRecording
                
                Logger.debug("[OnboardingJourneyViewModel] Started real audio recording to: \(tempURL.path)")
                
                // Stop recording after specified duration
                DispatchQueue.main.asyncAfter(deadline: .now() + testRecordingDuration) {
                    Task { @MainActor in
                        await self.stopRecordingAndAnalyze()
                    }
                }
                
            } catch {
                await MainActor.run {
                    Logger.error("[OnboardingJourneyViewModel] Failed to start recording: \(error.localizedDescription)")
                    errorMessage = "Failed to start recording: \(error.localizedDescription)"
                    isRecording = false
                    recordingState = .idle()
                }
            }
        }
    }
    
    @MainActor
    private func stopRecordingAndAnalyze() async {
        Logger.debug("[OnboardingJourneyViewModel] Stopping recording and starting analysis")
        
        // Stop the audio recorder
        audioRecorder?.stop()
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            Logger.error("[OnboardingJourneyViewModel] Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        guard let voiceRecording = currentVoiceRecording else {
            Logger.error("[OnboardingJourneyViewModel] No voice recording found")
            errorMessage = "Recording not found. Please try again."
            return
        }
        
        // Verify the audio file was created
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: voiceRecording.audioURL.path) {
            Logger.error("[OnboardingJourneyViewModel] Audio file was not created")
            errorMessage = "Recording failed. Please try again."
            isRecording = false
            recordingState = .idle()
            return
        }
        
        Logger.debug("[OnboardingJourneyViewModel] Audio file created successfully, starting analysis")
        
        do {
            // Perform hybrid analysis (local immediate + cloud comprehensive)  
            let result = try await vocalAnalysisService.analyzeVoice(recording: voiceRecording)
            
            currentAnalysisResult = result
            handleVocalAnalysisSuccess(result)
            
        } catch {
            Logger.error("[OnboardingJourneyViewModel] Vocal analysis failed: \(error.localizedDescription)")
            errorMessage = "Voice analysis failed: \(error.localizedDescription)"
            isRecording = false
            recordingState = .idle()
        }
    }
    
    
    private func handleVocalAnalysisSuccess(_ result: VocalAnalysisResult) {
        Logger.debug("[OnboardingJourneyViewModel] Voice analysis completed successfully")
        
        // Update UI with immediate local results
        let f0Mean = result.localMetrics.f0Mean
        let confidence = result.localMetrics.confidence
        
        successMessage = "Recording complete! F0: \(String(format: "%.1f", f0Mean))Hz (\(Int(confidence))% confidence)"
        shouldShowNextButton = true
        hasCompletedRecording = true
        isRecording = false
        recordingState = .idle()
        
        // Check if comprehensive analysis is already available
        hasComprehensiveAnalysis = result.comprehensiveAnalysis != nil
        
        // Track analytics
        trackSustainedVowelTestCompleted()
        trackVocalAnalysisCompleted(result: result)
    }
    
    // MARK: - Comprehensive Analysis Listener
    
    /// Sets up listener for comprehensive analysis results from cloud
    private func setupComprehensiveAnalysisListener() {
        Task {
            for await biomarkers in vocalAnalysisService.subscribeToResults() {
                await MainActor.run {
                    Logger.debug("[OnboardingJourneyViewModel] Received comprehensive analysis results")
                    
                    // Update current analysis result with comprehensive data
                    if let currentResult = currentAnalysisResult {
                        currentAnalysisResult = VocalAnalysisResult(
                            recordingId: currentResult.recordingId,
                            localMetrics: currentResult.localMetrics,
                            comprehensiveAnalysis: biomarkers,
                            status: .complete
                        )
                    }
                    
                    hasComprehensiveAnalysis = true
                    
                    // Update success message to indicate comprehensive analysis is ready
                    let f0Mean = biomarkers.f0.mean
                    let confidence = biomarkers.f0.confidence
                    successMessage = "Comprehensive analysis complete! F0: \(String(format: "%.1f", f0Mean))Hz (\(Int(confidence))% confidence)"
                    
                    Logger.info("[OnboardingJourneyViewModel] Comprehensive analysis complete - ready for baseline establishment")
                }
            }
        }
    }
    
    // MARK: - Baseline Establishment Methods (AC-001, AC-002, AC-003)
    
    /// Establishes vocal baseline from current analysis result using domain service
    func establishBaseline() async throws {
        Logger.debug("[OnboardingJourneyViewModel] Establishing vocal baseline using domain service")
        
        guard let analysisResult = currentAnalysisResult else {
            let error = "No analysis result available for baseline establishment"
            baselineError = error
            Logger.error("[OnboardingJourneyViewModel] \(error)")
            throw VocalAnalysisError.noAnalysisResult
        }
        
        guard let userId = authService.currentUserId else {
            let error = "User authentication required for baseline"
            baselineError = error
            Logger.error("[OnboardingJourneyViewModel] \(error)")
            throw VocalAnalysisError.userNotAuthenticated
        }
        
        // Get user profile for demographic data
        guard let userProfile = userProfile else {
            let error = "User profile required for baseline establishment"
            baselineError = error
            Logger.error("[OnboardingJourneyViewModel] \(error)")
            throw VocalBaselineError.userProfileNotFound
        }
        
        do {
            // Use domain service to establish baseline with real data
            let baseline = try await vocalBaselineService.establishBaseline(
                from: analysisResult,
                userId: UUID(uuidString: userId) ?? UUID(),
                userProfile: userProfile
            )
            
            // Update UI state
            vocalBaseline = baseline
            hasEstablishedBaseline = true
            baselineError = nil
            
            Logger.info("[OnboardingJourneyViewModel] Vocal baseline established successfully using domain service")
            
            // Track analytics with real baseline data
            trackAnalyticsEvent("onboarding_baseline_established", properties: [
                "f0_mean": baseline.biomarkers.f0.mean,
                "f0_confidence": baseline.biomarkers.f0.confidence,
                "clinical_quality": baseline.clinicalQuality.rawValue,
                "stability_score": baseline.biomarkers.stability.score,
                "demographic": baseline.demographic.rawValue,
                "voiced_ratio": baseline.biomarkers.metadata.voicedRatio,
                "recording_duration": baseline.biomarkers.metadata.recordingDuration
            ])
            
        } catch let baselineError as VocalBaselineError {
            // Handle domain-specific errors with contextual guidance
            let contextualGuidance = getErrorGuidance(for: baselineError)
            self.baselineError = baselineError.localizedDescription + (contextualGuidance.isEmpty ? "" : " " + contextualGuidance)
            Logger.error("[OnboardingJourneyViewModel] Baseline establishment failed: \(baselineError.localizedDescription)")
            
            // Track analytics for failure with reason
            trackAnalyticsEvent("onboarding_baseline_failed", properties: [
                "reason": baselineError.localizedDescription,
                "error_type": String(describing: baselineError)
            ])
            throw baselineError
        } catch {
            // Handle other errors
            self.baselineError = "Baseline establishment failed: \(error.localizedDescription)"
            Logger.error("[OnboardingJourneyViewModel] Unexpected error during baseline establishment: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Re-records baseline during onboarding (AC-003)
    func reRecordBaseline() async {
        Logger.debug("[OnboardingJourneyViewModel] User requested to re-record baseline")
        
        // Reset state for new recording
        hasCompletedRecording = false
        shouldShowNextButton = false
        currentAnalysisResult = nil
        baselineError = nil
        successMessage = nil
        hasComprehensiveAnalysis = false
        
        // Track analytics
        trackAnalyticsEvent("onboarding_baseline_re_record_requested", properties: [:])
    }
    
    /// Completes onboarding with established baseline
    func completeOnboarding() async {
        // Update completion tracking
        onboardingComplete = true
        
        // Track analytics with baseline context
        let properties: [String: Any] = [
            "has_baseline": hasEstablishedBaseline,
            "baseline_quality": vocalBaseline?.clinicalQuality.rawValue ?? "none"
        ]
        
        trackAnalyticsEvent("onboarding_completed_with_baseline", properties: properties)
        
        Logger.info("[OnboardingJourneyViewModel] Onboarding completed with baseline: \(hasEstablishedBaseline)")
    }
    
    // MARK: - Analytics Methods
    
    /// Centralized analytics tracking with user ID validation
    /// - Parameter eventName: Name of the analytics event
    /// - Parameter properties: Event properties to track
    private func trackAnalyticsEvent(_ eventName: String, properties: [String: Any]) {
        guard let userId = userProfile?.id else {
            Logger.error("[OnboardingJourneyViewModel] Missing user ID during \(eventName) analytics")
            return
        }
        
        var eventProperties = properties
        eventProperties["userID"] = userId
        
        // Convert to MixpanelType for analytics service
        let mixpanelProperties = eventProperties.mapValues { value in
            return value as? MixpanelType ?? String(describing: value)
        }
        
        analyticsService.track(eventName, properties: mixpanelProperties, origin: "OnboardingJourneyViewModel")
    }
    
    private func trackSignupMethodSelected(method: String) {
        trackAnalyticsEvent("onboarding_signup_method_selected", properties: ["method": method])
    }
    
    private func trackOnboardingStarted() {
        trackAnalyticsEvent("onboarding_started", properties: [
            "signup_method": selectedSignupMethod?.rawValue ?? "unknown"
        ])
    }
    
    private func trackSustainedVowelTestCompleted() {
        trackAnalyticsEvent("onboarding_vocal_test_completed", properties: [
            "duration": testRecordingDuration,
            "mode": UploadMode.onboarding.rawValue
        ])
    }
    
    private func trackVocalAnalysisCompleted(result: VocalAnalysisResult) {
        trackAnalyticsEvent("onboarding_vocal_analysis_completed", properties: [
            "duration": testRecordingDuration,
            "f0_mean": result.localMetrics.f0Mean,
            "confidence": result.localMetrics.confidence,
            "status": result.status.rawValue
        ])
    }
    
    private func trackProfileFinalized(profile: UserProfile) {
        trackAnalyticsEvent("onboarding_profile_finalized", properties: [
            "age": profile.age,
            "gender": profile.gender
        ])
    }
    
    /// Provides contextual guidance based on the specific baseline error
    /// - Parameter error: The baseline error that occurred
    /// - Returns: User-friendly guidance string, or empty if no specific guidance available
    private func getErrorGuidance(for error: VocalBaselineError) -> String {
        switch error {
        case .clinicalValidationFailed(let reason):
            if reason.contains("F0 confidence") || reason.contains("confidence") {
                return "Try recording in a quieter room and speak more clearly."
            } else if reason.contains("duration") || reason.contains("short") {
                return "Please speak for the full duration when recording."
            } else if reason.contains("voiced") {
                return "Make sure to speak continuously without long pauses."
            }
            return "Please try recording again with better audio quality."
        case .userProfileNotFound:
            return "Please complete your profile setup first."
        case .incompleteAnalysis:
            return "Please complete the voice recording first."
        default:
            return ""
        }
    }
    
    // MARK: - Computed Properties for UI Content
    
    /// Centralized UI strings for onboarding flow
    private struct OnboardingStrings {
        static let explainerHeadline = "Let's run some quick tests"
        static let explainerSubtext = "This helps us understand the unique physiology of your vocal tract."
        static let sustainedVowelTestInstruction = "This test measures the rate and stability of vocal cord vibrations, both of which are affected by changes in hormones."
        static let readingPromptHeading = "Reading Prompt"
        static let finalStepMessage = "Almost there! You're one step away from completing setup."
        static let beginButtonTitle = "Begin"
        static let nextButtonTitle = "Next"
        static let finishButtonTitle = "Finish"
    }
    
    var explainerHeadline: String {
        return OnboardingStrings.explainerHeadline
    }
    
    var explainerSubtext: String {
        return OnboardingStrings.explainerSubtext
    }
    
    var sustainedVowelTestInstruction: String {
        return OnboardingStrings.sustainedVowelTestInstruction
    }
    
    var sustainedVowelTestPrompt: String {
        return "Please say 'ahh' for \(Int(testRecordingDuration)) seconds."
    }
    
    var readingPromptHeading: String {
        return OnboardingStrings.readingPromptHeading
    }
    
    var finalStepMessage: String {
        if hasComprehensiveAnalysis {
            return "Perfect! Your voice analysis is complete. Finish setup to establish your baseline."
        } else {
            return OnboardingStrings.finalStepMessage
        }
    }
    
    var beginButtonTitle: String {
        return OnboardingStrings.beginButtonTitle
    }
    
    var nextButtonTitle: String {
        return OnboardingStrings.nextButtonTitle
    }
    
    var finishButtonTitle: String {
        return OnboardingStrings.finishButtonTitle
    }
    
    /// Returns a formatted baseline summary for UI display
    /// - Returns: Formatted string with baseline metrics and explanation
    func getBaselineSummary() -> String {
        guard let baseline = vocalBaseline else {
            return "No baseline established"
        }
        let f0Mean = baseline.biomarkers.f0.mean
        let confidence = baseline.biomarkers.f0.confidence
        let quality = baseline.clinicalQuality.rawValue
        let explanation = "Your vocal baseline captures your unique voice characteristics during onboarding. This establishes your personal reference point for future voice analysis."
        return "F0: \(String(format: "%.1f", f0Mean))Hz, Confidence: \(Int(confidence))%, Quality: \(quality)\n\n\(explanation)"
    }
}

// MARK: - UploadMode Raw Value
extension UploadMode {
    var rawValue: String {
        switch self {
        case .onboarding:
            return "onboarding"
        case .daily:
            return "daily"
        case .debugTest:
            return "debug_test"
        }
    }
}

 