import Foundation
import Mixpanel

/// Protocol for analytics service to enable mocking and testing
/// - Provides abstraction for analytics tracking
/// - Enables consistent event tracking across the app
/// - Supports different analytics implementations
protocol AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?)
    func identifyUser(userId: String, userProfile: UserProfile)
}

// AuthServiceProtocol is defined in AuthService.swift
// MicrophonePermissionManagerProtocol is defined in MicrophonePermissionManager.swift
// AudioRecorderProtocol is defined in AudioRecorderProtocol.swift
// AudioUploaderProtocol is defined in AudioUploader.swift

/// Protocol for user profile repository
protocol UserProfileRepositoryProtocol {
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void)
}

// OnboardingCoordinatorProtocol is defined in OnboardingCoordinator.swift

// MARK: - Date Provider Protocol

// DateProvider is defined in OnboardingTypes.swift

// MARK: - Upload Mode

// UploadMode is defined in AudioUploader.swift

// MARK: - Microphone Permission Status
// Note: MicrophonePermissionStatus is now defined in VoicePermissionManager.swift

// MARK: - Recording UI State

// RecordingUIState is defined in AudioRecorderProtocol.swift

// MARK: - Upload Error

// UploadError is defined in AudioUploader.swift

// MARK: - Signup Method

// SignupMethod is defined in OnboardingTypes.swift 