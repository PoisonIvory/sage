import Foundation

// MARK: - Core Domain Models for Vocal Analysis

/// Domain model representing fundamental frequency analysis
/// GWT: Given clinical voice analysis requirements
/// GWT: When modeling F0 biomarkers for menstrual cycle tracking  
/// GWT: Then F0Analysis represents clinical concepts accurately
public struct F0Analysis: Equatable, Codable {
    public let mean: Double        // Hz - fundamental frequency mean
    public let std: Double         // Hz - fundamental frequency standard deviation  
    public let confidence: Double  // % - voiced frame ratio (0-100)
    
    public init(mean: Double, std: Double, confidence: Double) {
        self.mean = mean
        self.std = std
        self.confidence = confidence
    }
    
    /// Validate F0 values against clinical ranges for adult females
    /// Research: Adult Female F0: 165-265 Hz (speaking), 175-400 Hz (sustained vowels)
    public func isWithinClinicalRange(for demographic: VoiceDemographic) -> Bool {
        switch demographic {
        case .adultFemale:
            return mean >= 165.0 && mean <= 400.0 && confidence >= 50.0
        case .adultMale:
            return mean >= 85.0 && mean <= 250.0 && confidence >= 50.0
        case .unknown:
            return mean >= 75.0 && mean <= 500.0 && confidence >= 30.0
        }
    }
    
    /// Clinical interpretation of F0 stability for PMDD/PCOS tracking
    public var stabilityAssessment: F0StabilityLevel {
        guard confidence >= 70.0 else { return .unreliable }
        
        if std <= 10.0 {
            return .excellent
        } else if std <= 20.0 {
            return .good  
        } else if std <= 35.0 {
            return .moderate
        } else {
            return .poor
        }
    }
}

/// Domain model for voice quality perturbation analysis
/// GWT: Given research-grade jitter and shimmer requirements
/// GWT: When modeling voice quality biomarkers
/// GWT: Then VoiceQualityAnalysis follows clinical standards
public struct VoiceQualityAnalysis: Equatable, Codable {
    public let jitter: JitterMeasures
    public let shimmer: ShimmerMeasures  
    public let hnr: HNRAnalysis
    
    public init(jitter: JitterMeasures, shimmer: ShimmerMeasures, hnr: HNRAnalysis) {
        self.jitter = jitter
        self.shimmer = shimmer
        self.hnr = hnr
    }
    
    /// Overall voice quality assessment based on clinical thresholds
    public var qualityLevel: VoiceQualityLevel {
        let jitterLevel = jitter.clinicalAssessment
        let shimmerLevel = shimmer.clinicalAssessment
        let hnrLevel = hnr.clinicalAssessment
        
        // Conservative assessment - worst component determines overall quality
        let levels = [jitterLevel, shimmerLevel, hnrLevel]
        if levels.contains(.pathological) { return .pathological }
        if levels.contains(.poor) { return .poor }
        if levels.contains(.moderate) { return .moderate }
        if levels.contains(.good) { return .good }
        return .excellent
    }
}

/// Research-grade jitter measurements following clinical standards
/// Reference: Titze, I. R. (1995). Workshop on Acoustic Voice Analysis
public struct JitterMeasures: Equatable, Codable {
    public let local: Double      // % - local period perturbation
    public let absolute: Double   // µs - absolute period variation
    public let rap: Double        // % - relative average perturbation  
    public let ppq5: Double       // % - 5-point period perturbation quotient
    
    public init(local: Double, absolute: Double, rap: Double, ppq5: Double) {
        self.local = local
        self.absolute = absolute
        self.rap = rap
        self.ppq5 = ppq5
    }
    
    /// Clinical assessment based on research thresholds
    /// Research: Jitter <1.04% excellent, <2% good, >5% pathological (Farrús et al., 2007)
    public var clinicalAssessment: VoiceQualityLevel {
        if local < 1.04 && rap < 1.0 {
            return .excellent
        } else if local < 2.0 && rap < 1.5 {
            return .good
        } else if local < 5.0 && rap < 3.0 {
            return .moderate
        } else if local < 8.0 && rap < 5.0 {
            return .poor
        } else {
            return .pathological
        }
    }
}

/// Research-grade shimmer measurements following clinical standards
public struct ShimmerMeasures: Equatable, Codable {
    public let local: Double      // % - local amplitude perturbation
    public let db: Double         // dB - amplitude perturbation in dB
    public let apq3: Double       // % - 3-point amplitude perturbation quotient
    public let apq5: Double       // % - 5-point amplitude perturbation quotient
    
    public init(local: Double, db: Double, apq3: Double, apq5: Double) {
        self.local = local
        self.db = db
        self.apq3 = apq3
        self.apq5 = apq5
    }
    
    /// Clinical assessment based on research thresholds  
    /// Research: Shimmer <3.81% excellent, <6% good, >10% pathological (Farrús et al., 2007)
    public var clinicalAssessment: VoiceQualityLevel {
        if local < 3.81 && apq3 < 3.0 {
            return .excellent
        } else if local < 6.0 && apq3 < 5.0 {
            return .good
        } else if local < 10.0 && apq3 < 8.0 {
            return .moderate
        } else if local < 15.0 && apq3 < 12.0 {
            return .poor
        } else {
            return .pathological
        }
    }
}

/// Harmonics-to-Noise Ratio analysis for voice breathiness assessment
public struct HNRAnalysis: Equatable, Codable {
    public let mean: Double       // dB - average HNR
    public let std: Double        // dB - HNR variability
    
    public init(mean: Double, std: Double) {
        self.mean = mean
        self.std = std
    }
    
    /// Clinical assessment based on research thresholds
    /// Research: HNR >20dB excellent, >15dB good, <10dB poor
    public var clinicalAssessment: VoiceQualityLevel {
        if mean >= 20.0 {
            return .excellent
        } else if mean >= 15.0 {
            return .good
        } else if mean >= 10.0 {
            return .moderate
        } else if mean >= 7.0 {
            return .poor
        } else {
            return .pathological
        }
    }
}

/// Composite vocal stability score for app UX and clinical interpretation
/// GWT: Given need for user-friendly voice quality metric
/// GWT: When combining clinical measures into single score
/// GWT: Then VocalStabilityScore provides meaningful 0-100 rating
public struct VocalStabilityScore: Equatable, Codable {
    public let score: Double      // 0-100 - composite stability rating
    public let components: StabilityComponents
    
    public init(score: Double, components: StabilityComponents) {
        self.score = score
        self.components = components  
    }
    
    /// User-friendly interpretation of stability score
    public var interpretation: StabilityInterpretation {
        if score >= 85.0 {
            return .excellent
        } else if score >= 70.0 {
            return .good
        } else if score >= 50.0 {
            return .moderate
        } else if score >= 30.0 {
            return .poor
        } else {
            return .unreliable
        }
    }
}

/// Components contributing to stability score calculation
public struct StabilityComponents: Equatable, Codable {
    public let f0Score: Double        // F0 confidence contribution (40% weight)
    public let jitterScore: Double    // Jitter assessment contribution (20% weight)
    public let shimmerScore: Double   // Shimmer assessment contribution (20% weight)
    public let hnrScore: Double       // HNR assessment contribution (20% weight)
    
    public init(f0Score: Double, jitterScore: Double, shimmerScore: Double, hnrScore: Double) {
        self.f0Score = f0Score
        self.jitterScore = jitterScore
        self.shimmerScore = shimmerScore
        self.hnrScore = hnrScore
    }
}

/// Complete vocal biomarkers for menstrual cycle tracking
/// GWT: Given comprehensive voice analysis pipeline
/// GWT: When modeling complete vocal assessment
/// GWT: Then VocalBiomarkers captures all clinical measures
public struct VocalBiomarkers: Equatable, Codable {
    public let f0: F0Analysis
    public let voiceQuality: VoiceQualityAnalysis
    public let stability: VocalStabilityScore
    public let metadata: VoiceAnalysisMetadata
    
    public init(f0: F0Analysis, voiceQuality: VoiceQualityAnalysis, stability: VocalStabilityScore, metadata: VoiceAnalysisMetadata) {
        self.f0 = f0
        self.voiceQuality = voiceQuality
        self.stability = stability
        self.metadata = metadata
    }
    
    /// Overall clinical assessment for PMDD/PCOS screening
    public var clinicalSummary: ClinicalVoiceAssessment {
        return ClinicalVoiceAssessment(
            overallQuality: voiceQuality.qualityLevel,
            f0Stability: f0.stabilityAssessment,
            stabilityScore: stability.interpretation,
            recommendedAction: determineRecommendedAction()
        )
    }
    
    private func determineRecommendedAction() -> ClinicalRecommendation {
        let qualityLevel = voiceQuality.qualityLevel
        let stabilityLevel = stability.interpretation
        
        if qualityLevel == .pathological || stabilityLevel == .unreliable {
            return .consultSpecialist
        } else if qualityLevel == .poor || stabilityLevel == .poor {
            return .monitorClosely
        } else if qualityLevel == .moderate || stabilityLevel == .moderate {
            return .trackTrends
        } else {
            return .continueTracking
        }
    }
}

/// Analysis metadata for quality assurance and debugging
public struct VoiceAnalysisMetadata: Equatable, Codable {
    public let recordingDuration: Double     // seconds
    public let sampleRate: Double           // Hz
    public let voicedRatio: Double          // 0.0-1.0 - fraction of voiced frames
    public let analysisTimestamp: Date
    public let analysisSource: AnalysisSource
    
    public init(recordingDuration: Double, sampleRate: Double, voicedRatio: Double, analysisTimestamp: Date, analysisSource: AnalysisSource) {
        self.recordingDuration = recordingDuration
        self.sampleRate = sampleRate
        self.voicedRatio = voicedRatio
        self.analysisTimestamp = analysisTimestamp
        self.analysisSource = analysisSource
    }
}

// MARK: - Supporting Enums and Types

public enum VoiceDemographic: String, Codable, CaseIterable {
    case adultFemale = "adult_female"
    case adultMale = "adult_male"  
    case unknown = "unknown"
}

public enum F0StabilityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    case unreliable = "unreliable"
}

public enum VoiceQualityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    case pathological = "pathological"
}

public enum StabilityInterpretation: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    case unreliable = "unreliable"
}

public enum AnalysisSource: String, Codable, CaseIterable {
    case localIOS = "local_ios"
    case cloudParselmouth = "cloud_parselmouth"
    case hybrid = "hybrid"
}

public enum ClinicalRecommendation: String, Codable, CaseIterable {
    case continueTracking = "continue_tracking"
    case trackTrends = "track_trends"
    case monitorClosely = "monitor_closely"
    case consultSpecialist = "consult_specialist"
}

/// Clinical voice assessment summary for PMDD/PCOS screening
public struct ClinicalVoiceAssessment: Equatable, Codable {
    public let overallQuality: VoiceQualityLevel
    public let f0Stability: F0StabilityLevel
    public let stabilityScore: StabilityInterpretation
    public let recommendedAction: ClinicalRecommendation
    
    public init(overallQuality: VoiceQualityLevel, f0Stability: F0StabilityLevel, stabilityScore: StabilityInterpretation, recommendedAction: ClinicalRecommendation) {
        self.overallQuality = overallQuality
        self.f0Stability = f0Stability
        self.stabilityScore = stabilityScore
        self.recommendedAction = recommendedAction
    }
}