//
//  HormonalCorrelationTests.swift
//  SageTests
//
//  Tests for hormonal phase correlation following TDD principles
//  AC-005: Daily Voice Tracking in Context of Baseline
//  AC-006: Show Longitudinal Voice and Hormone Insights
//

import XCTest
import Foundation
@testable import Sage

final class HormonalCorrelationTests: XCTestCase {
    
    // MARK: - AC-005: Daily Voice Tracking in Context of Baseline Tests
    
    func testSessionAnalysisRelativeToBaseline() {
        // Given: User has established baseline and records daily session
        let baseline = createValidBaseline()
        let sessionBiomarkers = createSessionBiomarkers()
        let cyclePhase = MenstrualPhase.luteal(day: 22)
        
        // When: Analyzing session in context of baseline
        let correlation = HormonalCorrelation.analyzeSession(
            sessionBiomarkers: sessionBiomarkers,
            baseline: baseline,
            cyclePhase: cyclePhase,
            sessionDate: Date()
        )
        
        // Then: Analysis should include baseline comparison and hormonal context
        XCTAssertNotNil(correlation.baselineComparison)
        XCTAssertEqual(correlation.cyclePhase, cyclePhase)
        XCTAssertNotNil(correlation.f0Deviation)
        XCTAssertNotNil(correlation.voiceQualityShift)
        XCTAssertTrue(correlation.isClinicalglySignificant)
    }
    
    func testF0DeviationFromBaseline() {
        // Given: Baseline F0 and session with different F0
        let baselineF0 = F0Analysis(mean: 220.0, std: 15.0, confidence: 85.0)
        let sessionF0 = F0Analysis(mean: 235.0, std: 18.0, confidence: 82.0)
        
        // When: Calculating F0 deviation
        let deviation = F0Deviation.calculate(session: sessionF0, baseline: baselineF0)
        
        // Then: Should quantify meaningful change
        XCTAssertEqual(deviation.meanShift, 15.0, accuracy: 0.1)
        XCTAssertEqual(deviation.percentageChange, 6.82, accuracy: 0.1)
        XCTAssertEqual(deviation.clinicalSignificance, .moderate)
        XCTAssertTrue(deviation.isUpward)
    }
    
    func testVoiceQualityShiftAnalysis() {
        // Given: Baseline and session with different voice quality
        let baselineJitter = JitterMeasures(local: 0.8, absolute: 45.0, rap: 0.7, ppq5: 0.9)
        let sessionJitter = JitterMeasures(local: 1.4, absolute: 78.0, rap: 1.2, ppq5: 1.5)
        
        // When: Analyzing voice quality shift
        let shift = VoiceQualityShift.analyze(
            sessionJitter: sessionJitter,
            baselineJitter: baselineJitter
        )
        
        // Then: Should detect deterioration in voice quality
        XCTAssertEqual(shift.direction, .deterioration)
        XCTAssertEqual(shift.magnitude, .moderate)
        XCTAssertTrue(shift.exceedsPersonalizedThreshold)
    }
    
    // MARK: - AC-006: Longitudinal Voice and Hormone Insights Tests
    
    func testLongitudinalPatternDetection() {
        // Given: Multiple sessions across menstrual cycle
        let baseline = createValidBaseline()
        let cycleSessions = createCompleteCycleSessions()
        
        // When: Analyzing longitudinal patterns
        let insights = LongitudinalInsights.analyze(
            sessions: cycleSessions,
            baseline: baseline,
            analysisWindow: .completeCycle
        )
        
        // Then: Should identify hormonal phase correlations
        XCTAssertTrue(insights.hasSignificantPhaseCorrelations)
        XCTAssertNotNil(insights.ovulationDetection)
        XCTAssertNotNil(insights.lutealPhasePattern)
        XCTAssertNotNil(insights.menstrualPhasePattern)
        XCTAssertGreaterThan(insights.correlationStrength, 0.3) // Statistical significance
    }
    
    func testOvulationDetectionFromVoice() {
        // Given: Sessions around ovulation window
        let baseline = createValidBaseline()
        let ovulationSessions = createOvulationWindowSessions()
        
        // When: Analyzing for ovulation detection
        let detection = OvulationDetection.analyze(
            sessions: ovulationSessions,
            baseline: baseline
        )
        
        // Then: Should identify F0 peak characteristic of ovulation
        XCTAssertNotNil(detection.predictedOvulationDate)
        XCTAssertGreaterThan(detection.confidence, 0.7)
        XCTAssertTrue(detection.f0PatternMatches)
        XCTAssertEqual(detection.detectionMethod, .f0Peak)
    }
    
    func testLutealPhaseVoicePattern() {
        // Given: Sessions during luteal phase
        let baseline = createValidBaseline()
        let lutealSessions = createLutealPhaseSessions()
        
        // When: Analyzing luteal phase patterns
        let pattern = LutealPhasePattern.analyze(
            sessions: lutealSessions,
            baseline: baseline
        )
        
        // Then: Should detect progesterone-related voice changes
        XCTAssertTrue(pattern.f0Decline.isPresent)
        XCTAssertTrue(pattern.voiceQualityDegradation.isPresent)
        XCTAssertEqual(pattern.progressivePattern, .declining)
        XCTAssertGreaterThan(pattern.statisticalSignificance, 0.05)
    }
    
    func testPersonalizedHormonalInsights() {
        // Given: User's complete cycle data with baseline
        let baseline = createValidBaseline()
        let userCycleData = createPersonalizedCycleData()
        
        // When: Generating personalized insights
        let insights = PersonalizedHormonalInsights.generate(
            baseline: baseline,
            cycleData: userCycleData,
            demographicContext: .adultFemale
        )
        
        // Then: Should provide user-specific hormonal patterns
        XCTAssertNotNil(insights.personalF0Pattern)
        XCTAssertNotNil(insights.cyclePhaseVoiceMap)
        XCTAssertNotNil(insights.hormonalSensitivity)
        XCTAssertNotNil(insights.clinicalRecommendations)
        XCTAssertTrue(insights.isStatisticallyValid)
    }
    
    // MARK: - Clinical Validation Tests
    
    func testCorrelationStatisticalSignificance() {
        // Given: Large dataset of sessions with known cycle phases
        let baseline = createValidBaseline()
        let largeCycleDataset = createLargeCycleDataset(sessionCount: 60)
        
        // When: Calculating statistical significance of correlations
        let significance = StatisticalAnalysis.calculateSignificance(
            sessions: largeCycleDataset,
            baseline: baseline
        )
        
        // Then: Should meet clinical research standards
        XCTAssertLessThan(significance.pValue, 0.05) // Statistically significant
        XCTAssertGreaterThan(significance.correlationCoefficient, 0.3) // Moderate correlation
        XCTAssertGreaterThan(significance.sampleSize, 30) // Adequate sample size
        XCTAssertTrue(significance.meetsResearchStandards)
    }
    
    func testResearchBasedValidation() {
        // Given: Voice patterns that should match published research
        let baseline = createValidBaseline()
        let researchBasedSessions = createResearchBasedSessions()
        
        // When: Validating against established research findings
        let validation = ResearchValidation.validate(
            sessions: researchBasedSessions,
            baseline: baseline,
            researchStandards: .farrausCervellera2007
        )
        
        // Then: Should align with published voice-hormone research
        XCTAssertTrue(validation.f0PatternsMatchResearch)
        XCTAssertTrue(validation.ovulationDetectionAccuracy >= 0.75)
        XCTAssertTrue(validation.lutealPhaseDetectionAccuracy >= 0.70)
        XCTAssertEqual(validation.overallValidationScore, .excellent)
    }
    
    // MARK: - Helper Methods
    
    private func createValidBaseline() -> VocalBaseline {
        let f0 = F0Analysis(mean: 220.0, std: 15.0, confidence: 85.0)
        let jitter = JitterMeasures(local: 0.8, absolute: 45.0, rap: 0.7, ppq5: 0.9)
        let shimmer = ShimmerMeasures(local: 3.2, db: 0.28, apq3: 2.8, apq5: 3.1)
        let hnr = HNRAnalysis(mean: 19.5, std: 2.1)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 82.5, components: StabilityComponents(f0Score: 34.0, jitterScore: 16.4, shimmerScore: 15.8, hnrScore: 16.3))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.85, analysisTimestamp: Date(), analysisSource: .hybrid)
        let biomarkers = VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
        
        return VocalBaseline(
            userId: UUID(),
            establishedAt: Date(),
            biomarkers: biomarkers,
            demographic: .adultFemale,
            recordingContext: .onboarding
        )
    }
    
    private func createSessionBiomarkers() -> VocalBiomarkers {
        let f0 = F0Analysis(mean: 235.0, std: 18.0, confidence: 82.0)
        let jitter = JitterMeasures(local: 1.1, absolute: 58.0, rap: 1.0, ppq5: 1.2)
        let shimmer = ShimmerMeasures(local: 3.8, db: 0.32, apq3: 3.5, apq5: 3.9)
        let hnr = HNRAnalysis(mean: 18.2, std: 2.4)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 78.0, components: StabilityComponents(f0Score: 32.8, jitterScore: 15.2, shimmerScore: 14.8, hnrScore: 15.2))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.82, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createCompleteCycleSessions() -> [VoiceSession] {
        var sessions: [VoiceSession] = []
        
        // Create sessions across a complete 28-day cycle
        for day in 1...28 {
            let phase = MenstrualPhase.fromCycleDay(day)
            let biomarkers = createBiomarkersForPhase(phase, cycleDay: day)
            let session = VoiceSession(
                id: UUID(),
                userId: UUID(),
                recordedAt: Date().addingTimeInterval(TimeInterval(-86400 * (28 - day))),
                biomarkers: biomarkers,
                cyclePhase: phase,
                cycleDay: day
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createOvulationWindowSessions() -> [VoiceSession] {
        var sessions: [VoiceSession] = []
        
        // Days 12-16 of cycle (ovulation window)
        for day in 12...16 {
            let phase = MenstrualPhase.ovulatory(day: day)
            let biomarkers = createOvulatoryBiomarkers(cycleDay: day)
            let session = VoiceSession(
                id: UUID(),
                userId: UUID(),
                recordedAt: Date().addingTimeInterval(TimeInterval(-86400 * (16 - day))),
                biomarkers: biomarkers,
                cyclePhase: phase,
                cycleDay: day
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createLutealPhaseSessions() -> [VoiceSession] {
        var sessions: [VoiceSession] = []
        
        // Days 15-28 of cycle (luteal phase)
        for day in 15...28 {
            let phase = MenstrualPhase.luteal(day: day)
            let biomarkers = createLutealBiomarkers(cycleDay: day)
            let session = VoiceSession(
                id: UUID(),
                userId: UUID(),
                recordedAt: Date().addingTimeInterval(TimeInterval(-86400 * (28 - day))),
                biomarkers: biomarkers,
                cyclePhase: phase,
                cycleDay: day
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createPersonalizedCycleData() -> [VoiceSession] {
        // Create 3 complete cycles of data for personalized insights
        return createCompleteCycleSessions() + 
               createCompleteCycleSessions() + 
               createCompleteCycleSessions()
    }
    
    private func createLargeCycleDataset(sessionCount: Int) -> [VoiceSession] {
        var sessions: [VoiceSession] = []
        
        for i in 0..<sessionCount {
            let cycleDay = (i % 28) + 1
            let phase = MenstrualPhase.fromCycleDay(cycleDay)
            let biomarkers = createBiomarkersForPhase(phase, cycleDay: cycleDay)
            let session = VoiceSession(
                id: UUID(),
                userId: UUID(),
                recordedAt: Date().addingTimeInterval(TimeInterval(-86400 * i)),
                biomarkers: biomarkers,
                cyclePhase: phase,
                cycleDay: cycleDay
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createResearchBasedSessions() -> [VoiceSession] {
        // Create sessions that should match Farrús & Cervellera (2007) findings
        return createCompleteCycleSessions()
    }
    
    private func createBiomarkersForPhase(_ phase: MenstrualPhase, cycleDay: Int) -> VocalBiomarkers {
        // Simulate research-based voice changes throughout cycle
        let baseF0: Double = 220.0
        let f0Adjustment: Double
        
        switch phase {
        case .menstrual:
            f0Adjustment = -5.0 // Lower F0 during menstruation
        case .follicular:
            f0Adjustment = 0.0 // Baseline F0
        case .ovulatory:
            f0Adjustment = 8.0 // Higher F0 around ovulation (estrogen peak)
        case .luteal:
            f0Adjustment = -3.0 // Slightly lower F0 (progesterone effect)
        }
        
        let f0 = F0Analysis(mean: baseF0 + f0Adjustment, std: 15.0, confidence: 85.0)
        let jitter = JitterMeasures(local: 0.8, absolute: 45.0, rap: 0.7, ppq5: 0.9)
        let shimmer = ShimmerMeasures(local: 3.2, db: 0.28, apq3: 2.8, apq5: 3.1)
        let hnr = HNRAnalysis(mean: 19.5, std: 2.1)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 82.5, components: StabilityComponents(f0Score: 34.0, jitterScore: 16.4, shimmerScore: 15.8, hnrScore: 16.3))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.85, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createOvulatoryBiomarkers(cycleDay: Int) -> VocalBiomarkers {
        // Higher F0 during ovulation (estrogen peak effect)
        let f0Peak = cycleDay == 14 ? 235.0 : 228.0 // Peak on day 14
        let f0 = F0Analysis(mean: f0Peak, std: 12.0, confidence: 88.0)
        let jitter = JitterMeasures(local: 0.6, absolute: 38.0, rap: 0.5, ppq5: 0.7)
        let shimmer = ShimmerMeasures(local: 2.8, db: 0.24, apq3: 2.5, apq5: 2.9)
        let hnr = HNRAnalysis(mean: 21.0, std: 1.8)
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 88.0, components: StabilityComponents(f0Score: 35.2, jitterScore: 17.8, shimmerScore: 17.2, hnrScore: 17.8))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.88, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
    
    private func createLutealBiomarkers(cycleDay: Int) -> VocalBiomarkers {
        // Progressive voice quality degradation during luteal phase (progesterone effect)
        let daysSinceLutealStart = cycleDay - 15
        let f0Decline = Double(daysSinceLutealStart) * 0.5 // Gradual F0 decline
        let f0 = F0Analysis(mean: 220.0 - f0Decline, std: 16.0, confidence: 80.0)
        
        let jitterIncrease = Double(daysSinceLutealStart) * 0.05
        let jitter = JitterMeasures(local: 0.8 + jitterIncrease, absolute: 45.0, rap: 0.7, ppq5: 0.9)
        
        let shimmerIncrease = Double(daysSinceLutealStart) * 0.1
        let shimmer = ShimmerMeasures(local: 3.2 + shimmerIncrease, db: 0.28, apq3: 2.8, apq5: 3.1)
        
        let hnrDecline = Double(daysSinceLutealStart) * 0.2
        let hnr = HNRAnalysis(mean: 19.5 - hnrDecline, std: 2.1)
        
        let voiceQuality = VoiceQualityAnalysis(jitter: jitter, shimmer: shimmer, hnr: hnr)
        let stability = VocalStabilityScore(score: 82.5 - Double(daysSinceLutealStart), components: StabilityComponents(f0Score: 34.0, jitterScore: 16.4, shimmerScore: 15.8, hnrScore: 16.3))
        let metadata = VoiceAnalysisMetadata(recordingDuration: 5.0, sampleRate: 48000, voicedRatio: 0.85, analysisTimestamp: Date(), analysisSource: .hybrid)
        
        return VocalBiomarkers(f0: f0, voiceQuality: voiceQuality, stability: stability, metadata: metadata)
    }
}