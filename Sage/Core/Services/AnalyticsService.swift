import Foundation
import Mixpanel

struct AnalyticsEvent {
    static let onboardingStarted = "onboarding_started"
    static let onboardingComplete = "onboarding_complete"
    static let microphonePermissionGranted = "microphone_permission_granted"
    static let microphonePermissionDenied = "microphone_permission_denied"
    static let recordingStarted = "recording_started"
    static let recordingStopped = "recording_stopped"
    static let recordingUploaded = "recording_uploaded"
    static let validationFailed = "validation_failed"
    static let sessionSkipped = "session_skipped"
    static let sessionCompleted = "session_completed"
    static let featureExtracted = "feature_extracted"
    static let userFeedbackSubmitted = "user_feedback_submitted"
    // Add more events as needed, following snake_case and entity prefix
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func track(_ name: String, properties: [String: MixpanelType]? = nil, origin: String? = nil) {
        var eventProperties = properties ?? [:]
        if let origin = origin {
            eventProperties["origin"] = origin
        }
        // Privacy: Ensure no raw PII is sent
        if let userId = eventProperties["user_id"] as? String {
            eventProperties["user_id"] = AnalyticsService.anonymize(userId)
        }
        Mixpanel.mainInstance().track(event: name, properties: eventProperties)
        print("[Analytics] Tracked event: \(name), properties: \(eventProperties)")
    }

    static func anonymize(_ identifier: String) -> String {
        // Simple hash for pseudonymization (not cryptographically secure)
        return String(identifier.hashValue)
    }
} 