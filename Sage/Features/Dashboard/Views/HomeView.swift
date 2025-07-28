import SwiftUI

struct HomeView: View {
    @StateObject private var f0DataService = F0DataService()
    
    var body: some View {
        ZStack {
            sageBackground
            f0DisplayCard
        }
        .onAppear {
            print("HomeView: appeared")
            Task {
                await f0DataService.fetchF0Data()
            }
        }
        .onDisappear {
            f0DataService.stopListening()
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
                f0ValueContent
                f0ConfidenceContent
            }
        }
        .frame(maxWidth: 300)
    }
    
    private var f0Label: some View {
        Text("Your F0")
            .font(SageTypography.headline)
            .foregroundColor(SageColors.espressoBrown)
    }
    
    private var f0ValueContent: some View {
        Group {
            if f0DataService.isLoading {
                SageProgressView()
                    .scaleEffect(0.8)
            } else if f0DataService.errorMessage != nil {
                Text("Analysis pending...")
                    .font(SageTypography.title)
                    .foregroundColor(SageColors.softTaupe)
            } else {
                Text(f0DataService.displayF0Value)
                    .font(SageTypography.title)
                    .foregroundColor(SageColors.sageTeal)
            }
        }
    }
    
    private var f0ConfidenceContent: some View {
        Group {
            if !f0DataService.isLoading && f0DataService.errorMessage == nil && f0DataService.f0Confidence > 0 {
                Text("\(Int(f0DataService.f0Confidence))% confidence")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.earthClay)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    HomeView()
} 