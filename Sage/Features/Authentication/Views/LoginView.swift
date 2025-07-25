import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Login")
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
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay) // UI_STANDARDS.md §2.4
                    }
                    SageButton(title: "Login") {
                        print("LoginView: Login button tapped")
                        viewModel.loginWithEmail()
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
        .onAppear {
            print("LoginView: appeared")
        }
    }
} 