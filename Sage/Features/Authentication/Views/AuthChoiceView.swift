import SwiftUI

struct AuthChoiceView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedFlow: AuthFlow?

    enum AuthFlow: Hashable {
        case signUp
        case login
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                SageSectionHeader(title: "Welcome to Sage")
                
                // Show loading indicator during existing session check
                if case .loading = viewModel.state {
                    VStack(spacing: 16) {
                        SageProgressView()
                        Text("Checking your session...")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.softTaupe)
                    }
                    .padding()
                } else {
                    SageCard {
                        VStack(spacing: 20) {
                            SageButton(title: "Continue Anonymously") {
                                handleContinueAnonymouslyTapped()
                            }
                            NavigationLink(value: AuthFlow.signUp) {
                                Text("Sign Up with Email")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.sageTeal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            NavigationLink(value: AuthFlow.login) {
                                Text("Log In")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.sageTeal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                
                if case let .failed(error) = viewModel.state {
                    SageCard {
                        Text("Error: \(error)")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                    }
                }
                if case .loading = viewModel.state {
                    ProgressView().padding()
                }
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal)
            .background(SageColors.fogWhite.ignoresSafeArea())
            .navigationDestination(for: AuthFlow.self) { flow in
                switch flow {
                case .signUp:
                    SignUpView(viewModel: viewModel, onAuthenticated: handleAuthenticationSuccess)
                case .login:
                    LoginView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            handleViewAppeared()
        }
        .onChange(of: viewModel.state) { state in
            if case .authenticated = state {
                handleAuthenticationSuccess()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleViewAppeared() {
        print("AuthChoiceView: appeared")
        checkExistingSession()
    }
    
    private func handleContinueAnonymouslyTapped() {
        print("AuthChoiceView: Continue Anonymously button tapped")
        viewModel.signInAnonymously()
    }
    
    private func checkExistingSession() {
        if case .authenticated = viewModel.state {
            print("AuthChoiceView: Already authenticated")
            handleAuthenticationSuccess()
        }
    }
    
    private func handleAuthenticationSuccess() {
        print("AuthChoiceView: Authentication successful")
        
        AnalyticsService.shared.trackAuthEvent(
            "auth_success",
            source: "AuthChoiceView",
            authViewModel: viewModel
        )
        
        // For NavigationStack usage, we might want to navigate to a different view
        // or handle the authentication differently
        print("AuthChoiceView: Authentication complete, user can proceed")
    }
} 