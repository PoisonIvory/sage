import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var signUpSuccess = false
    var onAuthenticated: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Create Account")
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
                        print("SignUpView: Sign Up button tapped")
                        viewModel.signUpWithEmail()
                        if viewModel.isAuthenticated {
                            signUpSuccess = true
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    // Optional: Continue Anonymously
                    Text("Continue Anonymously")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.softTaupe)
                        .underline()
                        .multilineTextAlignment(.center)
                        .padding(.top, SageSpacing.medium)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            print("SignUpView: Continue Anonymously tapped")
                            viewModel.signInAnonymously()
                        }
                        .accessibilityLabel("Continue without creating an account.")
                        .accessibilityHint("Browse Sage anonymously. No account or data is stored.")
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
            print("SignUpView: appeared")
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                print("SignUpView: Authenticated, calling onAuthenticated")
                AnalyticsService.shared.track(
                    "sign_up_complete",
                    properties: [
                        "method": viewModel.isAnonymous ? "anonymous" : "email",
                        "source": "SignUpView",
                        "event_version": 1
                    ]
                )
                onAuthenticated?()
            }
        }
    }
} 