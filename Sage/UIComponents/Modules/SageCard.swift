import SwiftUI

struct SageCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        print("SageCard: initialized")
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: SageSpacing.medium) {
            content
        }
        .padding()
        .background(SageColors.fogWhite)
        .cornerRadius(16)
        .shadow(color: SageColors.earthClay.opacity(0.08), radius: 8, x: 0, y: 2)
    }
} 