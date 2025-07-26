import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var signUpSuccess = false
    let onAuthenticated: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Create Account")
            
            // Show loading indicator during existing session check
            if viewModel.isCheckingSession {
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
                            error: viewModel.errorMessage?.contains("email") == true ? viewModel.errorMessage : nil,
                            keyboardType: .emailAddress
                        )
                        SageTextField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            isSecure: true,
                            error: viewModel.errorMessage?.contains("password") == true ? viewModel.errorMessage : nil
                        )
                        SageButton(title: "Sign Up") {
                            handleSignUpTapped()
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        
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
            
            if viewModel.isLoading {
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
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
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
        if viewModel.isAuthenticated {
            signUpSuccess = true
        }
    }
    
    private func handleContinueAnonymouslyTapped() {
        print("SignUpView: Continue Anonymously tapped")
        viewModel.signInAnonymously()
    }
    
    private func checkExistingSession() {
        if viewModel.isAuthenticated {
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