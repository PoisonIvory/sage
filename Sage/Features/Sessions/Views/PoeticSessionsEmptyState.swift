import SwiftUI

struct PoeticSessionsEmptyState: View {
    @State private var showIcon = false
    @State private var showText = false
    var body: some View {
        ZStack(alignment: .bottom) {
            // Soft abstract accent at bottom
            AbstractWaveBackground()
                .frame(height: 140)
                .opacity(0.18)
                .blur(radius: 2)
                .offset(y: 30)
                .accessibilityHidden(true)
            VStack(spacing: SageSpacing.large) {
                Spacer(minLength: 40)
                // Animated Icon
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(SageColors.sageTeal)
                    .opacity(showIcon ? 1 : 0)
                    .scaleEffect(showIcon ? 1.0 : 0.95)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showIcon)
                    .accessibilityHidden(true)
                // Poetic Headline
                Text("No voice journals yet.")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 16)
                    .animation(.easeInOut(duration: 1.0).delay(0.5), value: showText)
                // Poetic Body
                Text("Begin your first reflection by tapping the plus.")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.softTaupe)
                    .multilineTextAlignment(.center)
                    .padding(.top, SageSpacing.small)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 16)
                    .animation(.easeInOut(duration: 1.0).delay(0.8), value: showText)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, SageSpacing.xlarge)
            .frame(maxWidth: 420)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No voice journals yet. Begin your first reflection by tapping the plus button.")
        }
        .background(SageColors.fogWhite)
        .onAppear {
            showIcon = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showText = true }
        }
    }
}

struct PoeticSessionsEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        PoeticSessionsEmptyState()
            .previewLayout(.sizeThatFits)
            .background(SageColors.fogWhite)
    }
} 