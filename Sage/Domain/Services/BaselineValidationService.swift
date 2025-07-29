//
//  BaselineValidationService.swift
//  Sage
//
//  Domain service for baseline validation using real clinical thresholds
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation

// MARK: - Baseline Validation Service Protocol

/// Domain service for validating vocal baselines against clinical standards
/// - Uses research-based thresholds for different demographics
/// - Provides detailed validation feedback
/// - Follows single responsibility principle
protocol BaselineValidationServiceProtocol {
    /// Validates a vocal baseline against clinical standards
    /// - Parameter baseline: Baseline to validate
    /// - Returns: Validation result with clinical assessment
    func validateBaseline(_ baseline: VocalBaseline) -> BaselineValidationResult
}

// MARK: - Baseline Validation Service Implementation

final class BaselineValidationService: BaselineValidationServiceProtocol {
    
    // MARK: - Dependencies
    
    private let clinicalThresholdsService: ClinicalThresholdsServiceProtocol
    private let logger: StructuredLogger
    
    // MARK: - Initialization
    
    init(
        clinicalThresholdsService: ClinicalThresholdsServiceProtocol,
        logger: StructuredLogger = StructuredLogger(component: "BaselineValidationService")
    ) {
        self.clinicalThresholdsService = clinicalThresholdsService
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    public func validateBaseline(_ baseline: VocalBaseline) -> BaselineValidationResult {
        
        logger.debug("[BaselineValidationService] Validating baseline for user: \(baseline.userId)")
        
        // Get clinical thresholds for user's demographic
        let thresholds = clinicalThresholdsService.getThresholds(for: baseline.demographic)
        
        // Validate F0 confidence (minimum quality requirement)
        let f0ConfidenceValidation = validateF0Confidence(
            confidence: baseline.biomarkers.f0.confidence,
            threshold: thresholds.minimumF0Confidence
        )
        
        // Validate F0 range for demographic
        let f0RangeValidation = validateF0Range(
            f0Mean: baseline.biomarkers.f0.mean,
            demographic: baseline.demographic,
            thresholds: thresholds
        )
        
        // Validate voiced content ratio
        let voicedContentValidation = validateVoicedContent(
            voicedRatio: baseline.biomarkers.metadata.voicedRatio,
            threshold: thresholds.minimumVoicedRatio
        )
        
        // Validate recording duration
        let durationValidation = validateRecordingDuration(
            duration: baseline.biomarkers.metadata.recordingDuration,
            threshold: thresholds.minimumRecordingDuration
        )
        
        // Validate voice quality measures
        let qualityValidation = validateVoiceQuality(
            biomarkers: baseline.biomarkers,
            thresholds: thresholds
        )
        
        // Combine all validation results
        let allValidations = [
            f0ConfidenceValidation,
            f0RangeValidation,
            voicedContentValidation,
            durationValidation,
            qualityValidation
        ]
        
        let failedValidations = allValidations.filter { !$0.isValid }
        
        if failedValidations.isEmpty {
            // All validations passed
            let confidenceScore = calculateConfidenceScore(validations: allValidations)
            let clinicalQuality = determineClinicalQuality(baseline: baseline, thresholds: thresholds)
            
            logger.info("[BaselineValidationService] Baseline validation passed for user: \(baseline.userId)")
            
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            // Validation failed
            let rejectionReason = failedValidations
                .compactMap { $0.rejectionReason }
                .joined(separator: "; ")
            
            logger.error("[BaselineValidationService] Baseline validation failed for user: \(baseline.userId): \(rejectionReason)")
            
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: rejectionReason
            )
        }
    }
    
    // MARK: - Private Validation Methods
    
    private func validateF0Confidence(confidence: Double, threshold: Double) -> BaselineValidationResult {
        let isValid = confidence >= threshold
        return BaselineValidationResult(
            isValid: isValid,
            rejectionReason: isValid ? nil : "F0 confidence (\(confidence)%) below minimum threshold (\(threshold)%)"
        )
    }
    
    private func validateF0Range(f0Mean: Double, demographic: VoiceDemographic, thresholds: ClinicalThresholds) -> BaselineValidationResult {
        let range = thresholds.f0Range
        let isValid = f0Mean >= range.min && f0Mean <= range.max
        
        return BaselineValidationResult(
            isValid: isValid,
            rejectionReason: isValid ? nil : "F0 mean (\(f0Mean)Hz) outside expected range (\(range.min)-\(range.max)Hz) for \(demographic)"
        )
    }
    
    private func validateVoicedContent(voicedRatio: Double, threshold: Double) -> BaselineValidationResult {
        let isValid = voicedRatio >= threshold
        return BaselineValidationResult(
            isValid: isValid,
            rejectionReason: isValid ? nil : "Voiced content ratio (\(voicedRatio)) below minimum threshold (\(threshold))"
        )
    }
    
    private func validateRecordingDuration(duration: TimeInterval, threshold: TimeInterval) -> BaselineValidationResult {
        let isValid = duration >= threshold
        return BaselineValidationResult(
            isValid: isValid,
            rejectionReason: isValid ? nil : "Recording duration (\(duration)s) below minimum threshold (\(threshold)s)"
        )
    }
    
    private func validateVoiceQuality(biomarkers: VocalBiomarkers, thresholds: ClinicalThresholds) -> BaselineValidationResult {
        // Validate jitter measures
        let jitterValidation = validateJitterMeasures(
            jitter: biomarkers.voiceQuality.jitter,
            thresholds: thresholds.jitterThresholds
        )
        
        // Validate shimmer measures
        let shimmerValidation = validateShimmerMeasures(
            shimmer: biomarkers.voiceQuality.shimmer,
            thresholds: thresholds.shimmerThresholds
        )
        
        // Validate HNR measures
        let hnrValidation = validateHNRMeasures(
            hnr: biomarkers.voiceQuality.hnr,
            thresholds: thresholds.hnrThresholds
        )
        
        // Combine quality validations
        let qualityValidations = [jitterValidation, shimmerValidation, hnrValidation]
        let failedQualityValidations = qualityValidations.filter { !$0.isValid }
        
        if failedQualityValidations.isEmpty {
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            let reasons = failedQualityValidations.compactMap { $0.rejectionReason }
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: "Voice quality validation failed: \(reasons.joined(separator: "; "))"
            )
        }
    }
    
    private func validateF0Measures(f0: F0Analysis, thresholds: ClinicalThresholds) -> BaselineValidationResult {
        let meanValid = f0.mean >= thresholds.f0Range.min && f0.mean <= thresholds.f0Range.max
        let confidenceValid = f0.confidence >= thresholds.minimumF0Confidence
        
        if meanValid && confidenceValid {
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            let failures = [
                !meanValid ? "F0 mean (\(f0.mean)Hz) outside range (\(thresholds.f0Range.min)-\(thresholds.f0Range.max)Hz)" : nil,
                !confidenceValid ? "F0 confidence (\(f0.confidence)%) below minimum (\(thresholds.minimumF0Confidence)%)" : nil
            ].compactMap { $0 }
            
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: "F0 measures failed: \(failures.joined(separator: "; "))"
            )
        }
    }
    
    private func validateJitterMeasures(jitter: JitterMeasures, thresholds: JitterThresholds) -> BaselineValidationResult {
        let localValid = jitter.local <= thresholds.maximumLocal
        let rapValid = jitter.rap <= thresholds.maximumRap
        let ppq5Valid = jitter.ppq5 <= thresholds.maximumPpq5
        
        if localValid && rapValid && ppq5Valid {
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            let failures = [
                !localValid ? "local jitter (\(jitter.local)%) exceeds threshold (\(thresholds.maximumLocal)%)" : nil,
                !rapValid ? "RAP jitter (\(jitter.rap)%) exceeds threshold (\(thresholds.maximumRap)%)" : nil,
                !ppq5Valid ? "PPQ5 jitter (\(jitter.ppq5)%) exceeds threshold (\(thresholds.maximumPpq5)%)" : nil
            ].compactMap { $0 }
            
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: "Jitter measures failed: \(failures.joined(separator: "; "))"
            )
        }
    }
    
    private func validateShimmerMeasures(shimmer: ShimmerMeasures, thresholds: ShimmerThresholds) -> BaselineValidationResult {
        let localValid = shimmer.local <= thresholds.maximumLocal
        let apq3Valid = shimmer.apq3 <= thresholds.maximumApq3
        let apq5Valid = shimmer.apq5 <= thresholds.maximumApq5
        
        if localValid && apq3Valid && apq5Valid {
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            let failures = [
                !localValid ? "local shimmer (\(shimmer.local)%) exceeds threshold (\(thresholds.maximumLocal)%)" : nil,
                !apq3Valid ? "APQ3 shimmer (\(shimmer.apq3)%) exceeds threshold (\(thresholds.maximumApq3)%)" : nil,
                !apq5Valid ? "APQ5 shimmer (\(shimmer.apq5)%) exceeds threshold (\(thresholds.maximumApq5)%)" : nil
            ].compactMap { $0 }
            
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: "Shimmer measures failed: \(failures.joined(separator: "; "))"
            )
        }
    }
    
    private func validateHNRMeasures(hnr: HNRAnalysis, thresholds: HNRThresholds) -> BaselineValidationResult {
        let meanValid = hnr.mean >= thresholds.minimumMean
        let stdValid = hnr.std <= thresholds.maximumStd
        
        if meanValid && stdValid {
            return BaselineValidationResult(
                isValid: true
            )
        } else {
            let failures = [
                !meanValid ? "HNR mean (\(hnr.mean)dB) below minimum threshold (\(thresholds.minimumMean)dB)" : nil,
                !stdValid ? "HNR std (\(hnr.std)dB) exceeds maximum threshold (\(thresholds.maximumStd)dB)" : nil
            ].compactMap { $0 }
            
            return BaselineValidationResult(
                isValid: false,
                rejectionReason: "HNR measures failed: \(failures.joined(separator: "; "))"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateConfidenceScore(validations: [BaselineValidationResult]) -> Double {
        // Calculate weighted confidence based on validation results
        let totalWeight = validations.count
        let passedWeight = validations.filter { $0.isValid }.count
        return Double(passedWeight) / Double(totalWeight) * 100.0
    }
    
    private func determineClinicalQuality(baseline: VocalBaseline, thresholds: ClinicalThresholds) -> VoiceQualityLevel {
        // Determine clinical quality based on biomarker values vs thresholds
        let f0Quality = baseline.biomarkers.f0.confidence >= thresholds.excellentF0Confidence ? VoiceQualityLevel.excellent : .good
        let stabilityQuality = baseline.biomarkers.stability.score >= thresholds.excellentStabilityScore ? VoiceQualityLevel.excellent : .good
        
        // Return the higher quality level
        return f0Quality == .excellent && stabilityQuality == .excellent ? .excellent : .good
    }
}

// MARK: - Supporting Types

public struct BaselineValidationResult {
    let isValid: Bool
    let rejectionReason: String?
    
    init(isValid: Bool, rejectionReason: String? = nil) {
        self.isValid = isValid
        self.rejectionReason = rejectionReason
    }
} 