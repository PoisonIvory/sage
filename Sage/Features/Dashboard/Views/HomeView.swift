import SwiftUI

struct HomeView: View {
    // TODO: This will be replaced with actual F0 data from speech analysis pipeline
    @State private var f0Value: String = "210 Hz"
    
    var body: some View {
        ZStack {
            sageBackground
            f0DisplayCard
        }
        .onAppear {
            print("HomeView: appeared")
        }
    }
    
    // MARK: - UI Components
    
    private var sageBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var f0DisplayCard: some View {
        VStack(spacing: SageSpacing.xLarge) {
            Spacer()
            f0Card
            Spacer()
        }
    }
    
    private var f0Card: some View {
        SageCard {
            VStack(spacing: SageSpacing.medium) {
                f0Label
                f0Value
            }
        }
        .frame(maxWidth: 300)
    }
    
    private var f0Label: some View {
        Text("Your F0")
            .font(SageTypography.headline)
            .foregroundColor(SageColors.espressoBrown)
    }
    
    private var f0Value: some View {
        Text(f0Value)
            .font(SageTypography.title)
            .foregroundColor(SageColors.sageTeal)
    }
}

#Preview {
    HomeView()
} 