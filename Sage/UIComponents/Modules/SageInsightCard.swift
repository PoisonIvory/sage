import SwiftUI

/// SageInsightCard: Card for displaying dashboard insights or suggestions
/// - References: UI_STANDARDS.md §1, §2, §3, §6; DATA_STANDARDS.md §3.2
struct SageInsightCard: View {
    let title: String
    let iconName: String // SF Symbol
    let valueText: String
    let explanation: String
    var iconColor: Color = SageColors.sageTeal

    var body: some View {
        SageCard {
            HStack(alignment: .top, spacing: SageSpacing.medium) {
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: SageSpacing.small) {
                    Text(title)
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.espressoBrown)
                    Text(valueText)
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.sageTeal)
                    Text(explanation)
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(valueText). \(explanation)")
        }
    }
}

// MARK: - Preview
struct SageInsightCard_Previews: PreviewProvider {
    static var previews: some View {
        SageInsightCard(
            title: "Voice Stability",
            iconName: "waveform.path.ecg",
            valueText: "7/10",
            explanation: "Your voice was slightly more shaky than average today (jitter up, clarity down)."
        )
        .padding()
        .background(SageColors.fogWhite)
        .previewLayout(.sizeThatFits)
    }
} 