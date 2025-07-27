import SwiftUI
import Combine
import FirebaseAuth
import Mixpanel

/// OnboardingFlowView manages the complete onboarding flow for new users
///
/// Displays different onboarding steps based on the current state and handles
/// navigation between steps. Integrates with analytics and user profile services.
///
/// - SeeAlso: `DATA_STANDARDS.md` §2.2 for onboarding flow requirements
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §2.1 for ViewModel documentation standards
struct OnboardingFlowView: View {
    @StateObject private var viewModel: OnboardingFlowViewModel
    
    /// Initializes the onboarding flow with required dependencies
    ///
    /// - Parameters:
    ///   - coordinator: Handles onboarding completion and navigation
    ///   - userProfileRepository: Manages user profile data persistence
    ///   - analyticsService: Tracks onboarding events and user behavior
    ///   - authService: Provides current user authentication state
    /// - Returns: OnboardingFlowView instance
    /// - SideEffects: Initializes ViewModel with injected dependencies
    /// - SeeAlso: `DATA_STANDARDS.md` §2.3 for user profile requirements
    init(
        coordinator: OnboardingFlowCoordinating? = nil,
        userProfileRepository: UserProfileRepositoryProtocol = UserProfileRepository(),
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared,
        authService: AuthServiceProtocol = AuthService()
    ) {
        self._viewModel = StateObject(wrappedValue: OnboardingFlowViewModel(
            coordinator: coordinator,
            userProfileRepository: userProfileRepository,
            analyticsService: analyticsService,
            authService: authService
        ))
    }

    var body: some View {
        VStack {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeView(
                    onBegin: { 
                        viewModel.currentStep = .loginSignupChoice
                    }
                )
            case .loginSignupChoice:
                LoginSignupChoiceView(
                    onLogin: { viewModel.selectIAlreadyHaveAccount() },
                    onSignup: { viewModel.selectGetStarted() }
                )
            case .signupMethod:
                SignupMethodView(
                    onAnonymous: { viewModel.selectAnonymous() },
                    onEmail: { viewModel.selectEmail() }
                )
            case .userProfileCreation:
                UserInfoFormView(
                    isAnonymous: viewModel.isAnonymous,
                    userInfo: $viewModel.userInfo,
                    onComplete: { viewModel.completeUserInfo() }
                )
            case .userInfoForm:
                UserInfoFormView(
                    isAnonymous: viewModel.isAnonymous,
                    userInfo: $viewModel.userInfo,
                    onComplete: { viewModel.completeUserInfo() }
                )
            case .completed:
                Text("Onboarding Complete! Navigating to Home...")
            }
        }
        .padding()
        .onAppear {
            print("OnboardingFlowView: appeared")
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
            print("OnboardingFlowView: step changed to \(newStep)") // UI_STANDARDS.md §5.2
            if newStep == .completed {
                AnalyticsService.shared.track(
                    AnalyticsEvent.onboardingCompleted,
                    properties: [
                        AnalyticsProperties.source: "OnboardingFlowView",
                        AnalyticsProperties.eventVersion: 1
                        // Optionally add duration if available
                    ],
                    origin: "OnboardingFlowView"
                )
            }
        }
    }
}

/// Mock AuthService for dependency injection
/// 
/// Provides current user authentication state for the onboarding flow.
/// In a real implementation, this would integrate with Firebase Auth.
///
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §4.1 for mock documentation standards
class AuthService: AuthServiceProtocol {
    var currentUserId: String? {
        // In a real implementation, this would return Firebase Auth current user ID
        return Auth.auth().currentUser?.uid
    }
}



struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView()
    }
}

// MARK: - Test Helper
/// Test helper to verify OnboardingFlowView compilation
/// 
/// This extension provides a simple way to test that the OnboardingFlowView
/// compiles correctly with all its dependencies.
///
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §3.2 for test documentation standards
extension OnboardingFlowView {
    /// Creates a test instance with mock dependencies
    ///
    /// - Returns: OnboardingFlowView instance with mock services
    /// - SideEffects: Creates mock services for testing
    /// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §4.1 for mock documentation standards
    static func createForTesting() -> OnboardingFlowView {
        return OnboardingFlowView(
            coordinator: nil,
            userProfileRepository: MockUserProfileRepository(),
            analyticsService: MockAnalyticsService(),
            authService: MockAuthService()
        )
    }
}

/// Mock UserProfileRepository for testing
///
/// Provides controlled responses for testing user profile operations.
/// Tracks method calls and returns predefined results.
///
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §4.1 for mock documentation standards
class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        completion(nil) // Return nil for testing
    }
}

/// Mock AnalyticsService for testing
///
/// Tracks analytics events without sending them to external services.
/// Useful for testing analytics integration.
///
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §4.1 for mock documentation standards
class MockAnalyticsService: AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?) {
        print("MockAnalyticsService: Tracked event '\(name)' with properties: \(properties ?? [:])")
    }
}

/// Mock AuthService for testing
///
/// Provides controlled authentication state for testing.
/// Returns predefined user ID for consistent test behavior.
///
/// - SeeAlso: `CODE_DOCUMENTATION_RULES.md` §4.1 for mock documentation standards
class MockAuthService: AuthServiceProtocol {
    var currentUserId: String? {
        return "test-user-id"
    }
} 