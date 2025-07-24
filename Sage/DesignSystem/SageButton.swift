import SwiftUI

struct SageButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
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