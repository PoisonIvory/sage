import Foundation
import Mixpanel

// MARK: - Service Protocols

/// Protocol for analytics service
protocol AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?)
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

/// Microphone permission status
enum MicrophonePermissionStatus {
    case unknown
    case granted
    case denied
}

// MARK: - Recording UI State

// RecordingUIState is defined in AudioRecorderProtocol.swift

// MARK: - Upload Error

// UploadError is defined in AudioUploader.swift

// MARK: - Signup Method

// SignupMethod is defined in OnboardingTypes.swift 