import SwiftUI
import Combine

/// Comprehensive vocal analysis dashboard with real data integration
/// GWT: Given user views dashboard after voice recording
/// GWT: When VocalAnalysisDashboard displays results using HybridVocalAnalysisService
/// GWT: Then UI follows CoStar aesthetic with real clinical data (no mock data)
struct VocalAnalysisDashboard: View {
    @StateObject private var analysisService = HybridVocalAnalysisService()
    @State private var currentBiomarkers: VocalBiomarkers?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: SageSpacing.xLarge) {
                dashboardHeader
                
                if analysisService.currentState.isAnalyzing {
                    analysisInProgressCard
                } else if let biomarkers = currentBiomarkers {
                    comprehensiveAnalysisCards(biomarkers: biomarkers)
                } else {
                    noAnalysisCard
                }
            }
            .padding([.horizontal, .top], SageSpacing.xLarge)
            .padding(.bottom, 60)
        }
        .background(sageBackground)
        .navigationTitle("Voice Analysis")
        .onAppear {
            setupResultsSubscription()
        }
        .onDisappear {
            analysisService.stopListening()
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
            Text("Your Voice Today")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
            
            Text(analysisService.currentState.description)
                .font(SageTypography.body)
                .foregroundColor(SageColors.earthClay)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, SageSpacing.medium)
    }
    
    /// GWT: Given analysis is in progress (local or cloud)
    /// GWT: When displaying progress to user
    /// GWT: Then shows appropriate loading state with clinical context
    private var analysisInProgressCard: some View {
        SageStylizedCard(background: SageColors.sandstone) {
            VStack(spacing: SageSpacing.medium) {
                SageProgressView()
                    .scaleEffect(0.8)
                
                Text("Analyzing Voice Patterns")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.sageTeal)
                
                if case .localComplete(let metrics) = analysisService.currentState {
                    VStack(spacing: SageSpacing.small) {
                        Text("Initial F0: \(String(format: "%.1f", metrics.f0Mean)) Hz")
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.espressoBrown)
                        
                        Text("\(Int(metrics.confidence))% confidence")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        
                        Text("Comprehensive analysis in progress...")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                            .italic()
                    }
                }
            }
        }
    }
    
    /// GWT: Given no recent voice analysis available
    /// GWT: When user views dashboard without recordings
    /// GWT: Then shows guidance to record voice
    private var noAnalysisCard: some View {
        SageStylizedCard(background: SageColors.fogWhite) {
            VStack(spacing: SageSpacing.medium) {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 48))
                    .foregroundColor(SageColors.sageTeal)
                
                Text("No Voice Analysis")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                
                Text("Record your voice to see comprehensive vocal biomarker analysis including F0, voice quality, and stability metrics.")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.earthClay)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    /// GWT: Given comprehensive vocal analysis results available
    /// GWT: When displaying VocalBiomarkers to user
    /// GWT: Then shows research-grade features following UI_STANDARDS.md
    private func comprehensiveAnalysisCards(biomarkers: VocalBiomarkers) -> some View {
        VStack(spacing: SageSpacing.medium) {
            // Vocal Stability Overview Card
            vocalStabilityCard(stability: biomarkers.stability, f0: biomarkers.f0)
            
            // Voice Quality Details Card  
            voiceQualityCard(voiceQuality: biomarkers.voiceQuality)
            
            // Clinical Assessment Card
            clinicalAssessmentCard(assessment: biomarkers.clinicalSummary)
        }
    }
    
    /// GWT: Given vocal stability score and F0 analysis
    /// GWT: When displaying primary voice metrics
    /// GWT: Then shows composite stability score with F0 details
    private func vocalStabilityCard(stability: VocalStabilityScore, f0: F0Analysis) -> some View {
        SageStylizedCard(background: SageColors.sandstone) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Voice Stability")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.sageTeal)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", stability.score))
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.espressoBrown)
                    Text("/100")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                }
                
                SagePercentileBar(
                    value: stability.score / 100,
                    accent: SageColors.sageTeal,
                    background: SageColors.fogWhite,
                    label: "Stability",
                    percentile: stability.score / 100
                )
                
                // F0 Details
                VStack(alignment: .leading, spacing: SageSpacing.small) {
                    Text("Fundamental Frequency")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.espressoBrown)
                    
                    HStack(spacing: SageSpacing.medium) {
                        VStack(alignment: .leading) {
                            Text("Mean")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("\(String(format: "%.1f", f0.mean)) Hz")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Variability")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("\(String(format: "%.1f", f0.std)) Hz")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Confidence")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                            Text("\(Int(f0.confidence))%")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                        }
                    }
                }
                
                Text(stabilityInterpretationText(for: stability.interpretation))
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.cinnamonBark)
                    .italic()
            }
        }
    }
    
    /// GWT: Given voice quality analysis (jitter, shimmer, HNR)
    /// GWT: When displaying perturbation measures
    /// GWT: Then shows research-grade jitter/shimmer/HNR values
    private func voiceQualityCard(voiceQuality: VoiceQualityAnalysis) -> some View {
        SageStylizedCard(background: SageColors.fogWhite) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Voice Quality Analysis")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.coralBlush)
                
                // Jitter Measures
                voiceQualitySection(
                    title: "Jitter (Frequency Perturbation)",
                    measures: [
                        ("Local", "\(String(format: "%.2f", voiceQuality.jitter.local))%"),
                        ("RAP", "\(String(format: "%.2f", voiceQuality.jitter.rap))%"),
                        ("PPQ5", "\(String(format: "%.2f", voiceQuality.jitter.ppq5))%")
                    ],
                    assessment: voiceQuality.jitter.clinicalAssessment,
                    color: SageColors.sageTeal
                )
                
                SageDivider()
                
                // Shimmer Measures
                voiceQualitySection(
                    title: "Shimmer (Amplitude Perturbation)",
                    measures: [
                        ("Local", "\(String(format: "%.2f", voiceQuality.shimmer.local))%"),
                        ("APQ3", "\(String(format: "%.2f", voiceQuality.shimmer.apq3))%"),
                        ("APQ5", "\(String(format: "%.2f", voiceQuality.shimmer.apq5))%")
                    ],
                    assessment: voiceQuality.shimmer.clinicalAssessment,
                    color: SageColors.coralBlush
                )
                
                SageDivider()
                
                // HNR Analysis
                voiceQualitySection(
                    title: "Harmonics-to-Noise Ratio",
                    measures: [
                        ("Mean", "\(String(format: "%.1f", voiceQuality.hnr.mean)) dB"),
                        ("Std Dev", "\(String(format: "%.1f", voiceQuality.hnr.std)) dB")
                    ],
                    assessment: voiceQuality.hnr.clinicalAssessment,
                    color: SageColors.cinnamonBark
                )
            }
        }
    }
    
    /// Helper view for voice quality sections
    private func voiceQualitySection(
        title: String,
        measures: [(String, String)],
        assessment: VoiceQualityLevel,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: SageSpacing.small) {
            Text(title)
                .font(SageTypography.caption)
                .foregroundColor(color)
            
            HStack(spacing: SageSpacing.medium) {
                ForEach(measures, id: \.0) { measure in
                    VStack(alignment: .leading) {
                        Text(measure.0)
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        Text(measure.1)
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.espressoBrown)
                    }
                }
                
                Spacer()
                
                qualityLevelBadge(assessment)
            }
        }
    }
    
    /// GWT: Given clinical voice assessment for PMDD/PCOS screening
    /// GWT: When displaying clinical interpretation
    /// GWT: Then shows appropriate recommendation based on voice quality
    private func clinicalAssessmentCard(assessment: ClinicalVoiceAssessment) -> some View {
        SageStylizedCard(background: backgroundColorForRecommendation(assessment.recommendedAction)) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Clinical Assessment")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.espressoBrown)
                
                HStack {
                    VStack(alignment: .leading, spacing: SageSpacing.small) {
                        Text("Overall Quality")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        qualityLevelBadge(assessment.overallQuality)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: SageSpacing.small) {
                        Text("F0 Stability")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        stabilityLevelBadge(assessment.f0Stability)
                    }
                }
                
                Text(recommendationText(for: assessment.recommendedAction))
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.espressoBrown)
                    .padding(.top, SageSpacing.small)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupResultsSubscription() {
        let resultsStream = analysisService.subscribeToResults()
        
        Task {
            for await biomarkers in resultsStream {
                await MainActor.run {
                    currentBiomarkers = biomarkers
                }
            }
        }
    }
    
    private func qualityLevelBadge(_ level: VoiceQualityLevel) -> some View {
        Text(level.rawValue.capitalized)
            .font(SageTypography.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForQualityLevel(level).opacity(0.2))
            .foregroundColor(colorForQualityLevel(level))
            .cornerRadius(8)
    }
    
    private func stabilityLevelBadge(_ level: F0StabilityLevel) -> some View {
        Text(level.rawValue.capitalized)
            .font(SageTypography.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForStabilityLevel(level).opacity(0.2))
            .foregroundColor(colorForStabilityLevel(level))
            .cornerRadius(8)
    }
    
    private func colorForQualityLevel(_ level: VoiceQualityLevel) -> Color {
        switch level {
        case .excellent, .good:
            return SageColors.sageTeal
        case .moderate:
            return SageColors.coralBlush
        case .poor, .pathological:
            return SageColors.cinnamonBark
        }
    }
    
    private func colorForStabilityLevel(_ level: F0StabilityLevel) -> Color {
        switch level {
        case .excellent, .good:
            return SageColors.sageTeal
        case .moderate:
            return SageColors.coralBlush
        case .poor, .unreliable:
            return SageColors.cinnamonBark
        }
    }
    
    private func backgroundColorForRecommendation(_ recommendation: ClinicalRecommendation) -> Color {
        switch recommendation {
        case .continueTracking, .trackTrends:
            return SageColors.fogWhite
        case .monitorClosely:
            return SageColors.sandstone
        case .consultSpecialist:
            return SageColors.coralBlush.opacity(0.1)
        }
    }
    
    private func stabilityInterpretationText(for interpretation: StabilityInterpretation) -> String {
        switch interpretation {
        case .excellent:
            return "Your voice shows excellent stability with consistent patterns that may reflect balanced hormonal states."
        case .good:
            return "Your voice demonstrates good stability with minor variations typical of natural hormonal fluctuations."
        case .moderate:
            return "Your voice shows moderate stability with some variation that may correlate with cycle phases."
        case .poor:
            return "Your voice indicates increased variability that may be worth tracking alongside cycle patterns."
        case .unreliable:
            return "Voice analysis quality was limited. Consider recording in a quieter environment for better insights."
        }
    }
    
    private func recommendationText(for recommendation: ClinicalRecommendation) -> String {
        switch recommendation {
        case .continueTracking:
            return "Continue regular voice tracking to establish your personal baseline patterns."
        case .trackTrends:
            return "Track voice patterns over multiple cycles to identify potential correlations with symptoms."
        case .monitorClosely:
            return "Monitor voice changes closely and consider discussing patterns with a healthcare provider."
        case .consultSpecialist:
            return "Consider consulting with a healthcare provider about voice patterns and potential hormonal factors."
        }
    }
}

// MARK: - Supporting Views

#Preview {
    NavigationView {
        VocalAnalysisDashboard()
    }
}