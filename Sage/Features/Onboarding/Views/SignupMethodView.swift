import SwiftUI

/// Protocol for ViewModels that support signup method selection
protocol SignupMethodSelecting: ObservableObject {
    func selectAnonymous()
    func selectEmail()
    var email: String { get set }
    var password: String { get set }
    var fieldErrors: [String: String] { get }
}

// MARK: - OnboardingJourneyViewModel Conformance
extension OnboardingJourneyViewModel: SignupMethodSelecting {
    // Already has the required methods and properties
}

struct SignupMethodView<ViewModel: SignupMethodSelecting>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer(minLength: 100)
            
            // Headline
            Text("Begin Your Journey")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            
            // Subtext
            Text("Choose how you'd like to start your voice journaling experience")
                .font(SageTypography.body)
                .foregroundColor(SageColors.softTaupe)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
            
            // Signup Options
            VStack(spacing: SageSpacing.medium) {
                // Anonymous Signup Button
                Button(action: {
                    print("[SignupMethodView] Anonymous signup tapped")
                    viewModel.selectAnonymous()
                }) {
                    Text("Continue Anonymously")
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.fogWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SageSpacing.medium)
                        .background(SageColors.sageTeal)
                        .cornerRadius(16)
                }
                .accessibilityLabel("Continue anonymously. Start voice journaling without creating an account.")
                
                // Divider
                HStack {
                    SageDivider()
                    Text("or")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.softTaupe)
                        .padding(.horizontal, SageSpacing.medium)
                    SageDivider()
                }
                .padding(.vertical, SageSpacing.medium)
                
                // Email Signup Form - only show if ViewModel supports it
                if !viewModel.fieldErrors.isEmpty || !viewModel.email.isEmpty || !viewModel.password.isEmpty {
                    VStack(spacing: SageSpacing.medium) {
                        SageTextField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            error: viewModel.fieldErrors["email"],
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        SageTextField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            isSecure: true,
                            error: viewModel.fieldErrors["password"]
                        )
                        
                        Button(action: {
                            print("[SignupMethodView] Email signup tapped")
                            viewModel.selectEmail()
                        }) {
                            Text("Sign Up")
                                .font(SageTypography.headline)
                                .foregroundColor(SageColors.fogWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SageSpacing.medium)
                                .background(SageColors.coralBlush)
                                .cornerRadius(16)
                        }
                        .accessibilityLabel("Sign up with email and password")
                    }
                } else {
                    // Simple email signup button for OnboardingFlowViewModel
                    Button(action: {
                        print("[SignupMethodView] Email signup tapped")
                        viewModel.selectEmail()
                    }) {
                        Text("Sign Up with Email")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.fogWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SageSpacing.medium)
                            .background(SageColors.coralBlush)
                            .cornerRadius(16)
                    }
                    .accessibilityLabel("Sign up with email")
                }
            }
            .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            print("[SignupMethodView] View appeared")
        }
    }
}

struct SignupMethodView_Previews: PreviewProvider {
    static var previews: some View {
        SignupMethodView(viewModel: OnboardingJourneyViewModel(
            analyticsService: AnalyticsService.shared,
            authService: AuthService(),
            userProfileRepository: UserProfileRepository(),
            microphonePermissionManager: MicrophonePermissionManager(),
            vocalAnalysisService: HybridVocalAnalysisService(),
            vocalBaselineService: VocalBaselineService(
                validationService: BaselineValidationService(
                    clinicalThresholdsService: ClinicalThresholdsService(
                        researchDataService: ResearchDataService()
                    )
                ),
                repository: VocalBaselineRepository(
                    firestoreClient: MockFirestoreClientProtocol()
                ),
                userProfileRepository: UserProfileRepository()
            ),
            coordinator: nil,
            dateProvider: SystemDateProvider()
        ))
    }
} 