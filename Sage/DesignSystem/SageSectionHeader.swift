import SwiftUI

struct SageSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(SageTypography.sectionHeader)
            .foregroundColor(SageColors.espressoBrown)
            .padding(.vertical, SageSpacing.small)
    }
} 