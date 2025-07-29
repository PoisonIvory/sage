import SwiftUI

struct SageCard<Content: View>: View {
    let content: Content
    let flags: FeatureFlags?
    
    init(flags: FeatureFlags? = nil, @ViewBuilder content: () -> Content) {
        print("SageCard: initialized")
        self.flags = flags
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: SageSpacing.medium(flags)) {
            content
        }
        .padding(SageSpacing.medium(flags))
        .background(SageColors.surface(flags))
        .cornerRadius(SageSpacing.cornerRadius(flags))
        .shadow(color: SageColors.earthClay.opacity(0.08), radius: 8, x: 0, y: 2)
    }
} 