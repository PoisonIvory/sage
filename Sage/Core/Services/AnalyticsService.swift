import Foundation
import Mixpanel
import UIKit // Added for UIDevice

/// Analytics events following MixPanel best practices
///
/// Event naming follows the pattern: [Object] [Action]
/// Properties include consistent context and user journey data.
///
/// - SeeAlso: `DATA_STANDARDS.md` §5.1 for analytics requirements
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §7.1 for analytics documentation standards
struct AnalyticsEvent {
    // MARK: - Onboarding Events
    static let onboardingStarted = "Onboarding Started"
    static let onboardingCompleted = "Onboarding Completed"
    static let signupMethodSelected = "Signup Method Selected"
    static let profileEnriched = "Profile Enriched"
    static let loginSelected = "Login Selected"
    static let signupSelected = "Signup Selected"
    
    // MARK: - Recording Events
    static let recordingStarted = "Recording Started"
    static let recordingStopped = "Recording Stopped"
    static let recordingUploaded = "Recording Uploaded"
    static let recordingFailed = "Recording Failed"
    
    // MARK: - Permission Events
    static let microphonePermissionGranted = "Microphone Permission Granted"
    static let microphonePermissionDenied = "Microphone Permission Denied"
    
    // MARK: - Session Events
    static let sessionStarted = "Session Started"
    static let sessionCompleted = "Session Completed"
    static let sessionSkipped = "Session Skipped"
    
    // MARK: - Feature Events
    static let featureExtracted = "Feature Extracted"
    static let validationFailed = "Validation Failed"
    static let userFeedbackSubmitted = "User Feedback Submitted"
    
    // MARK: - Error Events
    static let errorOccurred = "Error Occurred"
    static let networkError = "Network Error"
    static let authenticationError = "Authentication Error"
}

/// Standard analytics properties for consistent tracking
///
/// Provides type-safe property keys and common property values
/// to ensure consistency across all analytics events.
///
/// - SeeAlso: `DATA_STANDARDS.md` §5.1 for analytics requirements
struct AnalyticsProperties {
    // MARK: - Common Property Keys
    static let userId = "user_id"
    static let origin = "origin"
    static let step = "step"
    static let duration = "duration"
    static let source = "source"
    static let eventVersion = "event_version"
    static let errorMessage = "error_message"
    static let errorCode = "error_code"
    static let deviceModel = "device_model"
    static let osVersion = "os_version"
    static let appVersion = "app_version"
    static let timestamp = "timestamp"
    
    // MARK: - Onboarding Properties
    static let signupMethod = "signup_method"
    static let profileCompletionPercentage = "profile_completion_percentage"
    static let onboardingStep = "onboarding_step"
    
    // MARK: - Recording Properties
    static let recordingDuration = "recording_duration"
    static let recordingQuality = "recording_quality"
    static let fileSize = "file_size"
    static let taskType = "task_type"
    
    // MARK: - Session Properties
    static let sessionId = "session_id"
    static let sessionType = "session_type"
    static let cyclePhase = "cycle_phase"
    static let symptomMood = "symptom_mood"
}

final class AnalyticsService: AnalyticsServiceProtocol {
    static let shared = AnalyticsService()
    private init() {}

    /// Identifies a user in Mixpanel and sets their profile properties
    ///
    /// - Parameters:
    ///   - userId: Unique user identifier
    ///   - userProfile: User profile data to set
    /// - Returns: Void
    /// - SideEffects: Identifies user in Mixpanel and sets profile properties
    func identifyUser(userId: String, userProfile: UserProfile) {
        // Identify the user in Mixpanel
        Mixpanel.mainInstance().identify(distinctId: userId)
        
        // Set user profile properties
        Mixpanel.mainInstance().people.set([
            "$name": userProfile.id,
            "$email": userProfile.email ?? "",
            "age": userProfile.age,
            "gender": userProfile.gender,
            "device_model": userProfile.deviceModel,
            "os_version": userProfile.osVersion,
            "created_at": userProfile.createdAt,
            "signup_method": userProfile.signupMethod ?? "unknown"
        ])
        
        print("[Analytics] Identified user: \(userId)")
    }

    /// Tracks an analytics event with properties following MixPanel best practices
    ///
    /// - Parameters:
    ///   - name: Event name (should be descriptive and action-oriented)
    ///   - properties: Event properties (use AnalyticsProperties keys for consistency)
    ///   - origin: Source component that triggered the event
    /// - Returns: Void
    /// - SideEffects: Sends event to MixPanel with anonymized data
    /// - SeeAlso: `DATA_STANDARDS.md` §5.1 for analytics requirements
    func track(_ name: String, properties: [String: MixpanelType]? = nil, origin: String? = nil) {
        var eventProperties = properties ?? [:]
        
        // Add standard properties
        if let origin = origin {
            eventProperties[AnalyticsProperties.origin] = origin
        }
        
        // Add device context
        eventProperties[AnalyticsProperties.deviceModel] = UIDevice.current.model
        eventProperties[AnalyticsProperties.osVersion] = UIDevice.current.systemVersion
        eventProperties[AnalyticsProperties.appVersion] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        eventProperties[AnalyticsProperties.timestamp] = Date().timeIntervalSince1970
        
        // Privacy: Ensure no raw PII is sent
        if let userId = eventProperties[AnalyticsProperties.userId] as? String {
            eventProperties[AnalyticsProperties.userId] = AnalyticsService.anonymize(userId)
        }
        
        // Track the event
        Mixpanel.mainInstance().track(event: name, properties: eventProperties)
        print("[Analytics] Tracked event: \(name), properties: \(eventProperties)")
    }

    /// Tracks authentication events with standardized properties
    ///
    /// - Parameters:
    ///   - name: Authentication event name
    ///   - source: Source component that triggered the event
    ///   - authViewModel: AuthViewModel instance to get signup method
    /// - Returns: Void
    /// - SideEffects: Sends event to MixPanel with authentication context
    func trackAuthEvent(_ name: String, source: String, authViewModel: AuthViewModel) {
        track(name, properties: [
            AnalyticsProperties.signupMethod: authViewModel.signUpMethod ?? "unknown",
            AnalyticsProperties.source: source,
            AnalyticsProperties.eventVersion: 1
        ])
    }

    /// Anonymizes user identifiers for privacy compliance
    ///
    /// - Parameters:
    ///   - identifier: Raw user identifier to anonymize
    /// - Returns: Anonymized string identifier
    /// - SideEffects: None
    /// - SeeAlso: `DATA_STANDARDS.md` §6.1 for privacy requirements
    static func anonymize(_ identifier: String) -> String {
        // Simple hash for pseudonymization (not cryptographically secure)
        return String(identifier.hashValue)
    }
} 