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
                SageCard {
                    VStack(spacing: 20) {
                        SageButton(title: "Continue Anonymously") {
                            print("AuthChoiceView: Continue Anonymously button tapped")
                            viewModel.signInAnonymously()
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
                if let error = viewModel.errorMessage {
                    SageCard {
                        Text("Error: \(error)")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay) // UI_STANDARDS.md §2.4
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
            .navigationDestination(for: AuthFlow.self) { flow in
                switch flow {
                case .signUp:
                    SignUpView(viewModel: viewModel)
                case .login:
                    LoginView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            print("AuthChoiceView: appeared")
        }
    }
} 