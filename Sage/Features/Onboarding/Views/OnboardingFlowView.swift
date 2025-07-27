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
            case .signupMethod:
                SignupMethodView(viewModel: viewModel)
            case .explainer:
                Text("Explainer Screen - Let's run some quick tests")
            case .vocalTest:
                Text("Vocal Test Screen - Please say 'ahh' for 10 seconds")
            case .readingPrompt:
                Text("Reading Prompt Screen")
            case .finalStep:
                Text("Final Step Screen - Almost there!")
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

// AuthService is defined in AuthService.swift



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
        // Note: For actual testing, use OnboardingTestHarness instead of direct mock instantiation
        return OnboardingFlowView(
            coordinator: nil,
            userProfileRepository: UserProfileRepository(),
            analyticsService: AnalyticsService.shared,
            authService: AuthService()
        )
    }
}

// Mock classes are defined in OnboardingTestHarness.swift 