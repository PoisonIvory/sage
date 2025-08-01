//
//  VocalBaseline.swift
//  Sage
//
//  Domain model for vocal baseline establishment following DDD principles
//  AC-001: Record Initial Vocal Baseline  
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation

// MARK: - Vocal Baseline Aggregate Root

/// Domain aggregate representing a user's vocal baseline for voice tracking
/// GWT: Given user completes onboarding voice recording
/// GWT: When establishing personalized vocal baseline  
/// GWT: Then VocalBaseline serves as scientific anchor for trend analysis
public struct VocalBaseline: Equatable, Codable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public let userId: UUID
    public let establishedAt: Date
    public let biomarkers: VocalBiomarkers
    public let demographic: VoiceDemographic
    public let recordingContext: RecordingContext
    
    // MARK: - Baseline Management
    
    public let archivedBaseline: ArchivedBaseline?
    public let replacementHistory: [BaselineReplacement]
    public let validationStatus: BaselineValidationStatus
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        establishedAt: Date,
        biomarkers: VocalBiomarkers,
        demographic: VoiceDemographic,
        recordingContext: RecordingContext,
        archivedBaseline: ArchivedBaseline? = nil,
        replacementHistory: [BaselineReplacement] = []
    ) {
        self.id = id
        self.userId = userId
        self.establishedAt = establishedAt
        self.biomarkers = biomarkers
        self.demographic = demographic
        self.recordingContext = recordingContext
        self.archivedBaseline = archivedBaseline
        self.replacementHistory = replacementHistory
        self.validationStatus = Self.validateClinicalThresholds(biomarkers: biomarkers, demographic: demographic)
    }
    
    // MARK: - Clinical Validation (AC-001)
    
    /// Validates if baseline meets clinical standards for voice tracking
    public var isClinicallValid: Bool {
        switch validationStatus {
        case .accepted:
            return true
        case .rejected:
            return false
        }
    }
    
    /// Clinical quality assessment of baseline biomarkers
    public var clinicalQuality: VoiceQualityLevel {
        return biomarkers.voiceQuality.qualityLevel
    }
    
    /// Personalized clinical thresholds based on user's baseline
    public var personalizedThresholds: PersonalizedThresholds {
        return PersonalizedThresholds.fromBaseline(biomarkers, demographic: demographic)
    }
    
    private static func validateClinicalThresholds(biomarkers: VocalBiomarkers, demographic: VoiceDemographic) -> BaselineValidationStatus {
        // F0 confidence must meet minimum threshold
        guard biomarkers.f0.confidence >= 50.0 else {
            return .rejected(reason: "F0 confidence below clinical threshold")
        }
        
        // F0 must be within demographic range
        guard biomarkers.f0.isWithinClinicalRange(for: demographic) else {
            return .rejected(reason: "F0 outside expected demographic range")
        }
        
        // Recording must have sufficient voiced content
        guard biomarkers.metadata.voicedRatio >= 0.6 else {
            return .rejected(reason: "Insufficient voiced content for baseline")
        }
        
        // Recording duration must be adequate
        guard biomarkers.metadata.recordingDuration >= 3.0 else {
            return .rejected(reason: "Recording too short for reliable baseline")
        }
        
        return .accepted
    }
}

// MARK: - Supporting Types

/// Recording context for baseline establishment
public enum RecordingContext: String, CaseIterable, Codable {
    case onboarding = "onboarding"
    case followUp = "follow_up"
    case recalibration = "recalibration"
}

/// Baseline validation status
public enum BaselineValidationStatus: Equatable, Codable {
    case accepted
    case rejected(reason: String)
}

/// Archived baseline for replacement tracking
public struct ArchivedBaseline: Equatable, Codable {
    public let id: UUID
    public let originalBaselineId: UUID
    public let archivedAt: Date
    public let replacementReason: ReplacementReason
    
    public init(
        id: UUID = UUID(),
        originalBaselineId: UUID,
        archivedAt: Date,
        replacementReason: ReplacementReason
    ) {
        self.id = id
        self.originalBaselineId = originalBaselineId
        self.archivedAt = archivedAt
        self.replacementReason = replacementReason
    }
}

/// Baseline replacement tracking
public struct BaselineReplacement: Equatable, Codable {
    public let id: UUID
    public let replacedAt: Date
    public let reason: ReplacementReason
    public let previousBaselineId: UUID
    
    public init(
        id: UUID = UUID(),
        replacedAt: Date,
        reason: ReplacementReason,
        previousBaselineId: UUID
    ) {
        self.id = id
        self.replacedAt = replacedAt
        self.reason = reason
        self.previousBaselineId = previousBaselineId
    }
}

/// Reason for baseline replacement
public enum ReplacementReason: String, CaseIterable, Codable {
    case userRequested = "user_requested"
    case qualityImprovement = "quality_improvement"
    case technicalIssue = "technical_issue"
    case recalibration = "recalibration"
}

// MARK: - Public Threshold Types

/// Public jitter thresholds for personalized baseline assessment
public struct PersonalizedJitterThresholds: Equatable, Codable {
    public let maximumLocal: Double
    public let maximumRap: Double
    public let maximumPpq5: Double
    
    public init(maximumLocal: Double, maximumRap: Double, maximumPpq5: Double) {
        self.maximumLocal = maximumLocal
        self.maximumRap = maximumRap
        self.maximumPpq5 = maximumPpq5
    }
}

/// Public shimmer thresholds for personalized baseline assessment
public struct PersonalizedShimmerThresholds: Equatable, Codable {
    public let maximumLocal: Double
    public let maximumApq3: Double
    public let maximumApq5: Double
    
    public init(maximumLocal: Double, maximumApq3: Double, maximumApq5: Double) {
        self.maximumLocal = maximumLocal
        self.maximumApq3 = maximumApq3
        self.maximumApq5 = maximumApq5
    }
}

/// Public HNR thresholds for personalized baseline assessment
public struct PersonalizedHNRThresholds: Equatable, Codable {
    public let minimumMean: Double
    public let maximumStd: Double
    
    public init(minimumMean: Double, maximumStd: Double) {
        self.minimumMean = minimumMean
        self.maximumStd = maximumStd
    }
}

/// Public F0 range for personalized baseline assessment
public struct PersonalizedF0Range: Equatable, Codable {
    public let min: Double
    public let max: Double
    
    public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

/// Personalized thresholds based on baseline
public struct PersonalizedThresholds: Equatable, Codable {
    public let f0Range: PersonalizedF0Range
    public let minimumF0Confidence: Double
    public let minimumVoicedRatio: Double
    public let minimumRecordingDuration: TimeInterval
    public let jitterThresholds: PersonalizedJitterThresholds
    public let shimmerThresholds: PersonalizedShimmerThresholds
    public let hnrThresholds: PersonalizedHNRThresholds
    
    public init(
        f0Range: PersonalizedF0Range,
        minimumF0Confidence: Double,
        minimumVoicedRatio: Double,
        minimumRecordingDuration: TimeInterval,
        jitterThresholds: PersonalizedJitterThresholds,
        shimmerThresholds: PersonalizedShimmerThresholds,
        hnrThresholds: PersonalizedHNRThresholds
    ) {
        self.f0Range = f0Range
        self.minimumF0Confidence = minimumF0Confidence
        self.minimumVoicedRatio = minimumVoicedRatio
        self.minimumRecordingDuration = minimumRecordingDuration
        self.jitterThresholds = jitterThresholds
        self.shimmerThresholds = shimmerThresholds
        self.hnrThresholds = hnrThresholds
    }
    
    public static func fromBaseline(_ biomarkers: VocalBiomarkers, demographic: VoiceDemographic) -> PersonalizedThresholds {
        // Create personalized thresholds based on user's baseline and demographic
        let f0Range = PersonalizedF0Range(
            min: biomarkers.f0.mean * 0.8,
            max: biomarkers.f0.mean * 1.2
        )
        
        // Create threshold objects based on baseline values
        let jitterThresholds = PersonalizedJitterThresholds(
            maximumLocal: biomarkers.voiceQuality.jitter.local * 1.5,
            maximumRap: biomarkers.voiceQuality.jitter.rap * 1.5,
            maximumPpq5: biomarkers.voiceQuality.jitter.ppq5 * 1.5
        )
        
        let shimmerThresholds = PersonalizedShimmerThresholds(
            maximumLocal: biomarkers.voiceQuality.shimmer.local * 1.5,
            maximumApq3: biomarkers.voiceQuality.shimmer.apq3 * 1.5,
            maximumApq5: biomarkers.voiceQuality.shimmer.apq5 * 1.5
        )
        
        let hnrThresholds = PersonalizedHNRThresholds(
            minimumMean: biomarkers.voiceQuality.hnr.mean * 0.8,
            maximumStd: biomarkers.voiceQuality.hnr.std * 1.2
        )
        
        return PersonalizedThresholds(
            f0Range: f0Range,
            minimumF0Confidence: 50.0,
            minimumVoicedRatio: 0.6,
            minimumRecordingDuration: 3.0,
            jitterThresholds: jitterThresholds,
            shimmerThresholds: shimmerThresholds,
            hnrThresholds: hnrThresholds
        )
    }
} 