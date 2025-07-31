import SwiftUI

/// Main onboarding journey view that orchestrates the entire onboarding flow
/// - Follows DesignSystem patterns for consistent styling
/// - Uses nature-inspired, soft, grounded UX tone
/// - Implements all screens defined in GWT tests
struct OnboardingJourneyView: View {
    @StateObject private var viewModel: OnboardingJourneyViewModel
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil
    
    init(
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared,
        authService: AuthServiceProtocol = AuthService(),
        userProfileRepository: UserProfileRepositoryProtocol = UserProfileRepository(),
        microphonePermissionManager: MicrophonePermissionManagerProtocol = MicrophonePermissionManager(),
        vocalAnalysisService: HybridVocalAnalysisService? = nil,
        coordinator: OnboardingCoordinatorProtocol? = nil,
        dateProvider: DateProvider = SystemDateProvider(),
        onComplete: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: OnboardingJourneyViewModel(
            analyticsService: analyticsService,
            authService: authService,
            userProfileRepository: userProfileRepository,
            microphonePermissionManager: microphonePermissionManager,
            vocalAnalysisService: vocalAnalysisService,
            vocalBaselineService: VocalBaselineService(
                validationService: BaselineValidationService(
                    clinicalThresholdsService: ClinicalThresholdsService(
                        researchDataService: ResearchDataService()
                    )
                ),
                repository: VocalBaselineRepository(
                    firestoreClient: MockFirestoreClientProtocol()
                ),
                userProfileRepository: userProfileRepository
            ),
            coordinator: coordinator,
            dateProvider: dateProvider
        ))
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Soft atmospheric background following DesignSystem
            LinearGradient(
                gradient: Gradient(colors: [
                    SageColors.fogWhite,
                    SageColors.sandstone.opacity(0.5),
                    SageColors.earthClay.opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Abstract accent at bottom
            AbstractWaveBackground()
                .frame(height: 180)
                .opacity(0.22)
                .blur(radius: 2)
                .offset(y: 40)
                .accessibilityHidden(true)
            
            // Content based on current step
            switch viewModel.currentStep {
            case .signupMethod:
                SignupMethodView(viewModel: viewModel)
            case .explainer:
                ExplainerView(viewModel: viewModel)
            case .userInfoForm:
                UserInfoFormView(
                    isAnonymous: viewModel.selectedSignupMethod == .anonymous,
                    userInfo: $viewModel.userProfileData,
                    onComplete: { viewModel.completeUserInfo() }
                )
            case .sustainedVowelTest:
                SustainedVowelTestView(viewModel: viewModel)
            case .readingPrompt:
                ReadingPromptView(viewModel: viewModel)
            case .finalStep:
                FinalStepView(viewModel: viewModel)
            case .completed:
                // Onboarding completed - coordinator handles navigation
                Color.clear
                    .onAppear {
                        if let onComplete = onComplete {
                            onComplete()
                        }
                    }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            print("[OnboardingJourneyView] View appeared")
        }
    }
}

// MARK: - Signup Method View
// Note: SignupMethodView is defined in SignupMethodView.swift

// MARK: - Explainer View

struct ExplainerView: View {
    @ObservedObject var viewModel: OnboardingJourneyViewModel
    
    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer(minLength: 120)
            
            // Headline
            Text(viewModel.explainerHeadline)
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, SageSpacing.xlarge)
            
            // Subtext
            Text(viewModel.explainerSubtext)
                .font(SageTypography.body)
                .foregroundColor(SageColors.softTaupe)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                print("[ExplainerView] Continue button tapped")
                viewModel.selectBegin()
            }) {
                Text("Continue")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.fogWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SageSpacing.medium)
                    .background(SageColors.sageTeal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, SageSpacing.xlarge)
            .accessibilityLabel("Continue to profile setup. Provide your information.")
            
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Vocal Test View

struct SustainedVowelTestView: View {
    @ObservedObject var viewModel: OnboardingJourneyViewModel
    
    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer(minLength: 80)
            
            // Instruction
            Text(viewModel.sustainedVowelTestInstruction)
                .font(SageTypography.sectionHeader)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, SageSpacing.xlarge)
            
            // Prompt
            Text(viewModel.sustainedVowelTestPrompt)
                .font(SageTypography.headline)
                .foregroundColor(SageColors.cinnamonBark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
            
            // Recording UI
            VStack(spacing: SageSpacing.large) {
                // Countdown Timer
                if viewModel.recordingState.showCountdown {
                    CountdownTimerView()
                        .accessibilityIdentifier("CountdownTimer")
                }
                
                // Progress Bar
                if viewModel.recordingState.showProgressBar {
                    ProgressBarView()
                        .accessibilityIdentifier("ProgressBar")
                }
                
                // Waveform Animation
                if viewModel.recordingState.showWaveform {
                    WaveformView()
                        .accessibilityIdentifier("WaveformView")
                }
                
                // Success Message
                if let successMessage = viewModel.successMessage, !successMessage.isEmpty {
                    Text(successMessage)
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.sageTeal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SageSpacing.xlarge)
                }
                
                // Baseline Establishment (AC-002: Display Baseline Summary)
                if viewModel.hasEstablishedBaseline, let baseline = viewModel.vocalBaseline {
                    VStack(spacing: SageSpacing.medium) {
                        Text("✓ Your Voice Profile Established")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.sageTeal)
                        
                        VStack(alignment: .leading, spacing: SageSpacing.small) {
                            HStack {
                                Text("F0:")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.earthClay)
                                Spacer()
                                Text("\(String(format: "%.1f", baseline.biomarkers.f0.mean)) Hz")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.espressoBrown)
                            }
                            
                            HStack {
                                Text("Stability:")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.earthClay)
                                Spacer()
                                Text("\(String(format: "%.0f", baseline.biomarkers.stability.score))%")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.espressoBrown)
                            }
                            
                            HStack {
                                Text("Quality:")
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.earthClay)
                                Spacer()
                                Text(baseline.biomarkers.voiceQuality.qualityLevel.rawValue)
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.espressoBrown)
                            }
                        }
                        .padding(SageSpacing.medium)
                        .background(SageColors.fogWhite)
                        .cornerRadius(12)
                        
                        Text("This baseline will be used for future voice comparisons")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, SageSpacing.large)
                }
                
                // Baseline Error Display
                if let baselineError = viewModel.baselineError {
                    VStack(spacing: SageSpacing.small) {
                        Text("⚠️ Baseline Quality Issue")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.coralBlush)
                        
                        Text(baselineError)
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.cinnamonBark)
                            .multilineTextAlignment(.center)
                        
                        // Re-record button (AC-003: Re-record Baseline)
                        Button(action: {
                            Task {
                                await viewModel.reRecordBaseline()
                            }
                        }) {
                            Text("Re-record Baseline")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.sageTeal)
                        }
                    }
                    .padding(.horizontal, SageSpacing.large)
                }
                
                // Action Buttons
                if viewModel.isRecording {
                    // Recording in progress - show stop button
                    Button(action: {
                        print("[SustainedVowelTestView] Stop recording tapped")
                        viewModel.completeSustainedVowelTest()
                    }) {
                        Text("Stop Recording")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.fogWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SageSpacing.medium)
                            .background(SageColors.coralBlush)
                            .cornerRadius(16)
                    }
                    .accessibilityLabel("Stop recording. Complete the vocal test.")
                } else if viewModel.shouldShowNextButton && !viewModel.hasEstablishedBaseline {
                    // Recording complete - show next button to proceed through onboarding
                    VStack(spacing: SageSpacing.medium) {
                        Button(action: {
                            print("[SustainedVowelTestView] Next tapped after recording")
                            viewModel.selectNext()
                        }) {
                            Text("Next")
                                .font(SageTypography.headline)
                                .foregroundColor(SageColors.fogWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SageSpacing.medium)
                                .background(SageColors.sageTeal)
                                .cornerRadius(16)
                        }
                        .accessibilityLabel("Continue to next step")
                        
                        Text("Continue through onboarding while analysis processes")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                            .multilineTextAlignment(.center)
                    }
                } else if viewModel.hasEstablishedBaseline {
                    // Baseline established - show continue button
                    Button(action: {
                        print("[SustainedVowelTestView] Continue after baseline established")
                        viewModel.selectNext()
                    }) {
                        Text("Continue")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.fogWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SageSpacing.medium)
                            .background(SageColors.sageTeal)
                            .cornerRadius(16)
                    }
                    .accessibilityLabel("Continue to next step with established baseline")
                } else if !viewModel.isRecording && !viewModel.shouldShowNextButton && !viewModel.hasCompletedRecording {
                    // Ready to start recording - only show if no recording has been completed
                    Button(action: {
                        print("[SustainedVowelTestView] Begin recording tapped")
                        viewModel.startSustainedVowelTest()
                    }) {
                        Text(viewModel.beginButtonTitle)
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.fogWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SageSpacing.medium)
                            .background(SageColors.sageTeal)
                            .cornerRadius(16)
                    }
                    .accessibilityLabel("Begin recording. Start the vocal test.")
                }
            }
            .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            print("[SustainedVowelTestView] View appeared")
            viewModel.onSustainedVowelTestViewAppear()
        }
        .onDisappear {
            print("[SustainedVowelTestView] View disappeared")
            viewModel.onSustainedVowelTestViewDisappear()
        }
    }
}

// MARK: - Reading Prompt View

struct ReadingPromptView: View {
    @ObservedObject var viewModel: OnboardingJourneyViewModel
    
    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer(minLength: 120)
            
            // Heading
            Text(viewModel.readingPromptHeading)
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            
            // Placeholder content
            Text("This screen will contain reading prompt content in future iterations")
                .font(SageTypography.body)
                .foregroundColor(SageColors.softTaupe)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
            
            // Next Button
            Button(action: {
                print("[ReadingPromptView] Next button tapped")
                viewModel.selectNext()
            }) {
                Text(viewModel.nextButtonTitle)
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.fogWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SageSpacing.medium)
                    .background(SageColors.sageTeal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, SageSpacing.xlarge)
            .accessibilityLabel("Continue to final step. Complete onboarding setup.")
            
            Spacer(minLength: 60)
        }
        .navigationBarTitle("Reading Prompt", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Final Step View

struct FinalStepView: View {
    @ObservedObject var viewModel: OnboardingJourneyViewModel
    
    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer(minLength: 120)
            
            // Message
            Text(viewModel.finalStepMessage)
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
            
            // Finish Button
            Button(action: {
                print("[FinalStepView] Finish button tapped")
                viewModel.selectFinish()
            }) {
                Text(viewModel.finishButtonTitle)
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.fogWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SageSpacing.medium)
                    .background(SageColors.sageTeal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, SageSpacing.xlarge)
            .accessibilityLabel("Complete onboarding. Finish setup and go to home.")
            
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Recording UI Components

struct CountdownTimerView: View {
    @State private var timeRemaining = 10
    
    var body: some View {
        Text("\(timeRemaining)")
            .font(.system(size: 48, weight: .bold, design: .serif))
            .foregroundColor(SageColors.sageTeal)
            .onAppear {
                startCountdown()
            }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

struct ProgressBarView: View {
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(SageColors.sandstone)
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(SageColors.sageTeal)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
                    .animation(.linear(duration: 10), value: progress)
            }
        }
        .frame(height: 8)
        .onAppear {
            progress = 1.0
        }
    }
}

struct WaveformView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(SageColors.sageTeal)
                    .frame(width: 3, height: 20 + CGFloat(index % 3) * 10)
                    .scaleEffect(y: 0.5 + 0.5 * sin(Double(index) * 0.5 + animationOffset), anchor: .center)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: animationOffset)
            }
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
}

// MARK: - Preview

struct OnboardingJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingJourneyView()
    }
} 