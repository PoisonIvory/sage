//
//  ClinicalThresholdsService.swift
//  Sage
//
//  Domain service for clinical thresholds based on research data
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation

// MARK: - Clinical Thresholds Service Protocol

/// Domain service for providing clinical thresholds based on research data
/// - Uses peer-reviewed research for threshold values
/// - Provides demographic-specific thresholds
/// - Follows single responsibility principle
protocol ClinicalThresholdsServiceProtocol {
    /// Gets clinical thresholds for a specific demographic
    /// - Parameter demographic: Voice demographic (age, gender, etc.)
    /// - Returns: Clinical thresholds for the demographic
    func getThresholds(for demographic: VoiceDemographic) -> ClinicalThresholds
}

// MARK: - Clinical Thresholds Service Implementation

final class ClinicalThresholdsService: ClinicalThresholdsServiceProtocol {
    
    // MARK: - Dependencies
    
    private let researchDataService: ResearchDataServiceProtocol
    private let logger: StructuredLogger
    
    // MARK: - Initialization
    
    init(
        researchDataService: ResearchDataServiceProtocol,
        logger: StructuredLogger = StructuredLogger(component: "ClinicalThresholdsService")
    ) {
        self.researchDataService = researchDataService
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    func getThresholds(for demographic: VoiceDemographic) -> ClinicalThresholds {
        
        logger.debug("[ClinicalThresholdsService] Getting thresholds for demographic: \(demographic)")
        
        // Get research-based thresholds for the demographic
        let researchThresholds = researchDataService.getThresholds(for: demographic)
        
        // Apply any clinical adjustments based on current research
        let adjustedThresholds = applyClinicalAdjustments(
            baseThresholds: researchThresholds,
            demographic: demographic
        )
        
        logger.debug("[ClinicalThresholdsService] Retrieved thresholds for \(demographic): F0 range \(adjustedThresholds.f0Range.min)-\(adjustedThresholds.f0Range.max)Hz")
        
        return adjustedThresholds
    }
    
    // MARK: - Private Methods
    
    private func applyClinicalAdjustments(
        baseThresholds: ClinicalThresholds,
        demographic: VoiceDemographic
    ) -> ClinicalThresholds {
        
        // Apply any clinical adjustments based on current research findings
        // This allows for updates to thresholds without changing the base research data
        
        var adjustedThresholds = baseThresholds
        
        // Apply age-specific adjustments based on recent research
        switch demographic {
        case .adolescent:
            // Adolescents may have higher F0 variability
            adjustedThresholds.f0Range = F0Range(
                min: baseThresholds.f0Range.min * 0.9,
                max: baseThresholds.f0Range.max * 1.1
            )
            adjustedThresholds.minimumF0Confidence = 45.0 // Slightly lower for adolescents
            
        case .seniorFemale, .seniorMale, .seniorOther:
            // Seniors may have lower F0 and higher variability
            adjustedThresholds.f0Range = F0Range(
                min: baseThresholds.f0Range.min * 0.8,
                max: baseThresholds.f0Range.max * 0.9
            )
            adjustedThresholds.minimumF0Confidence = 40.0 // Lower confidence acceptable for seniors
            
        default:
            // Adult demographics use standard thresholds
            break
        }
        
        return adjustedThresholds
    }
}

// MARK: - Clinical Thresholds Data Structure

struct ClinicalThresholds {
    // F0 (Fundamental Frequency) thresholds
    var f0Range: F0Range
    var minimumF0Confidence: Double
    let excellentF0Confidence: Double
    
    // Recording quality thresholds
    let minimumVoicedRatio: Double
    let minimumRecordingDuration: TimeInterval
    
    // Voice quality thresholds
    let jitterThresholds: JitterThresholds
    let shimmerThresholds: ShimmerThresholds
    let hnrThresholds: HNRThresholds
    
    // Stability thresholds
    let excellentStabilityScore: Double
    let minimumStabilityScore: Double
}

struct F0Range {
    var min: Double
    var max: Double
}

struct JitterThresholds {
    let maximumLocal: Double
    let maximumRap: Double
    let maximumPpq5: Double
}

struct ShimmerThresholds {
    let maximumLocal: Double
    let maximumApq3: Double
    let maximumApq5: Double
}

struct HNRThresholds {
    let minimumMean: Double
    let maximumStd: Double
}

// MARK: - Research Data Service Protocol

/// Service for accessing research-based clinical thresholds
/// - Provides peer-reviewed threshold values
/// - Separates research data from clinical adjustments
protocol ResearchDataServiceProtocol {
    func getThresholds(for demographic: VoiceDemographic) -> ClinicalThresholds
}

// MARK: - Research Data Service Implementation

final class ResearchDataService: ResearchDataServiceProtocol {
    
    func getThresholds(for demographic: VoiceDemographic) -> ClinicalThresholds {
        
        // These values are based on peer-reviewed research
        // References: Titze (1994), Baken & Orlikoff (2000), etc.
        
        switch demographic {
        case .adolescent:
            return ClinicalThresholds(
                f0Range: F0Range(min: 150.0, max: 300.0),
                minimumF0Confidence: 50.0,
                excellentF0Confidence: 85.0,
                minimumVoicedRatio: 0.6,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.5,
                    maximumRap: 1.2,
                    maximumPpq5: 1.8
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 5.0,
                    maximumApq3: 4.5,
                    maximumApq5: 5.5
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 15.0,
                    maximumStd: 3.0
                ),
                excellentStabilityScore: 80.0,
                minimumStabilityScore: 60.0
            )
            
        case .adultFemale:
            return ClinicalThresholds(
                f0Range: F0Range(min: 165.0, max: 255.0),
                minimumF0Confidence: 50.0,
                excellentF0Confidence: 85.0,
                minimumVoicedRatio: 0.6,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.04,
                    maximumRap: 0.84,
                    maximumPpq5: 1.04
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 3.81,
                    maximumApq3: 3.47,
                    maximumApq5: 3.81
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 20.0,
                    maximumStd: 2.5
                ),
                excellentStabilityScore: 85.0,
                minimumStabilityScore: 65.0
            )
            
        case .adultMale:
            return ClinicalThresholds(
                f0Range: F0Range(min: 85.0, max: 180.0),
                minimumF0Confidence: 50.0,
                excellentF0Confidence: 85.0,
                minimumVoicedRatio: 0.6,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.04,
                    maximumRap: 0.84,
                    maximumPpq5: 1.04
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 3.81,
                    maximumApq3: 3.47,
                    maximumApq5: 3.81
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 20.0,
                    maximumStd: 2.5
                ),
                excellentStabilityScore: 85.0,
                minimumStabilityScore: 65.0
            )
            
        case .adultOther:
            return ClinicalThresholds(
                f0Range: F0Range(min: 120.0, max: 220.0),
                minimumF0Confidence: 50.0,
                excellentF0Confidence: 85.0,
                minimumVoicedRatio: 0.6,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.04,
                    maximumRap: 0.84,
                    maximumPpq5: 1.04
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 3.81,
                    maximumApq3: 3.47,
                    maximumApq5: 3.81
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 20.0,
                    maximumStd: 2.5
                ),
                excellentStabilityScore: 85.0,
                minimumStabilityScore: 65.0
            )
            
        case .seniorFemale:
            return ClinicalThresholds(
                f0Range: F0Range(min: 140.0, max: 220.0),
                minimumF0Confidence: 45.0,
                excellentF0Confidence: 80.0,
                minimumVoicedRatio: 0.5,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.5,
                    maximumRap: 1.2,
                    maximumPpq5: 1.8
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 5.0,
                    maximumApq3: 4.5,
                    maximumApq5: 5.5
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 15.0,
                    maximumStd: 3.0
                ),
                excellentStabilityScore: 75.0,
                minimumStabilityScore: 55.0
            )
            
        case .seniorMale:
            return ClinicalThresholds(
                f0Range: F0Range(min: 80.0, max: 160.0),
                minimumF0Confidence: 45.0,
                excellentF0Confidence: 80.0,
                minimumVoicedRatio: 0.5,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.5,
                    maximumRap: 1.2,
                    maximumPpq5: 1.8
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 5.0,
                    maximumApq3: 4.5,
                    maximumApq5: 5.5
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 15.0,
                    maximumStd: 3.0
                ),
                excellentStabilityScore: 75.0,
                minimumStabilityScore: 55.0
            )
            
        case .seniorOther:
            return ClinicalThresholds(
                f0Range: F0Range(min: 100.0, max: 180.0),
                minimumF0Confidence: 45.0,
                excellentF0Confidence: 80.0,
                minimumVoicedRatio: 0.5,
                minimumRecordingDuration: 3.0,
                jitterThresholds: JitterThresholds(
                    maximumLocal: 1.5,
                    maximumRap: 1.2,
                    maximumPpq5: 1.8
                ),
                shimmerThresholds: ShimmerThresholds(
                    maximumLocal: 5.0,
                    maximumApq3: 4.5,
                    maximumApq5: 5.5
                ),
                hnrThresholds: HNRThresholds(
                    minimumMean: 15.0,
                    maximumStd: 3.0
                ),
                excellentStabilityScore: 75.0,
                minimumStabilityScore: 55.0
            )
        }
    }
} 