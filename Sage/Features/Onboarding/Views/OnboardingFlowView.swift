import SwiftUI
import Combine

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingFlowViewModel()

    var body: some View {
        VStack {
            switch viewModel.step {
            case .loginSignupChoice:
                LoginSignupChoiceView(
                    onLogin: { viewModel.selectLogin() },
                    onSignup: { viewModel.selectSignup() }
                )
            case .signupMethod:
                SignupMethodView(
                    onAnonymous: { viewModel.selectAnonymous() },
                    onEmail: { viewModel.selectEmail() }
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
        .onChange(of: viewModel.step) { _, newStep in
            print("OnboardingFlowView: step changed to \(newStep)") // UI_STANDARDS.md §5.2
            if newStep == .completed {
                AnalyticsService.shared.track(
                    AnalyticsEvent.onboardingComplete,
                    properties: [
                        "source": "OnboardingFlowView",
                        "event_version": 1
                        // Optionally add duration if available
                    ]
                )
            }
        }
    }
}

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView()
    }
} 