import SwiftUI

/// Demo view to test the onboarding journey implementation
/// - Shows the onboarding flow in action
/// - Uses mock services for testing
struct OnboardingJourneyDemoView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Spacer()
            
            Text("Onboarding Journey Demo")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            
            Text("Tap the button below to start the onboarding journey")
                .font(SageTypography.body)
                .foregroundColor(SageColors.softTaupe)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xlarge)
            
            Button(action: {
                print("[OnboardingJourneyDemoView] Starting onboarding journey")
                showOnboarding = true
            }) {
                Text("Start Onboarding")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.fogWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SageSpacing.medium)
                    .background(SageColors.sageTeal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, SageSpacing.xlarge)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingJourneyView(
                analyticsService: AnalyticsService.shared,
                authService: AuthService(),
                userProfileRepository: UserProfileRepository(),
                microphonePermissionManager: MicrophonePermissionManager(),
                audioRecorder: OnboardingAudioRecorder(),
                audioUploader: AudioUploader(),
                coordinator: nil,
                dateProvider: SystemDateProvider()
            )
        }
    }
}

// MARK: - Mock Services for Demo

// Mock classes are defined in OnboardingTestHarness.swift

// MARK: - Preview

struct OnboardingJourneyDemoView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingJourneyDemoView()
    }
} 