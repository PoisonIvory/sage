//
//  VocalBaselineTests.swift
//  SageTests
//
//  Tests for vocal baseline domain model following TDD principles
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import XCTest
import Foundation
@testable import Sage

final class VocalBaselineTests: XCTestCase {
    
    // MARK: - AC-001: Record Initial Vocal Baseline Tests
    
    func testUserRecordsInitialVocalBaseline() {
        // Given: A new user with demographic information
        let userId = UUID()
        let demographic = VoiceDemographic.adultFemale
        let biomarkers = createValidVocalBiomarkers()
        
        // When: Creating a vocal baseline from onboarding recording
        let baseline = VocalBaseline(
            userId: userId,
            establishedAt: Date(),
            biomarkers: biomarkers,
            demographic: demographic,
            recordingContext: .onboarding
        )
        
        // Then: Baseline should be properly initialized with clinical validation
        XCTAssertEqual(baseline.userId, userId)
        XCTAssertEqual(baseline.demographic, demographic)
        XCTAssertEqual(baseline.recordingContext, .onboarding)
        XCTAssertTrue(baseline.isClinicallValid)
        XCTAssertNotNil(baseline.personalizedThresholds)
    }
    
    func testBaselineCalculatesPersonalizedThresholds() {
        // Given: Valid vocal biomarkers from baseline recording
        let biomarkers = createValidVocalBiomarkers()
        let baseline = createValidBaseline(biomarkers: biomarkers)
        
        // When: Accessing personalized thresholds
        let thresholds = baseline.personalizedThresholds
        
        // Then: Thresholds should be calculated based on user's baseline
        XCTAssertTrue(thresholds.f0Range.contains(biomarkers.f0.mean))
        XCTAssertEqual(thresholds.jitterThreshold, biomarkers.voiceQuality.jitter.local * 1.5, accuracy: 0.1)
        XCTAssertEqual(thresholds.shimmerThreshold, biomarkers.voiceQuality.shimmer.local * 1.5, accuracy: 0.1)
        XCTAssertEqual(thresholds.hnrThreshold, biomarkers.voiceQuality.hnr.mean * 0.8, accuracy: 0.1)
    }
    
    func testBaselineRejectsInvalidVocalData() {
        // Given: Invalid vocal biomarkers (poor quality)
        let invalidBiomarkers = createInvalidVocalBiomarkers()
        
        // When: Attempting to create baseline with invalid data
        let baseline = VocalBaseline(
            userId: UUID(),
            establishedAt: Date(),
            biomarkers: invalidBiomarkers,
            demographic: .adultFemale,
            recordingContext: .onboarding
        )
        
        // Then: Baseline should be marked as clinically invalid
        XCTAssertFalse(baseline.isClinicallValid)
        XCTAssertEqual(baseline.validationStatus, .rejected(reason: "F0 confidence below clinical threshold"))
    }
    
    // MARK: - AC-002: Display Baseline Summary and Education Tests
    
    func testBaselineGeneratesEducationalSummary() {
        // Given: Valid vocal baseline established during onboarding
        let baseline = createValidBaseline()
        
        // When: Generating educational summary for user
        let summary = baseline.educationalSummary
        
        // Then: Summary should contain user-friendly explanations
        XCTAssertTrue(summary.contains("Your unique voice profile"))
        XCTAssertTrue(summary.contains("track changes throughout your menstrual cycle"))
        XCTAssertTrue(summary.contains("hormonal fluctuations"))
        XCTAssertNotNil(baseline.clinicalInterpretation)
    }
    
    func testBaselineDisplaysKeyMetrics() {
        // Given: Baseline with specific vocal measurements
        let biomarkers = createValidVocalBiomarkers()
        let baseline = createValidBaseline(biomarkers: biomarkers)
        
        // When: Accessing display metrics
        let displayMetrics = baseline.displayMetrics
        
        // Then: Should show formatted clinical values
        XCTAssertEqual(displayMetrics.fundamentalFrequency, "220.5 Hz")
        XCTAssertEqual(displayMetrics.voiceStability, "85%")
        XCTAssertEqual(displayMetrics.overallQuality, "Good")
        XCTAssertNotNil(displayMetrics.establishmentDate)
    }
    
    // MARK: - AC-003: Re-record Baseline During Onboarding Tests
    
    func testUserCanArchiveAndReplaceBaseline() {
        // Given: Existing baseline that user wants to replace
        let originalBaseline = createValidBaseline()
        let newBiomarkers = createAlternativeVocalBiomarkers()
        
        // When: User re-records baseline
        let updatedBaseline = originalBaseline.replaceWith(
            newBiomarkers: newBiomarkers,
            replacedAt: Date()
        )
        
        // Then: Original should be archived and new baseline active
        XCTAssertEqual(updatedBaseline.biomarkers.f0.mean, newBiomarkers.f0.mean)
        XCTAssertNotNil(updatedBaseline.archivedBaseline)
        XCTAssertEqual(updatedBaseline.archivedBaseline?.biomarkers.f0.mean, originalBaseline.biomarkers.f0.mean)
        XCTAssertTrue(updatedBaseline.wasReplaced)
    }
    
    func testBaselineArchiveRetainsHistory() {
        // Given: Multiple baseline replacements
        let firstBaseline = createValidBaseline()
        let secondBiomarkers = createAlternativeVocalBiomarkers()
        let thirdBiomarkers = createValidVocalBiomarkers()
        
        // When: Replacing baseline multiple times
        let secondBaseline = firstBaseline.replaceWith(newBiomarkers: secondBiomarkers, replacedAt: Date())
        let thirdBaseline = secondBaseline.replaceWith(newBiomarkers: thirdBiomarkers, replacedAt: Date())
        
        // Then: Should maintain complete history
        XCTAssertEqual(thirdBaseline.replacementHistory.count, 2)
        XCTAssertNotNil(thirdBaseline.archivedBaseline)
        XCTAssertTrue(thirdBaseline.wasReplaced)
    }
    
    // MARK: - Clinical Validation Tests
    
    func testBaselineValidatesClinicalThresholds() {
        // Given: Various vocal biomarker scenarios
        let excellentBiomarkers = createExcellentVocalBiomarkers()
        let poorBiomarkers = createPoorVocalBiomarkers()
        
        // When: Creating baselines with different quality levels
        let excellentBaseline = createValidBaseline(biomarkers: excellentBiomarkers)
        let poorBaseline = createValidBaseline(biomarkers: poorBiomarkers)
        
        // Then: Clinical validation should reflect biomarker quality
        XCTAssertEqual(excellentBaseline.clinicalQuality, .excellent)
        XCTAssertEqual(poorBaseline.clinicalQuality, .moderate)
        XCTAssertTrue(excellentBaseline.isClinicallValid)
        XCTAssertTrue(poorBaseline.isClinicallValid) // Poor but still valid for baseline
    }
    
    func testBaselineExpirationLogic() {
        // Given: Baseline established 91 days ago
        let oldDate = Calendar.current.date(byAdding: .day, value: -91, to: Date())!
        let oldBaseline = VocalBaseline(
            userId: UUID(),
            establishedAt: oldDate,
            biomarkers: createValidVocalBiomarkers(),
            demographic: .adultFemale,
            recordingContext: .onboarding
        )
        
        // When: Checking if baseline needs refresh
        let needsRefresh = oldBaseline.needsRefresh
        let daysUntilExpiry = oldBaseline.daysUntilExpiryRecommendation
        
        // Then: Should recommend refresh for old baselines
        XCTAssertTrue(needsRefresh)
        XCTAssertLessThan(daysUntilExpiry, 0) // Already expired
    }
    
    // MARK: - Helper Methods
    
    private func createValidBaseline(biomarkers: VocalBiomarkers? = nil) -> VocalBaseline {
        return VocalBaseline(
            userId: UUID(),
            establishedAt: Date(),
            biomarkers: biomarkers ?? createValidVocalBiomarkers(),
            demographic: .adultFemale,
            recordingContext: .onboarding
        )
    }
    
    private func createValidVocalBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 220.5, std: 15.2, confidence: 85.0)
        let jitter = JitterMeasures(local: 0.8, absolute: 45.2, rap: 0.7, ppq5: 0.9)
        let shimmer = ShimmerMeasures(local: 3.2, db: 0.28, apq3: 2.8, apq5: 3.1)
        let hnr = HNRAnalysis(mean: 19.5, std: 2.1)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 82.5, components: StabilityComponents(f0Score: 34.0, jitterScore: 16.4, shimmerScore: 15.8, hnrScore: 16.3))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.85, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createInvalidVocalBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 220.5, std: 45.0, confidence: 35.0) // Low confidence
        let jitter = JitterMeasures(local: 8.5, absolute: 150.0, rap: 7.2, ppq5: 9.1) // High jitter
        let shimmer = ShimmerMeasures(local: 15.2, db: 1.8, apq3: 14.8, apq5: 16.1) // High shimmer
        let hnr = HNRAnalysis(mean: 6.5, std: 3.8) // Low HNR
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 25.0, components: StabilityComponents(f0Score: 14.0, jitterScore: 4.0, shimmerScore: 3.0, hnrScore: 4.0))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 2.0, sampleRate: 48000, voicedRatio: 0.35, analysisTimestamp: Date(), analysisSource: .localIOS)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createAlternativeVocalBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 235.0, std: 18.5, confidence: 78.0)
        let jitter = JitterMeasures(local: 1.2, absolute: 52.0, rap: 1.1, ppq5: 1.3)
        let shimmer = ShimmerMeasures(local: 4.1, db: 0.35, apq3: 3.8, apq5: 4.3)
        let hnr = HNRAnalysis(mean: 17.2, std: 2.8)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 76.0, components: StabilityComponents(f0Score: 31.2, jitterScore: 15.2, shimmerScore: 14.6, hnrScore: 15.0))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.5, sampleRate: 48000, voicedRatio: 0.78, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createExcellentVocalBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 215.0, std: 8.5, confidence: 92.0)
        let jitter = JitterMeasures(local: 0.6, absolute: 28.0, rap: 0.5, ppq5: 0.7)
        let shimmer = ShimmerMeasures(local: 2.1, db: 0.18, apq3: 1.9, apq5: 2.3)
        let hnr = HNRAnalysis(mean: 22.5, std: 1.8)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 91.0, components: StabilityComponents(f0Score: 36.8, jitterScore: 18.2, shimmerScore: 17.8, hnrScore: 18.2))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.92, analysisTimestamp: Date(), analysisSource: .cloudParselmouth)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createPoorVocalBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 195.0, std: 28.0, confidence: 65.0)
        let jitter = JitterMeasures(local: 3.5, absolute: 85.0, rap: 2.8, ppq5: 3.8)
        let shimmer = ShimmerMeasures(local: 8.2, db: 0.78, apq3: 7.8, apq5: 8.6)
        let hnr = HNRAnalysis(mean: 12.0, std: 3.5)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 58.0, components: StabilityComponents(f0Score: 26.0, jitterScore: 10.0, shimmerScore: 9.5, hnrScore: 12.5))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 4.5, sampleRate: 48000, voicedRatio: 0.65, analysisTimestamp: Date(), analysisSource: .localIOS)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
}