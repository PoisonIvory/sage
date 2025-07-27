import Foundation
import Mixpanel

// MARK: - Service Protocols

/// Protocol for analytics service
protocol AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?)
}

// AuthServiceProtocol is defined in AuthService.swift

/// Protocol for user profile repository
protocol UserProfileRepositoryProtocol {
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void)
}

/// Protocol for microphone permission management
protocol MicrophonePermissionManagerProtocol {
    func checkPermission(completion: @escaping (Bool) -> Void)
}

// AudioRecorderProtocol is defined in AudioRecorderProtocol.swift

/// Protocol for audio upload
protocol AudioUploaderProtocol {
    func uploadRecording(_ recording: Recording, mode: UploadMode, completion: @escaping (Result<Void, Error>) -> Void)
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