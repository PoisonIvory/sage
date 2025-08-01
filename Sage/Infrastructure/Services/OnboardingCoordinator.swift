import Foundation

/// Coordinates onboarding flow completion and navigation
/// - Handles transition to main app after onboarding
/// - Provides clean interface for onboarding flow
/// - Follows GWT test specifications for flow completion
final class OnboardingCoordinator: OnboardingCoordinatorProtocol {
    
    private let navigationHandler: () -> Void
    private let analyticsService: AnalyticsServiceProtocol?
    
    /// Initializes coordinator with navigation handler and optional analytics
    /// - Parameters:
    ///   - navigationHandler: Closure to handle navigation to main app
    ///   - analyticsService: Optional analytics service for tracking completion
    init(navigationHandler: @escaping () -> Void, analyticsService: AnalyticsServiceProtocol? = nil) {
        self.navigationHandler = navigationHandler
        self.analyticsService = analyticsService
    }
    
    /// Called when onboarding is complete
    /// - Parameter userProfile: The completed user profile
    func onboardingDidComplete(userProfile: UserProfile) {
        print("[OnboardingCoordinator] Onboarding completed for user \(userProfile.id)")
        
        // Track onboarding completion if analytics service is available
        analyticsService?.track(
            "onboarding_completed",
            properties: [
                "user_id": userProfile.id,
                "signup_method": "onboarding_flow",
                "completion_time": Date().timeIntervalSince1970
            ],
            origin: "OnboardingCoordinator"
        )
        
        // Navigate to main app
        navigationHandler()
    }
} 