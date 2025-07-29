import SwiftUI

struct SageButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: {
            print("SageButton: Button tapped with title=\(title)")
            action()
        }) {
            Text(title)
                .font(SageTypography.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(SageColors.sageTeal)
                .cornerRadius(12)
        }
        .padding(.horizontal, SageSpacing.medium)
    }
}

struct SageFloatingActionButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: {
            print("SageFloatingActionButton: + tapped")
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: SageSpacing.xlarge * 1.5, height: SageSpacing.xlarge * 1.5)
                .background(SageColors.sageTeal)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Start new voice session")
        .accessibilityAddTraits(.isButton)
    }
} 