import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

// Note: This is the comprehensive voice analysis content moved from VoiceDashboardView
// The Dashboard tab will be a placeholder for future longitudinal data

struct HomeView: View {
    @StateObject private var analysisService = HybridVocalAnalysisService()
    @State private var currentBiomarkers: VocalBiomarkers?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: SageSpacing.xLarge) {
                homeHeader
                Spacer(minLength: 0)
                if analysisService.currentState.isAnalyzing {
                    analysisInProgressSection
                } else if let biomarkers = currentBiomarkers {
                    realDataAnalysisCards(biomarkers: biomarkers)
                } else {
                    noDataAvailableSection
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, SageSpacing.large)
            .padding(.top, SageSpacing.xLarge)
            .padding(.bottom, 24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .background(sageBackground)
        .onAppear {
            setupRealTimeSubscription()
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
    
    private var homeHeader: some View {
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
    
    /// Analysis in progress section
    private var analysisInProgressSection: some View {
        VStack(spacing: SageSpacing.medium) {
            SageStylizedCard(background: SageColors.sandstone) {
                VStack(spacing: SageSpacing.medium) {
                    SageProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Real-Time Voice Analysis")
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.sageTeal)
                    
                    if case .localComplete(let metrics) = analysisService.currentState {
                        VStack(spacing: SageSpacing.small) {
                            Text("Local Analysis Complete")
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.espressoBrown)
                            
                            HStack(spacing: SageSpacing.medium) {
                                VStack {
                                    Text("F0 Mean")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.earthClay)
                                    Text("\(String(format: "%.1f", metrics.f0Mean)) Hz")
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.espressoBrown)
                                }
                                
                                VStack {
                                    Text("Confidence")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.earthClay)
                                    Text("\(Int(metrics.confidence))%")
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.espressoBrown)
                                }
                            }
                            
                            Text("Comprehensive analysis in progress...")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                                .italic()
                        }
                    }
                }
            }
        }
    }
    
    /// No data available section
    private var noDataAvailableSection: some View {
        HStack {
            Spacer(minLength: 0)
            SageStylizedCard(background: SageColors.fogWhite) {
                VStack(spacing: SageSpacing.medium) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundColor(SageColors.sageTeal)
                    Text("No Recent Analysis")
                        .font(SageTypography.headline)
                        .foregroundColor(SageColors.espressoBrown)
                    Text("Record your voice to see real-time vocal biomarker analysis including F0, jitter, shimmer, and HNR measurements.")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: 400)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
    
    /// Real data analysis cards
    private func realDataAnalysisCards(biomarkers: VocalBiomarkers) -> some View {
        VStack(spacing: SageSpacing.medium) {
            // Real Vocal Stability Card
            realVocalStabilityCard(stability: biomarkers.stability, f0: biomarkers.f0)
            
            // Real Voice Quality Card (Jitter, Shimmer, HNR)
            realVoiceQualityCard(voiceQuality: biomarkers.voiceQuality)
            
            // Clinical Assessment Card (Real recommendations)
            realClinicalAssessmentCard(assessment: biomarkers.clinicalSummary, metadata: biomarkers.metadata)
        }
    }
    
    /// Real vocal stability card with actual stability score and F0 data
    private func realVocalStabilityCard(stability: VocalStabilityScore, f0: F0Analysis) -> some View {
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
                    label: "Stability Score",
                    percentile: stability.score / 100
                )
                
                // Real F0 Analysis
                VStack(alignment: .leading, spacing: SageSpacing.small) {
                    Text("Fundamental Frequency Analysis")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.espressoBrown)
                    
                    HStack(spacing: SageSpacing.medium) {
                        VStack(alignment: .leading) {
                            Text("Mean F0")
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
                
                Text(realStabilityInsight(for: stability.interpretation, f0Stability: f0.stabilityAssessment))
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.cinnamonBark)
                    .italic()
            }
        }
    }
    
    /// Real voice quality card with actual jitter, shimmer, and HNR data
    private func realVoiceQualityCard(voiceQuality: VoiceQualityAnalysis) -> some View {
        SageStylizedCard(background: SageColors.fogWhite) {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                Text("Voice Quality Analysis")
                    .font(SageTypography.headline)
                    .foregroundColor(SageColors.coralBlush)
                
                // Real Jitter Measurements
                realVoiceQualitySection(
                    title: "Jitter (Frequency Perturbation)",
                    measurements: [
                        ("Local", "\(String(format: "%.3f", voiceQuality.jitter.local))%"),
                        ("RAP", "\(String(format: "%.3f", voiceQuality.jitter.rap))%"),
                        ("PPQ5", "\(String(format: "%.3f", voiceQuality.jitter.ppq5))%")
                    ],
                    assessment: voiceQuality.jitter.clinicalAssessment,
                    color: SageColors.sageTeal
                )
                
                SageDivider()
                
                // Real Shimmer Measurements
                realVoiceQualitySection(
                    title: "Shimmer (Amplitude Perturbation)",
                    measurements: [
                        ("Local", "\(String(format: "%.3f", voiceQuality.shimmer.local))%"),
                        ("APQ3", "\(String(format: "%.3f", voiceQuality.shimmer.apq3))%"),
                        ("APQ5", "\(String(format: "%.3f", voiceQuality.shimmer.apq5))%")
                    ],
                    assessment: voiceQuality.shimmer.clinicalAssessment,
                    color: SageColors.coralBlush
                )
                
                SageDivider()
                
                // Real HNR Analysis
                realVoiceQualitySection(
                    title: "Harmonics-to-Noise Ratio",
                    measurements: [
                        ("Mean", "\(String(format: "%.1f", voiceQuality.hnr.mean)) dB"),
                        ("Std Dev", "\(String(format: "%.1f", voiceQuality.hnr.std)) dB")
                    ],
                    assessment: voiceQuality.hnr.clinicalAssessment,
                    color: SageColors.cinnamonBark
                )
                
                Text("Clinical thresholds: Jitter <1.04% excellent, Shimmer <3.81% excellent, HNR >20dB excellent")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.earthClay)
                    .italic()
            }
        }
    }
    
    /// Helper for real voice quality sections
    private func realVoiceQualitySection(
        title: String,
        measurements: [(String, String)],
        assessment: VoiceQualityLevel,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: SageSpacing.small) {
            HStack {
                Text(title)
                    .font(SageTypography.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                // Real clinical assessment badge
                Text(assessment.rawValue.capitalized)
                    .font(SageTypography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForAssessment(assessment).opacity(0.2))
                    .foregroundColor(colorForAssessment(assessment))
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
    
    /// Real clinical assessment card with actual recommendations
    private func realClinicalAssessmentCard(assessment: ClinicalVoiceAssessment, metadata: VoiceAnalysisMetadata) -> some View {
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
                        
                        Text(assessment.overallQuality.rawValue.capitalized)
                            .font(SageTypography.body)
                            .foregroundColor(colorForAssessment(assessment.overallQuality))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: SageSpacing.small) {
                        Text("Analysis Source")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.earthClay)
                        
                        Text(metadata.analysisSource.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.espressoBrown)
                    }
                }
                
                Text(realRecommendationText(for: assessment.recommendedAction, overallQuality: assessment.overallQuality))
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.espressoBrown)
                    .padding(.top, SageSpacing.small)
                
                // Real metadata display
                HStack {
                    Text("Voiced Ratio: \(String(format: "%.1f", metadata.voicedRatio * 100))%")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.earthClay)
                    
                    Spacer()
                    
                    Text("Duration: \(String(format: "%.1f", metadata.recordingDuration))s")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.earthClay)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupRealTimeSubscription() {
        // Query for the most recent voice analysis result
        Task {
            await queryMostRecentAnalysis()
        }
        
        // Also listen to the ongoing analysis service for real-time updates
        let resultsStream = analysisService.subscribeToResults()
        
        Task {
            for await biomarkers in resultsStream {
                await MainActor.run {
                    currentBiomarkers = biomarkers
                }
            }
        }
    }
    
    private func queryMostRecentAnalysis() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let firestore = Firestore.firestore()
        let query = firestore
            .collection("users")
            .document(userId)
            .collection("voice_analyses")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
        
        do {
            let snapshot = try await query.getDocuments()
            guard let document = snapshot.documents.first else {
                return
            }
            let data = document.data()
            
            // Parse the most recent analysis result
            if let biomarkers = parseVocalBiomarkers(from: data) {
                await MainActor.run {
                    currentBiomarkers = biomarkers
                }
            }
        } catch {
            print("Error querying most recent analysis: \(error)")
        }
    }
    
    // Helper method to parse VocalBiomarkers (extracted from VocalResultsListener)
    private func parseVocalBiomarkers(from data: [String: Any]) -> VocalBiomarkers? {
        // Extract vocal analysis features from Firestore document
        guard let f0Mean = data["vocal_analysis_f0_mean"] as? Double,
              let f0Std = data["vocal_analysis_f0_std"] as? Double,
              let f0Confidence = data["vocal_analysis_f0_confidence"] as? Double,
              let jitterLocal = data["vocal_analysis_jitter_local"] as? Double,
              let jitterAbsolute = data["vocal_analysis_jitter_absolute"] as? Double,
              let jitterRap = data["vocal_analysis_jitter_rap"] as? Double,
              let jitterPpq5 = data["vocal_analysis_jitter_ppq5"] as? Double,
              let shimmerLocal = data["vocal_analysis_shimmer_local"] as? Double,
              let shimmerDb = data["vocal_analysis_shimmer_db"] as? Double,
              let shimmerApq3 = data["vocal_analysis_shimmer_apq3"] as? Double,
              let shimmerApq5 = data["vocal_analysis_shimmer_apq5"] as? Double,
              let hnrMean = data["vocal_analysis_hnr_mean"] as? Double,
              let hnrStd = data["vocal_analysis_hnr_std"] as? Double,
              let stabilityScore = data["vocal_analysis_vocal_stability_score"] as? Double else {
            return nil
        }
        
        // Construct domain models
        let f0Analysis = F0Analysis(mean: f0Mean, std: f0Std, confidence: f0Confidence)
        
        let jitterMeasures = JitterMeasures(
            local: jitterLocal,
            absolute: jitterAbsolute,
            rap: jitterRap,
            ppq5: jitterPpq5
        )
        
        let shimmerMeasures = ShimmerMeasures(
            local: shimmerLocal,
            db: shimmerDb,
            apq3: shimmerApq3,
            apq5: shimmerApq5
        )
        
        let hnrAnalysis = HNRAnalysis(mean: hnrMean, std: hnrStd)
        
        let voiceQuality = VoiceQualityAnalysis(
            jitter: jitterMeasures,
            shimmer: shimmerMeasures,
            hnr: hnrAnalysis
        )
        
        let stabilityComponents = StabilityComponents(
            f0Score: f0Confidence * 0.4,
            jitterScore: max(0, 100 - jitterLocal * 20) * 0.2,
            shimmerScore: max(0, 100 - shimmerLocal * 10) * 0.2,
            hnrScore: min(100, hnrMean * 5) * 0.2
        )
        
        let stability = VocalStabilityScore(score: stabilityScore, components: stabilityComponents)
        
        let metadata = VoiceAnalysisMetadata(
            recordingDuration: data["vocal_analysis_metadata_duration"] as? Double ?? 0.0,
            sampleRate: data["vocal_analysis_metadata_sample_rate"] as? Double ?? 48000.0,
            voicedRatio: data["vocal_analysis_metadata_voiced_ratio"] as? Double ?? 0.0,
            analysisTimestamp: Date(),
            analysisSource: .cloudParselmouth
        )
        
        return VocalBiomarkers(
            f0: f0Analysis,
            voiceQuality: voiceQuality,
            stability: stability,
            metadata: metadata
        )
    }
    
    private func colorForAssessment(_ assessment: VoiceQualityLevel) -> Color {
        switch assessment {
        case .excellent, .good:
            return SageColors.sageTeal
        case .moderate:
            return SageColors.coralBlush
        case .poor, .pathological:
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
    
    private func realStabilityInsight(for interpretation: StabilityInterpretation, f0Stability: F0StabilityLevel) -> String {
        switch (interpretation, f0Stability) {
        case (.excellent, .excellent):
            return "Excellent voice stability with consistent F0 patterns. This may indicate balanced hormonal states suitable for baseline tracking."
        case (.good, .good):
            return "Good voice stability with minor F0 variations typical of natural hormonal fluctuations. Continue regular tracking."
        case (.moderate, .moderate):
            return "Moderate voice stability with some F0 variation. Consider tracking patterns across multiple cycle phases."
        case (.poor, _), (_, .poor):
            return "Increased voice variability detected. Monitor closely and consider environmental factors or cycle timing."
        case (.unreliable, _), (_, .unreliable):
            return "Voice analysis quality was limited. Ensure quiet recording environment and sustained vowel production for optimal results."
        default:
            return "Voice patterns analyzed. Continue tracking to establish personal baseline and identify cycle correlations."
        }
    }
    
    private func realRecommendationText(for recommendation: ClinicalRecommendation, overallQuality: VoiceQualityLevel) -> String {
        switch (recommendation, overallQuality) {
        case (.continueTracking, .excellent), (.continueTracking, .good):
            return "Voice quality is within normal ranges. Continue regular tracking to establish your personal baseline patterns for cycle correlation."
        case (.trackTrends, _):
            return "Track voice patterns over multiple cycles to identify potential correlations with PMDD/PCOS symptoms and hormonal fluctuations."
        case (.monitorClosely, .moderate):
            return "Voice shows some variation from optimal ranges. Monitor closely and consider discussing patterns with healthcare provider if persistent."
        case (.monitorClosely, .poor):
            return "Voice quality indicates increased perturbation. Monitor trends carefully and consider environmental factors affecting recording quality."
        case (.consultSpecialist, .pathological):
            return "Voice analysis indicates patterns that may warrant professional evaluation. Consider consulting with healthcare provider about voice-hormone relationships."
        case (.consultSpecialist, _):
            return "Voice patterns suggest potential clinical significance. Discuss findings with healthcare provider familiar with hormonal voice changes."
        default:
            return "Continue voice tracking as part of your comprehensive PMDD/PCOS monitoring approach."
        }
    }
}

// MARK: - Supporting UI Components (moved from VoiceDashboardView)

/// Percentile Bar component
struct SagePercentileBar: View {
    let value: Double // 0-1
    let accent: Color
    let background: Color
    let label: String
    let percentile: Double // 0-1
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.espressoBrown)
                Spacer()
                Text("\(Int(percentile * 100))th %ile")
                    .font(SageTypography.caption)
                    .foregroundColor(accent)
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(background)
                    .frame(height: 8)
                Capsule()
                    .fill(accent)
                    .frame(width: CGFloat(percentile) * 160, height: 8)
                    .animation(.easeOut(duration: 0.6), value: percentile)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Int(percentile * 100))th percentile")
    }
}

/// Stylized Card component
struct SageStylizedCard<Content: View>: View {
    let background: Color
    let shadow: Color
    let content: Content
    init(background: Color, shadow: Color = SageColors.earthClay.opacity(0.10), @ViewBuilder content: () -> Content) {
        self.background = background
        self.shadow = shadow
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: SageSpacing.medium) {
            content
        }
        .padding(SageSpacing.large)
        .background(background)
        .cornerRadius(20)
        .shadow(color: shadow, radius: 12, x: 0, y: 4)
    }
}

#Preview {
    HomeView()
} 