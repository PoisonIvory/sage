import SwiftUI

struct SageSectionHeader: View {
    let title: String
    let flags: FeatureFlags?
    
    init(title: String, flags: FeatureFlags? = nil) {
        self.title = title
        self.flags = flags
        print("SageSectionHeader: initialized with title=\(title)")
    }
    
    var body: some View {
        Text(title)
            .font(SageTypography.sectionHeader(flags))
            .foregroundColor(SageColors.primary(flags))
            .padding(.vertical, SageSpacing.small(flags))
    }
} 