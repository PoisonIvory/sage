import SwiftUI

struct HomeView: View {
    // TODO: This will be replaced with actual F0 data from speech analysis pipeline
    @State private var f0Value: String = "210 Hz"
    
    var body: some View {
        VStack(spacing: SageSpacing.xLarge) {
            Spacer()
            
            SageCard {
                VStack(spacing: SageSpacing.medium) {
                    Text("Your F0")
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.espressoBrown)
                    
                    Text(f0Value)
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.sageTeal)
                }
            }
            .frame(maxWidth: 300)
            
            Spacer()
        }
        .padding(.horizontal, SageSpacing.xLarge)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            print("HomeView: appeared")
        }
    }
}

#Preview {
    HomeView()
} 