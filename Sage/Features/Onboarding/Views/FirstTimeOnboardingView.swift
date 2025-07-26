import SwiftUI

/// FirstTimeOnboardingView
/// A poetic, animated onboarding flow for first-time users, inspired by Co–Star and Sage's design system.
/// - Three screens: Welcome, Start Your First Entry, You’re In
/// - Uses TabView with PageTabViewStyle for paging
/// - All colors, spacing, and typography from Sage design system
/// - Self-contained: manages its own state and session logic
/// - Handoff to main app via onComplete closure
struct FirstTimeOnboardingView: View {
    // MARK: - State
    @State private var currentPage = 0
    @State private var isRecording = false
    @State private var hasRecorded = false
    @State private var micPermissionDenied = false
    @State private var animateCelebration = false
    @State private var animateWave = false
    @State private var animateParticles = false
    @State private var onboardingComplete = false
    @State private var errorMessage: String? = nil

    // Callback to trigger navigation to home
    var onComplete: (() -> Void)? = nil

    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated background (gradient + abstract wave)
            LinearGradient(
                gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5), SageColors.sageTeal.opacity(0.18)]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(
                AbstractWaveBackground()
                    .frame(height: 180)
                    .opacity(0.22)
                    .blur(radius: 2)
                    .offset(y: 40)
                    .accessibilityHidden(true)
            )
            // Optional: floating particles for extra poetry
            if animateParticles {
                ParticleField()
                    .transition(.opacity)
            }
            // Main onboarding content
            TabView(selection: $currentPage) {
                // --- Screen 1: Voice Hero Manifesto ---
                VoiceHeroView {
                    print("[Onboarding] VoiceHeroView: Next tapped, moving to Screen 2")
                    withAnimation(.spring()) { currentPage = 1 }
                }
                .tag(0)
                .onAppear {
                    print("[Onboarding] VoiceHeroView appeared")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { animateParticles = true }
                }
                // --- Screen 2: Start Your First Entry ---
                VStack(spacing: SageSpacing.xLarge) {
                    Spacer(minLength: 60)
                    AnimatedMicBackground(isActive: isRecording)
                        .frame(height: 120)
                        .padding(.bottom, SageSpacing.large)
                        .accessibilityHidden(true)
                    Text("Start Your First Entry")
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.espressoBrown)
                        .multilineTextAlignment(.center)
                        .opacity(1)
                        .accessibilityLabel("Start your first entry")
                    Text("Try your voice")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.cinnamonBark)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                        .padding(.top, SageSpacing.small)
                    SageButton(title: isRecording ? "Recording..." : "Try your voice") {
                        print("[Onboarding] Screen 2: Try your voice tapped")
                        requestMicrophoneAndStart()
                    }
                    .disabled(isRecording)
                    .accessibilityLabel("Try your voice. Starts microphone access and your first session.")
                    if micPermissionDenied {
                        Text("Microphone access is required. Please enable it in Settings.")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.coralBlush)
                            .multilineTextAlignment(.center)
                            .padding(.top, SageSpacing.medium)
                    }
                    Spacer()
                    if hasRecorded {
                        SageButton(title: "Next") {
                            print("[Onboarding] Screen 2: Next tapped, moving to Screen 3")
                            withAnimation(.spring()) { currentPage = 2 }
                        }
                        .accessibilityLabel("Next: Enter your journal")
                    }
                    Spacer(minLength: 40)
                }
                .tag(1)
                .onAppear {
                    print("[Onboarding] Screen 2 appeared")
                }
                // --- Screen 3: You’re In ---
                VStack(spacing: SageSpacing.xLarge) {
                    Spacer(minLength: 80)
                    if animateCelebration {
                        CelebrationAnimation()
                            .frame(height: 120)
                            .transition(.scale)
                            .accessibilityHidden(true)
                    }
                    Text("Welcome to your journal")
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.sageTeal)
                        .multilineTextAlignment(.center)
                        .opacity(animateCelebration ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: animateCelebration)
                        .accessibilityLabel("Welcome to your journal")
                    Text("You’re in. Your voice matters.")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.espressoBrown)
                        .multilineTextAlignment(.center)
                        .opacity(animateCelebration ? 1 : 0.7)
                        .animation(.easeInOut(duration: 1.2), value: animateCelebration)
                    Spacer()
                    SageButton(title: "Enter App") {
                        print("[Onboarding] Screen 3: Enter App tapped, onboarding complete")
                        onboardingComplete = true
                        onComplete?()
                    }
                    .accessibilityLabel("Enter the app")
                    Spacer(minLength: 40)
                }
                .tag(2)
                .onAppear {
                    print("[Onboarding] Screen 3 appeared")
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                        animateCelebration = true
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.7), value: currentPage)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Onboarding step \(currentPage + 1) of 3")
            // Error alert
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { newValue in if !newValue { errorMessage = nil } }
            )) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Microphone/session logic (self-contained)
    private func requestMicrophoneAndStart() {
        print("[Onboarding] Requesting microphone permission...")
        AudioRecorder.shared.requestMicrophonePermission { granted in
            print("[Onboarding] Microphone permission granted=\(granted)")
            if granted {
                isRecording = true
                micPermissionDenied = false
                print("[Onboarding] Recording started (simulated)")
                // Simulate recording (replace with real session logic as needed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isRecording = false
                    hasRecorded = true
                    print("[Onboarding] Recording ended (simulated), user can proceed")
                    // Save a mock session (replace with real save logic)
                    // ...
                }
            } else {
                micPermissionDenied = true
                errorMessage = "Microphone access is required to record your voice journal. Please enable it in Settings."
                print("[Onboarding] Microphone permission denied, error shown to user")
            }
        }
    }
}

// MARK: - Animated Waveform (Screen 1)
struct AnimatedWaveform: View {
    var isActive: Bool
    @State private var phase: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let midY = height / 2
                let amplitude: CGFloat = isActive ? 18 : 6
                let frequency: CGFloat = 1.5
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / width
                    let y = midY + sin((relativeX + phase) * .pi * frequency) * amplitude
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(SageColors.sageTeal, lineWidth: 3)
            .opacity(0.8)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase += 1
                }
            }
        }
    }
}

// MARK: - Animated Mic Background (Screen 2)
struct AnimatedMicBackground: View {
    var isActive: Bool
    @State private var scale: CGFloat = 1.0
    var body: some View {
        ZStack {
            Circle()
                .fill(SageColors.sandstone.opacity(0.18))
                .frame(width: 120, height: 120)
                .scaleEffect(isActive ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isActive)
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundColor(SageColors.sageTeal)
                .scaleEffect(isActive ? 1.08 : 1.0)
                .animation(.spring(response: 0.7, dampingFraction: 0.6), value: isActive)
        }
    }
}

// MARK: - Celebration Animation (Screen 3)
struct CelebrationAnimation: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    var body: some View {
        ZStack {
            Circle()
                .fill(SageColors.sageTeal.opacity(0.18))
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
                        scale = 1.2
                        opacity = 1.0
                    }
                }
            Image(systemName: "star.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(SageColors.coralBlush)
                .scaleEffect(scale)
                .opacity(opacity)
        }
    }
}

// MARK: - Particle Field (Optional, for poetry)
struct ParticleField: View {
    @State private var particles: [CGPoint] = (0..<18).map { _ in CGPoint(x: .random(in: 0...1), y: .random(in: 0...1)) }
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particles.count, id: \ .self) { i in
                Circle()
                    .fill(SageColors.softTaupe.opacity(0.18))
                    .frame(width: 8, height: 8)
                    .position(x: particles[i].x * geo.size.width, y: particles[i].y * geo.size.height)
                    .animation(
                        Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(Double(i) * 0.1),
                        value: particles[i]
                    )
            }
        }
        .onAppear {
            for i in particles.indices {
                particles[i] = CGPoint(x: .random(in: 0...1), y: .random(in: 0...1))
            }
        }
    }
}

// MARK: - Preview
struct FirstTimeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeOnboardingView()
            .background(SageColors.fogWhite)
            .previewLayout(.sizeThatFits)
    }
} 