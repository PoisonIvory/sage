import SwiftUI

struct SageProgressView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: SageColors.sageTeal))
            .scaleEffect(1.3)
            .padding(SageSpacing.medium)
            .background(SageColors.fogWhite)
            .clipShape(Circle())
            .shadow(color: SageColors.sandstone.opacity(0.2), radius: 6, x: 0, y: 2)
            .accessibilityLabel("Loading")
    }
}

struct SageProgressView_Previews: PreviewProvider {
    static var previews: some View {
        SageProgressView()
            .padding()
            .background(SageColors.sandstone)
            .previewLayout(.sizeThatFits)
    }
} 