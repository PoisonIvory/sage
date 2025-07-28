import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var signUpSuccess = false
    let onAuthenticated: () -> Void

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
    private var errorMessage: String? {
        if case let .failed(error) = viewModel.state { return error } else { return nil }
    }

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Create Account")
            
            // Show loading indicator during existing session check
            if isLoading {
                VStack(spacing: 16) {
                    SageProgressView()
                    Text("Checking your session...")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.softTaupe)
                }
                .padding()
            } else {
                SageCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SageTextField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            error: errorMessage?.contains("email") == true ? errorMessage : nil,
                            keyboardType: .emailAddress
                        )
                        SageTextField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            isSecure: true,
                            error: errorMessage?.contains("password") == true ? errorMessage : nil
                        )
                        SageButton(title: "Sign Up") {
                            handleSignUpTapped()
                        }
                        .disabled(!viewModel.isFormValid || isLoading)
                        
                        // Continue Anonymously button
                        Text("Continue Anonymously")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.softTaupe)
                            .underline()
                            .multilineTextAlignment(.center)
                            .padding(.top, SageSpacing.medium)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                handleContinueAnonymouslyTapped()
                            }
                            .accessibilityLabel("Continue without creating an account.")
                            .accessibilityHint("Browse Sage anonymously. No account or data is stored.")
                    }
                }
            }
            
            if isLoading {
                SageProgressView().padding()
            }
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal)
        .background(SageColors.fogWhite.ignoresSafeArea())
        .alert(isPresented: $signUpSuccess) {
            Alert(
                title: Text("Success!"),
                message: Text("Your account was created successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            handleViewAppeared()
        }
        .onChange(of: viewModel.state) { oldState, state in
            if case .authenticated = state {
                handleAuthenticationSuccess()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleViewAppeared() {
        print("SignUpView: appeared")
        checkExistingSession()
    }
    
    private func handleSignUpTapped() {
        print("SignUpView: Sign Up button tapped")
        viewModel.signUpWithEmail()
        if case .authenticated = viewModel.state {
            signUpSuccess = true
        }
    }
    
    private func handleContinueAnonymouslyTapped() {
        print("SignUpView: Continue Anonymously tapped")
        viewModel.signInAnonymously()
    }
    
    private func checkExistingSession() {
        if case .authenticated = viewModel.state {
            print("SignUpView: Already authenticated, calling onAuthenticated")
            handleAuthenticationSuccess()
        }
    }
    
    private func handleAuthenticationSuccess() {
        print("SignUpView: Authentication successful, calling onAuthenticated")
        
        AnalyticsService.shared.trackAuthEvent(
            "sign_up_complete",
            source: "SignUpView",
            authViewModel: viewModel
        )
        
        onAuthenticated()
    }
}

// MARK: - Convenience Initializer for NavigationStack Usage
extension SignUpView {
    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        self.onAuthenticated = {
            // Default behavior for NavigationStack usage
            print("SignUpView: Default onAuthenticated called (NavigationStack usage)")
        }
    }
} 