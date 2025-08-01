import Foundation

/// Protocol for onboarding flow coordination (for testability)
protocol OnboardingCoordinatorProtocol: AnyObject {
    func onboardingDidComplete(userProfile: UserProfile)
} 