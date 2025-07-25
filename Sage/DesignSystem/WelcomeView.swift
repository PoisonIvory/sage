import SwiftUI

struct WelcomeView: View {
    @State private var showHeadline = false
    @State private var showBody = false
    @State private var showActions = false
    @Environment(\.colorScheme) var colorScheme
    
    // Navigation callbacks (to be hooked up in parent or App)
    var onBrowse: (() -> Void)? = nil
    var onBegin: (() -> Void)? = nil
    var onLogin: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Soft atmospheric background
            LinearGradient(
                gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5), SageColors.earthClay.opacity(0.3)]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Abstract accent at bottom
            AbstractWaveBackground()
                .frame(height: 180)
                .opacity(0.22)
                .blur(radius: 2)
                .offset(y: 40)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: SageSpacing.large) {
                Spacer(minLength: 100)
                // Headline
                Text("Women have always spoken.")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline ? 0 : 20)
                    .animation(.easeInOut(duration: 1.0).delay(0.1), value: showHeadline)
                // Body
                Text("Sage is here to listen.")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.softTaupe)
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .padding(.top, SageSpacing.large)
                    .opacity(showBody ? 1 : 0)
                    .offset(y: showBody ? 0 : 20)
                    .animation(.easeInOut(duration: 1.0).delay(0.6), value: showBody)
                Spacer()
                // Primary CTA: Get Started
                VStack(spacing: SageSpacing.medium) {
                    // Get Started Button
                    Text("Get Started")
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.fogWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SageSpacing.medium)
                        .background(SageColors.sageTeal)
                        .cornerRadius(16)
                        .scaleEffect(showActions ? 1.0 : 0.95)
                        .opacity(showActions ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(1.1), value: showActions)
                        .onTapGesture {
                            print("WelcomeView: 'Get Started' tapped")
                            AnalyticsService.shared.track(
                                AnalyticsEvent.onboardingStarted,
                                properties: [
                                    "source": "WelcomeView",
                                    "event_version": 1
                                ]
                            )
                            onBegin?()
                        }
                        .accessibilityLabel("Get started with Sage. Begin your voice journaling journey.")
                        .accessibilityAddTraits(.isButton)
                    // Secondary CTA: I already have an account
                    Text("I already have an account")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.softTaupe)
                        .underline()
                        .multilineTextAlignment(.center)
                        .padding(.top, SageSpacing.small)
                        .opacity(showActions ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(1.3), value: showActions)
                        .onTapGesture {
                            print("WelcomeView: 'I already have an account' tapped")
                            onLogin?()
                        }
                        .accessibilityLabel("Log in to your Sage account.")
                        .accessibilityHint("Access your saved voice journals.")
                }
                .padding(.top, SageSpacing.large)
                .padding(.horizontal, SageSpacing.xlarge)
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            print("WelcomeView: appeared (poetic minimal mode)")
            showHeadline = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showBody = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showActions = true }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .previewLayout(.sizeThatFits)
    }
} 