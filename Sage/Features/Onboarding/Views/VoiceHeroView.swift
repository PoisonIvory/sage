import SwiftUI

struct VoiceHeroView: View {
    var onNext: () -> Void
    @State private var animateMouth = false
    
    var body: some View {
        ZStack {
            // Background: off-white with subtle wave texture
            SageColors.fogWhite
                .ignoresSafeArea()
            AbstractWaveBackground()
                .opacity(0.18)
                .blur(radius: 1)
                .ignoresSafeArea()
            
            HStack(alignment: .center, spacing: 0) {
                // Line-art mouth/voice motif with subtle animation
                VStack {
                    MouthVoiceMotif(animate: animateMouth)
                        .frame(width: 160, height: 160)
                        .padding(.leading, 24)
                        .accessibilityHidden(true)
                    Spacer()
                }
                
                Spacer(minLength: 0)
                
                // Text block
                VStack(alignment: .leading, spacing: 20) {
                    Text("Stop explaining your symptoms.")
                        .font(SageTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(SageColors.espressoBrown)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel("Stop explaining your symptoms.")
                    
                    // Subtitle with emphasis on 'proving'
                    subtitleText
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.cinnamonBark)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel("Start proving them.")
                    
                    Spacer(minLength: 0)
                    
                    // Next button
                    SageButton(title: "Next") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            animateMouth = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onNext()
                        }
                    }
                    .accessibilityLabel("Continue to next onboarding screen")
                    .scaleEffect(animateMouth ? 1.0 : 0.97)
                    .shadow(color: SageColors.earthClay.opacity(animateMouth ? 0.18 : 0.0), radius: animateMouth ? 12 : 0)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 48)
                .frame(maxWidth: 400, alignment: .center)
            }
        }
        .onAppear {
            withAnimation(Animation.spring(response: 1.0, dampingFraction: 0.7).repeatForever(autoreverses: true)) {
                animateMouth = true
            }
        }
    }
    
    // Subtitle with emphasis on 'proving'
    private var subtitleText: some View {
        let base = "Start "
        let emphasis = "proving"
        let end = " them."
        return (
            Text(base) +
            Text(emphasis).italic().fontWeight(.semibold) +
            Text(end)
        )
    }
}

// Simple line-art mouth/voice motif with subtle wave animation
struct MouthVoiceMotif: View {
    var animate: Bool
    var body: some View {
        ZStack {
            // Mouth outline
            Path { path in
                path.move(to: CGPoint(x: 40, y: 80))
                path.addQuadCurve(to: CGPoint(x: 120, y: 80), control: CGPoint(x: 80, y: 120))
                path.addQuadCurve(to: CGPoint(x: 40, y: 80), control: CGPoint(x: 80, y: 40))
            }
            .stroke(SageColors.cinnamonBark, lineWidth: 3)
            .opacity(0.95)
            // Voice waves (animated)
            ForEach(0..<3) { i in
                WaveShape(phase: animate ? CGFloat(i) * 0.5 : 0)
                    .stroke(SageColors.earthClay.opacity(0.7 - Double(i) * 0.2), lineWidth: 1.5)
                    .frame(width: 80 + CGFloat(i) * 18, height: 24 + CGFloat(i) * 8)
                    .offset(y: -32 - CGFloat(i) * 10)
                    .opacity(animate ? 0.7 : 0.3)
                    .animation(Animation.spring(response: 1.2 + Double(i) * 0.2, dampingFraction: 0.8).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amplitude: CGFloat = rect.height / 3
        let length = rect.width
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: length, by: 2) {
            let relativeX = x / length
            let y = midY + sin(relativeX * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
} 