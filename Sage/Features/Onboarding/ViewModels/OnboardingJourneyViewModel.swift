import Foundation
import SwiftUI
import Mixpanel

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
    @Published var isRecording: Bool = false {
        didSet {
            // Derive recordingState from isRecording to reduce duplication
            recordingState = isRecording ? .recording() : .idle()
        }
    }
    @Published var shouldShowNextButton: Bool = false
    
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
    private let audioRecorder: AudioRecorderProtocol
    private let audioUploader: AudioUploaderProtocol
    private weak var coordinator: OnboardingCoordinatorProtocol?
    private let dateProvider: DateProvider
    
    // MARK: - Private State
    private var currentRecording: Recording?
    
    // MARK: - Computed Properties
    var recordingState: RecordingUIState {
        // Derive from isRecording to eliminate state duplication
        return isRecording ? .recording() : .idle()
    }
    
    // MARK: - Initialization
    init(
        analyticsService: AnalyticsServiceProtocol,
        authService: AuthServiceProtocol,
        userProfileRepository: UserProfileRepositoryProtocol,
        microphonePermissionManager: MicrophonePermissionManagerProtocol,
        audioRecorder: AudioRecorderProtocol,
        audioUploader: AudioUploaderProtocol,
        coordinator: OnboardingCoordinatorProtocol?,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.analyticsService = analyticsService
        self.authService = authService
        self.userProfileRepository = userProfileRepository
        self.microphonePermissionManager = microphonePermissionManager
        self.audioRecorder = audioRecorder
        self.audioUploader = audioUploader
        self.coordinator = coordinator
        self.dateProvider = dateProvider
        Logger.info("[OnboardingJourneyViewModel] Initialized")
    }
    
    // MARK: - Signup Flow Methods
    
    /// Handles user selection of "Get Started"
    func selectGetStarted() {
        Logger.debug("[OnboardingJourneyViewModel] User selected Get Started")
        currentStep = .explainer
    }
    
    /// Handles user selection of anonymous signup
    func selectAnonymous() {
        Logger.debug("[OnboardingJourneyViewModel] User selected anonymous signup")
        clearFieldErrors() // Clear any previous errors
        selectedSignupMethod = .anonymous
        createMinimalUserProfile()
        trackSignupMethodSelected(method: "anonymous")
        trackOnboardingStarted()
        currentStep = .explainer
    }
    
    /// Handles user selection of email signup
    func selectEmail() {
        Logger.debug("[OnboardingJourneyViewModel] User selected email signup")
        clearFieldErrors() // Clear any previous errors
        selectedSignupMethod = .email
        createMinimalUserProfile()
        trackSignupMethodSelected(method: "email")
        trackOnboardingStarted()
        currentStep = .explainer
    }
    
    // MARK: - View 1: Explainer Methods
    
    /// Handles user tapping "Begin" button on explainer screen
    func selectBegin() {
        Logger.debug("[OnboardingJourneyViewModel] User tapped Begin button")
        currentStep = .vocalTest
    }
    
    // MARK: - View 2: Vocal Test Methods
    
    /// Called when vocal test view appears
    func onVocalTestViewAppear() {
        Logger.debug("[OnboardingJourneyViewModel] Vocal test view appeared")
        checkMicrophonePermission()
    }
    
    /// Called when vocal test view disappears
    func onVocalTestViewDisappear() {
        Logger.debug("[OnboardingJourneyViewModel] Vocal test view disappeared")
        cancelRecordingIfNeeded()
    }
    
    /// Starts the vocal test recording
    func startVocalTest() {
        Logger.debug("[OnboardingJourneyViewModel] Starting vocal test")
        
        // Check permission status first
        switch microphonePermissionStatus {
        case .granted:
            beginRecording()
        case .denied:
            Logger.error("[OnboardingJourneyViewModel] Microphone permission denied")
            errorMessage = "Microphone access is required. Enable it in Settings to continue."
        case .unknown:
            // Request permission first
            microphonePermissionManager.checkPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.microphonePermissionStatus = .granted
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
    func completeVocalTest() {
        Logger.debug("[OnboardingJourneyViewModel] Completing vocal test")
        isRecording = false
        
        if let recording = currentRecording {
            uploadRecording(recording)
        } else {
            Logger.error("[OnboardingJourneyViewModel] No recording found during completion")
        }
    }
    
    /// Handles vocal test upload result
    func handleVocalTestUploadResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            Logger.debug("[OnboardingJourneyViewModel] Upload completed successfully")
            successMessage = "Success! Let's move on to testing your pitch variation."
            shouldShowNextButton = true
            trackVocalTestCompleted()
            trackVocalTestUploaded(mode: .onboarding)
        case .failure(let error):
            Logger.error("[OnboardingJourneyViewModel] Upload failed: \(error.localizedDescription)")
            if let uploadError = error as? UploadError {
                errorMessage = uploadError.localizedDescription
            } else {
                errorMessage = "Upload failed. Please try again."
            }
        }
    }
    
    /// Handles user tapping "Next" after vocal test
    func selectNext() {
        Logger.debug("[OnboardingJourneyViewModel] User tapped Next")
        switch currentStep {
        case .vocalTest:
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
        currentStep = .completed
        if let profile = userProfile {
            coordinator?.onboardingDidComplete(userProfile: profile)
        } else {
            Logger.error("[OnboardingJourneyViewModel] No user profile found during completion")
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
            audioRecorder.stop()
            isRecording = false
            currentRecording = nil
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
            self.microphonePermissionStatus = granted ? .granted : .denied
            Logger.debug("[OnboardingJourneyViewModel] Microphone permission status: \(self.microphonePermissionStatus)")
        }
    }
    
    private func beginRecording() {
        Logger.debug("[OnboardingJourneyViewModel] Beginning recording")
        isRecording = true
        
        // Use the AudioRecorderProtocol for controlled recording
        audioRecorder.start(duration: testRecordingDuration) { [weak self] recording in
            guard let self = self else { return }
            Logger.debug("[OnboardingJourneyViewModel] Recording completed: \(recording.id)")
            self.currentRecording = recording
            self.completeVocalTest()
        }
    }
    
    private func uploadRecording(_ recording: Recording) {
        Logger.debug("[OnboardingJourneyViewModel] Uploading recording: \(recording.id)")
        audioUploader.uploadRecording(recording, mode: .onboarding) { [weak self] result in
            self?.handleVocalTestUploadResult(result)
        }
    }
    
    // MARK: - Analytics Methods
    
    private func trackSignupMethodSelected(method: String) {
        guard let userId = userProfile?.id else {
            Logger.error("[OnboardingJourneyViewModel] Missing user ID during signup method analytics")
            return
        }
        
        analyticsService.track(
            "onboarding_signup_method_selected",
            properties: [
                "method": method,
                "userID": userId
            ],
            origin: "OnboardingJourneyViewModel"
        )
    }
    
    private func trackOnboardingStarted() {
        guard let userId = userProfile?.id else {
            Logger.error("[OnboardingJourneyViewModel] Missing user ID during onboarding started analytics")
            return
        }
        
        analyticsService.track(
            "onboarding_started",
            properties: [
                "userID": userId,
                "signup_method": selectedSignupMethod?.rawValue ?? "unknown"
            ],
            origin: "OnboardingJourneyViewModel"
        )
    }
    
    private func trackVocalTestCompleted() {
        guard let userId = userProfile?.id else {
            Logger.error("[OnboardingJourneyViewModel] Missing user ID during vocal test completed analytics")
            return
        }
        
        analyticsService.track(
            "onboarding_vocal_test_completed",
            properties: [
                "duration": testRecordingDuration,
                "userID": userId,
                "mode": UploadMode.onboarding.rawValue
            ],
            origin: "OnboardingJourneyViewModel"
        )
    }
    
    private func trackVocalTestUploaded(mode: UploadMode) {
        // Guard against nil userProfile to prevent crashes
        guard let userId = userProfile?.id else {
            Logger.error("[OnboardingJourneyViewModel] Missing user ID during upload analytics")
            return
        }
        
        analyticsService.track(
            "onboarding_vocal_test_result_uploaded",
            properties: [
                "duration": testRecordingDuration,
                "userID": userId,
                "success": true,
                "mode": mode.rawValue
            ],
            origin: "OnboardingJourneyViewModel"
        )
    }
    
    private func trackProfileFinalized(profile: UserProfile) {
        analyticsService.track(
            "onboarding_profile_finalized",
            properties: [
                "age": profile.age,
                "gender": profile.gender,
                "userID": profile.id
            ],
            origin: "OnboardingJourneyViewModel"
        )
    }
    
    // MARK: - Computed Properties for UI Content
    
    var explainerHeadline: String {
        return "Let's run some quick tests"
    }
    
    var explainerSubtext: String {
        return "This helps us understand the unique physiology of your vocal tract."
    }
    
    var vocalTestInstruction: String {
        return "This test measures the rate and stability of vocal cord vibrations, both of which are affected by changes in hormones."
    }
    
    var vocalTestPrompt: String {
        return "Please say 'ahh' for \(Int(testRecordingDuration)) seconds."
    }
    
    var readingPromptHeading: String {
        return "Reading Prompt"
    }
    
    var finalStepMessage: String {
        return "Almost there! You're one step away from completing setup."
    }
    
    var beginButtonTitle: String {
        return "Begin"
    }
    
    var nextButtonTitle: String {
        return "Next"
    }
    
    var finishButtonTitle: String {
        return "Finish"
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

// MARK: - Logger for Production-Ready Logging

/// Simple logger that respects build configuration
/// - Debug builds: Full logging
/// - Release builds: No logging to reduce noise
struct Logger {
    static func debug(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
    
    static func error(_ message: String) {
        #if DEBUG
        print("❌ \(message)")
        #endif
    }
    
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }
} 