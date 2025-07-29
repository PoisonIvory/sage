import SwiftUI

struct SageEmptyState<CTA: View>: View {
    let iconName: String
    let title: String
    let message: String
    let cta: CTA?
    let flags: FeatureFlags?

    @State private var appeared = false

    init(iconName: String, title: String, message: String, flags: FeatureFlags? = nil, @ViewBuilder cta: () -> CTA? = { nil }) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.flags = flags
        self.cta = cta()
    }

    var body: some View {
        VStack(spacing: SageSpacing.xLarge(flags)) {
            ZStack {
                Circle()
                    .fill(SageColors.sandstone.opacity(0.2))
                    .frame(width: 96, height: 96)
                Image(systemName: iconName)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(SageColors.accent(flags))
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(SageTypography.body(flags))
                .fontWeight(.semibold)
                .foregroundColor(SageColors.primary(flags))
                .multilineTextAlignment(.center)
                .padding(.top, SageSpacing.small(flags))
            Text(message)
                .font(SageTypography.caption(flags))
                .foregroundColor(SageColors.secondary(flags))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xlarge)
            if let cta = cta {
                cta
                    .padding(.top, SageSpacing.medium(flags))
            }
        }
        .frame(maxWidth: 320)
        .padding(SageSpacing.xLarge(flags))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(SageColors.surface(flags))
                .shadow(color: SageColors.sandstone.opacity(0.13), radius: 18, x: 0, y: 6)
        )
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.7), value: appeared)
        .onAppear { appeared = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + ". " + message)
    }
}

struct SageEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SageEmptyState(
                iconName: "mic.circle.fill",
                title: "No recordings yet",
                message: "Start your first voice journal by tapping the + button."
            ) {
                Button(action: { print("CTA tapped") }) {
                    Text("Tap to begin")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.sageTeal)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule().fill(SageColors.sandstone.opacity(0.25))
                        )
                }
            }
        }
        .padding()
        .background(SageColors.fogWhite)
        .previewLayout(.sizeThatFits)
    }
}
// FEEDBACK_LOG.md: New empty-state card pattern with softly tinted background, expressive icon layering, and CTA slot. See UI_STANDARDS.md for card styling and spacing. 