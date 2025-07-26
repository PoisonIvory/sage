import SwiftUI

/// SageProgressRing: Circular progress indicator for dashboard metrics
/// - References: UI_STANDARDS.md §1, §3, §4; DATA_STANDARDS.md §3.2
struct SageProgressRing: View {
    var progress: Double // 0.0 to 1.0
    var label: String
    var valueText: String
    var ringColor: Color = SageColors.sageTeal
    var backgroundColor: Color = SageColors.sandstone
    var lineWidth: CGFloat = 8
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
            VStack(spacing: 2) {
                Text(valueText)
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                Text(label)
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.earthClay)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText)")
        .accessibilityValue("Progress: \(Int(progress * 100)) percent")
    }
}

// MARK: - Preview
struct SageProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        SageProgressRing(progress: 0.75, label: "Fluency", valueText: "7.5/10")
            .padding()
            .background(SageColors.fogWhite)
            .previewLayout(.sizeThatFits)
    }
} 