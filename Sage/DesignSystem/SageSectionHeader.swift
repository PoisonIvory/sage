import SwiftUI

struct SageSectionHeader: View {
    let title: String
    init(title: String) {
        self.title = title
        print("SageSectionHeader: initialized with title=\(title)")
    }
    var body: some View {
        Text(title)
            .font(SageTypography.sectionHeader)
            .foregroundColor(SageColors.espressoBrown)
            .padding(.vertical, SageSpacing.small)
    }
} 