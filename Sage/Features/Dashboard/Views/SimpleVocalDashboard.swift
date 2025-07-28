import SwiftUI

/// Simplified vocal analysis dashboard for MVP testing
/// GWT: Given user views dashboard after voice recording
/// GWT: When SimpleVocalDashboard displays mock data temporarily
/// GWT: Then UI shows expected layout and components for testing
struct SimpleVocalDashboard: View {
    @State private var isAnalyzing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: SageSpacing.xLarge) {
                dashboardHeader
                
                if isAnalyzing {
                    analysisInProgressCard
                } else {
                    mockAnalysisCards
                }
            }
            .padding([.horizontal, .top], SageSpacing.xLarge)
            .padding(.bottom, 60)
        }
        .background(sageBackground)
        .navigationTitle("Voice Analysis")
        .onAppear {
            // Simulate analysis flow for testing
            simulateAnalysis()
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
    
    private var dashboardHeader: some View {
        VStack(spacing: SageSpacing.small) {
            Text("Your Voice Analysis")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
            
            Text(isAnalyzing ? "Processing voice patterns..." : "Analysis complete")
                .font(SageTypography.body)
                .foregroundColor(SageColors.earthClay)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, SageSpacing.medium)
    }
    
    private var analysisInProgressCard: some View {
        SageStylizedCard(background: SageColors.sandstone) {
            VStack(spacing: SageSpacing.medium) {
                SageProgressView()
                    .scaleEffect(0.8)
                
                Text("Analyzing Voice Patterns")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.sageTeal)
                
                Text("Processing F0, jitter, shimmer, and HNR measurements...")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.earthClay)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var mockAnalysisCards: some View {
        VStack(spacing: SageSpacing.medium) {
            // Mock Vocal Stability Card
            mockVocalStabilityCard
            
            // Mock Voice Quality Card
            mockVoiceQualityCard
            
            // Mock Clinical Assessment Card
            mockClinicalAssessmentCard
        }
    }
    
    private var mockVocalStabilityCard: some View {
        SageStylizedCard(background: SageColors.sandstone) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Voice Stability")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.sageTeal)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("82.5")
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.espressoBrown)
                    Text("/100")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                }
                
                SagePercentileBar(
                    value: 0.825,
                    accent: SageColors.sageTeal,
                    background: SageColors.fogWhite,
                    label: "Stability Score",
                    percentile: 0.825
                )
                
                // Mock F0 Analysis
                VStack(alignment: .leading, spacing: SageSpacing.small) {
                    Text("Fundamental Frequency Analysis")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.espressoBrown)
                    
                    HStack(spacing: SageSpacing.medium) {
                        VStack(alignment: .leading) {
                            Text("Mean F0")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("220.5 Hz")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Variability")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("15.2 Hz")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Confidence")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("88%")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                    }
                }
                
                Text("Excellent voice stability with consistent F0 patterns. This may indicate balanced hormonal states suitable for baseline tracking.")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.cinnamonBark)
                    .italic()
            }
        }
    }
    
    private var mockVoiceQualityCard: some View {
        SageStylizedCard(background: SageColors.fogWhite) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Voice Quality Analysis (Research-Grade)")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.coralBlush)
                
                // Mock Jitter Measurements
                mockVoiceQualitySection(
                    title: "Jitter (Frequency Perturbation)",
                    measurements: [
                        ("Local", "0.824%"),
                        ("RAP", "0.756%"),
                        ("PPQ5", "0.891%")
                    ],
                    assessment: "Excellent",
                    color: SageColors.sageTeal
                )
                
                SageDivider()
                
                // Mock Shimmer Measurements
                mockVoiceQualitySection(
                    title: "Shimmer (Amplitude Perturbation)",
                    measurements: [
                        ("Local", "3.245%"),
                        ("APQ3", "2.876%"),
                        ("APQ5", "3.521%")
                    ],
                    assessment: "Good",
                    color: SageColors.coralBlush
                )
                
                SageDivider()
                
                // Mock HNR Analysis
                mockVoiceQualitySection(
                    title: "Harmonics-to-Noise Ratio",
                    measurements: [
                        ("Mean", "19.2 dB"),
                        ("Std Dev", "2.1 dB")
                    ],
                    assessment: "Good",
                    color: SageColors.cinnamonBark
                )
                
                Text("Clinical thresholds: Jitter <1.04% excellent, Shimmer <3.81% excellent, HNR >20dB excellent")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.earthClay)
                    .italic()
            }
        }
    }
    
    private func mockVoiceQualitySection(
        title: String,
        measurements: [(String, String)],
        assessment: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: SageSpacing.small) {
            HStack {
                Text(title)
                    .font(SageTypography.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(assessment)
                    .font(SageTypography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(6)
            }
            
            HStack(spacing: SageSpacing.medium) {
                ForEach(measurements, id: \.0) { measurement in
                    VStack(alignment: .leading) {
                        Text(measurement.0)
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        Text(measurement.1)
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.espressoBrown)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var mockClinicalAssessmentCard: some View {
        SageStylizedCard(background: SageColors.fogWhite) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Clinical Assessment")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                
                HStack {
                    VStack(alignment: .leading, spacing: SageSpacing.small) {
                        Text("Overall Quality")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        
                        Text("Good")
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.sageTeal)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: SageSpacing.small) {
                        Text("Analysis Source")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        
                        Text("Cloud Parselmouth")
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.espressoBrown)
                    }
                }
                
                Text("Voice quality is within normal ranges. Continue regular tracking to establish your personal baseline patterns for cycle correlation.")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.espressoBrown)
                    .padding(.top, SageSpacing.small)
                
                HStack {
                    Text("Voiced Ratio: 88.5%")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.earthClay)
                    
                    Spacer()
                    
                    Text("Duration: 3.2s")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.earthClay)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateAnalysis() {
        isAnalyzing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isAnalyzing = false
        }
    }
}

#Preview {
    NavigationView {
        SimpleVocalDashboard()
    }
}