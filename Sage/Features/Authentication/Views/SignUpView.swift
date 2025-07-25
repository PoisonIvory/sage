import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var signUpSuccess = false

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Create Account")
            SageCard {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(SageTypography.body)
                        .padding(12)
                        .background(SageColors.fogWhite)
                        .cornerRadius(10)
                    SecureField("Password", text: $viewModel.password)
                        .font(SageTypography.body)
                        .padding(12)
                        .background(SageColors.fogWhite)
                        .cornerRadius(10)
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay) // UI_STANDARDS.md §2.4
                    }
                    SageButton(title: "Sign Up") {
                        print("SignUpView: Sign Up button tapped")
                        viewModel.signUpWithEmail()
                        if viewModel.isAuthenticated {
                            signUpSuccess = true
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            if viewModel.isLoading {
                ProgressView().padding()
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
    }
} 