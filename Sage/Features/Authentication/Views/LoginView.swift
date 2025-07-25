import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Login")
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
                    SageButton(title: "Login") {
                        print("LoginView: Login button tapped")
                        viewModel.loginWithEmail()
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
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
        .onAppear {
            print("LoginView: appeared")
        }
    }
} 