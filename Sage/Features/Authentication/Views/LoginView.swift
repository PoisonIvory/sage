import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onAuthenticated: (() -> Void)? = nil

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
    private var errorMessage: String? {
        if case let .failed(error) = viewModel.state { return error } else { return nil }
    }

    var body: some View {
        VStack(spacing: 28) {
            SageSectionHeader(title: "Login")
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
                    SageButton(title: "Login") {
                        print("LoginView: Login button tapped")
                        viewModel.loginWithEmail()
                    }
                    .onChange(of: viewModel.state) { oldState, state in
                        if case .authenticated = state {
                            print("LoginView: User authenticated")
                            onAuthenticated?()
                        }
                    }
                    .disabled(!viewModel.isFormValid || isLoading)
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
        .onAppear {
            print("LoginView: appeared")
        }
    }
} 