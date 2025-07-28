import XCTest
@testable import Sage

// MARK: - Comprehensive Test Suite for VocalBiomarkers Domain Models

class VocalBiomarkersTests: XCTestCase {
    
    // MARK: - F0Analysis Tests
    
    /// GWT: Given clinical F0 values for adult female
    /// GWT: When validating against clinical ranges
    /// GWT: Then should correctly identify normal vs abnormal values
    func testF0AnalysisValidation() {
        // Given: Normal adult female F0 values
        let normalF0 = F0Analysis(mean: 220.0, std: 15.0, confidence: 85.0)
        
        // When: Validating against adult female clinical range
        let isValid = normalF0.isWithinClinicalRange(for: .adultFemale)
        
        // Then: Should validate as within normal range (165-400 Hz)
        XCTAssertTrue(isValid, "Normal adult female F0 should be within clinical range")
        
        // Given: Pathological F0 values
        let pathologicalF0Low = F0Analysis(mean: 120.0, std: 5.0, confidence: 90.0)
        let pathologicalF0High = F0Analysis(mean: 450.0, std: 20.0, confidence: 80.0)
        
        // When: Validating pathological values
        let isLowValid = pathologicalF0Low.isWithinClinicalRange(for: .adultFemale)
        let isHighValid = pathologicalF0High.isWithinClinicalRange(for: .adultFemale)
        
        // Then: Should identify as outside clinical range
        XCTAssertFalse(isLowValid, "Low F0 should be outside adult female range")
        XCTAssertFalse(isHighValid, "High F0 should be outside adult female range")
    }
    
    /// GWT: Given F0 stability assessment requirements
    /// GWT: When evaluating F0 standard deviation
    /// GWT: Then should classify stability levels correctly
    func testF0StabilityAssessment() {
        // Given: Excellent stability (low std deviation)
        let excellentF0 = F0Analysis(mean: 220.0, std: 8.0, confidence: 90.0)
        
        // When: Assessing stability
        let excellentStability = excellentF0.stabilityAssessment
        
        // Then: Should classify as excellent
        XCTAssertEqual(excellentStability, .excellent, "Low std deviation should indicate excellent stability")
        
        // Given: Poor stability (high std deviation)
        let poorF0 = F0Analysis(mean: 220.0, std: 40.0, confidence: 85.0)
        
        // When: Assessing stability
        let poorStability = poorF0.stabilityAssessment
        
        // Then: Should classify as poor
        XCTAssertEqual(poorStability, .poor, "High std deviation should indicate poor stability")
        
        // Given: Low confidence recording
        let lowConfidenceF0 = F0Analysis(mean: 220.0, std: 5.0, confidence: 45.0)
        
        // When: Assessing stability
        let unreliableStability = lowConfidenceF0.stabilityAssessment
        
        // Then: Should classify as unreliable due to low confidence
        XCTAssertEqual(unreliableStability, .unreliable, "Low confidence should indicate unreliable assessment")
    }
    
    // MARK: - JitterMeasures Tests
    
    /// GWT: Given research-grade jitter thresholds
    /// GWT: When assessing jitter measurements
    /// GWT: Then should classify according to clinical standards (Farrús et al., 2007)
    func testJitterClinicalAssessment() {
        // Given: Excellent jitter values (<1.04% local, <1.0% RAP)
        let excellentJitter = JitterMeasures(local: 0.8, absolute: 15.0, rap: 0.7, ppq5: 0.9)
        
        // When: Assessing clinical level
        let excellentAssessment = excellentJitter.clinicalAssessment
        
        // Then: Should classify as excellent
        XCTAssertEqual(excellentAssessment, .excellent, "Low jitter values should indicate excellent voice quality")
        
        // Given: Pathological jitter values (>8% local, >5% RAP)
        let pathologicalJitter = JitterMeasures(local: 12.0, absolute: 800.0, rap: 8.0, ppq5: 15.0)
        
        // When: Assessing clinical level
        let pathologicalAssessment = pathologicalJitter.clinicalAssessment
        
        // Then: Should classify as pathological
        XCTAssertEqual(pathologicalAssessment, .pathological, "High jitter values should indicate pathological voice quality")
    }
    
    // MARK: - ShimmerMeasures Tests
    
    /// GWT: Given research-grade shimmer thresholds
    /// GWT: When assessing shimmer measurements  
    /// GWT: Then should classify according to clinical standards (Farrús et al., 2007)
    func testShimmerClinicalAssessment() {
        // Given: Excellent shimmer values (<3.81% local, <3.0% APQ3)
        let excellentShimmer = ShimmerMeasures(local: 2.5, db: 0.25, apq3: 2.0, apq5: 2.8)
        
        // When: Assessing clinical level
        let excellentAssessment = excellentShimmer.clinicalAssessment
        
        // Then: Should classify as excellent
        XCTAssertEqual(excellentAssessment, .excellent, "Low shimmer values should indicate excellent voice quality")
        
        // Given: Good shimmer values (3.81-6% local, 3-5% APQ3)  
        let goodShimmer = ShimmerMeasures(local: 5.0, db: 0.5, apq3: 4.0, apq5: 5.5)
        
        // When: Assessing clinical level
        let goodAssessment = goodShimmer.clinicalAssessment
        
        // Then: Should classify as good
        XCTAssertEqual(goodAssessment, .good, "Moderate shimmer values should indicate good voice quality")
    }
    
    // MARK: - HNRAnalysis Tests
    
    /// GWT: Given HNR clinical thresholds for voice quality
    /// GWT: When assessing harmonics-to-noise ratio
    /// GWT: Then should classify according to research standards
    func testHNRClinicalAssessment() {
        // Given: Excellent HNR (>20 dB)
        let excellentHNR = HNRAnalysis(mean: 22.0, std: 2.0)
        
        // When: Assessing clinical level
        let excellentAssessment = excellentHNR.clinicalAssessment
        
        // Then: Should classify as excellent
        XCTAssertEqual(excellentAssessment, .excellent, "High HNR should indicate excellent voice quality")
        
        // Given: Poor HNR (<10 dB but >7 dB)
        let poorHNR = HNRAnalysis(mean: 8.5, std: 3.0)
        
        // When: Assessing clinical level
        let poorAssessment = poorHNR.clinicalAssessment
        
        // Then: Should classify as poor
        XCTAssertEqual(poorAssessment, .poor, "Low HNR should indicate poor voice quality")
        
        // Given: Pathological HNR (<7 dB)
        let pathologicalHNR = HNRAnalysis(mean: 5.0, std: 4.0)
        
        // When: Assessing clinical level
        let pathologicalAssessment = pathologicalHNR.clinicalAssessment
        
        // Then: Should classify as pathological
        XCTAssertEqual(pathologicalAssessment, .pathological, "Very low HNR should indicate pathological voice quality")
    }
    
    // MARK: - VoiceQualityAnalysis Tests
    
    /// GWT: Given comprehensive voice quality analysis
    /// GWT: When combining jitter, shimmer, and HNR assessments
    /// GWT: Then overall quality should reflect worst component (conservative assessment)
    func testVoiceQualityOverallAssessment() {
        // Given: Mixed quality components (excellent jitter, poor shimmer, good HNR)
        let excellentJitter = JitterMeasures(local: 0.5, absolute: 10.0, rap: 0.4, ppq5: 0.6)
        let poorShimmer = ShimmerMeasures(local: 12.0, db: 1.2, apq3: 10.0, apq5: 14.0)
        let goodHNR = HNRAnalysis(mean: 16.0, std: 2.5)
        
        let mixedQuality = VoiceQualityAnalysis(jitter: excellentJitter, shimmer: poorShimmer, hnr: goodHNR)
        
        // When: Assessing overall quality
        let overallQuality = mixedQuality.qualityLevel
        
        // Then: Should reflect worst component (conservative assessment)
        XCTAssertEqual(overallQuality, .poor, "Overall quality should reflect worst component for conservative clinical assessment")
    }
    
    // MARK: - VocalStabilityScore Tests
    
    /// GWT: Given vocal stability score requirements
    /// GWT: When interpreting composite score
    /// GWT: Then should provide user-friendly assessment levels
    func testVocalStabilityInterpretation() {
        // Given: Excellent stability score
        let excellentComponents = StabilityComponents(f0Score: 90.0, jitterScore: 85.0, shimmerScore: 88.0, hnrScore: 92.0)
        let excellentStability = VocalStabilityScore(score: 88.0, components: excellentComponents)
        
        // When: Getting interpretation
        let excellentInterpretation = excellentStability.interpretation
        
        // Then: Should classify as excellent
        XCTAssertEqual(excellentInterpretation, .excellent, "High stability score should indicate excellent interpretation")
        
        // Given: Poor stability score
        let poorComponents = StabilityComponents(f0Score: 25.0, jitterScore: 30.0, shimmerScore: 28.0, hnrScore: 35.0)
        let poorStability = VocalStabilityScore(score: 35.0, components: poorComponents)
        
        // When: Getting interpretation
        let poorInterpretation = poorStability.interpretation
        
        // Then: Should classify as poor
        XCTAssertEqual(poorInterpretation, .poor, "Low stability score should indicate poor interpretation")
    }
    
    // MARK: - VocalBiomarkers Integration Tests
    
    /// GWT: Given complete vocal biomarkers analysis
    /// GWT: When generating clinical summary for PMDD/PCOS screening
    /// GWT: Then should provide appropriate clinical recommendations
    func testVocalBiomarkersClinicalSummary() {
        // Given: Normal voice characteristics for adult female
        let normalF0 = F0Analysis(mean: 220.0, std: 12.0, confidence: 85.0)
        let normalJitter = JitterMeasures(local: 0.8, absolute: 15.0, rap: 0.6, ppq5: 0.9)
        let normalShimmer = ShimmerMeasures(local: 3.0, db: 0.3, apq3: 2.5, apq5: 3.2)
        let normalHNR = HNRAnalysis(mean: 18.0, std: 2.0)
        let normalQuality = VoiceQualityAnalysis(jitter: normalJitter, shimmer: normalShimmer, hnr: normalHNR)
        
        let goodComponents = StabilityComponents(f0Score: 85.0, jitterScore: 80.0, shimmerScore: 82.0, hnrScore: 78.0)
        let normalStability = VocalStabilityScore(score: 82.0, components: goodComponents)
        
        let metadata = VoiceAnalysisMetadata(
            recordingDuration: 3.0,
            sampleRate: 48000.0,
            voicedRatio: 0.85,
            analysisTimestamp: Date(),
            analysisSource: .hybrid
        )
        
        let normalBiomarkers = VocalBiomarkers(
            f0: normalF0,
            voiceQuality: normalQuality,
            stability: normalStability,
            metadata: metadata
        )
        
        // When: Generating clinical summary
        let clinicalSummary = normalBiomarkers.clinicalSummary
        
        // Then: Should recommend continued tracking for normal voice
        XCTAssertEqual(clinicalSummary.recommendedAction, .continueTracking, "Normal voice characteristics should recommend continued tracking")
        XCTAssertEqual(clinicalSummary.overallQuality, .good, "Normal voice should be assessed as good quality")
        
        // Given: Pathological voice characteristics
        let pathologicalJitter = JitterMeasures(local: 15.0, absolute: 1000.0, rap: 12.0, ppq5: 18.0)
        let pathologicalShimmer = ShimmerMeasures(local: 20.0, db: 2.0, apq3: 18.0, apq5: 22.0)
        let pathologicalHNR = HNRAnalysis(mean: 4.0, std: 5.0)
        let pathologicalQuality = VoiceQualityAnalysis(jitter: pathologicalJitter, shimmer: pathologicalShimmer, hnr: pathologicalHNR)
        
        let pathologicalComponents = StabilityComponents(f0Score: 15.0, jitterScore: 10.0, shimmerScore: 12.0, hnrScore: 8.0)
        let pathologicalStability = VocalStabilityScore(score: 15.0, components: pathologicalComponents)
        
        let pathologicalBiomarkers = VocalBiomarkers(
            f0: normalF0,
            voiceQuality: pathologicalQuality,
            stability: pathologicalStability,
            metadata: metadata
        )
        
        // When: Generating clinical summary for pathological voice
        let pathologicalSummary = pathologicalBiomarkers.clinicalSummary
        
        // Then: Should recommend specialist consultation
        XCTAssertEqual(pathologicalSummary.recommendedAction, .consultSpecialist, "Pathological voice should recommend specialist consultation")
        XCTAssertEqual(pathologicalSummary.overallQuality, .pathological, "Pathological voice should be assessed as pathological quality")
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    /// GWT: Given edge case inputs for robust validation
    /// GWT: When processing boundary conditions
    /// GWT: Then should handle gracefully without crashes
    func testEdgeCaseValidation() {
        // Given: Zero values (analysis failure case)
        let zeroF0 = F0Analysis(mean: 0.0, std: 0.0, confidence: 0.0)
        
        // When: Assessing stability
        let zeroStability = zeroF0.stabilityAssessment
        
        // Then: Should classify as unreliable
        XCTAssertEqual(zeroStability, .unreliable, "Zero confidence should indicate unreliable assessment")
        
        // Given: Extreme values
        let extremeJitter = JitterMeasures(local: 999.0, absolute: 99999.0, rap: 999.0, ppq5: 999.0)
        
        // When: Assessing extreme jitter
        let extremeAssessment = extremeJitter.clinicalAssessment
        
        // Then: Should classify as pathological
        XCTAssertEqual(extremeAssessment, .pathological, "Extreme jitter values should be classified as pathological")
    }
    
    // MARK: - Codable Conformance Tests
    
    /// GWT: Given domain models need persistence
    /// GWT: When encoding and decoding VocalBiomarkers
    /// GWT: Then should maintain data integrity
    func testVocalBiomarkersCodableConformance() throws {
        // Given: Complete VocalBiomarkers instance
        let originalF0 = F0Analysis(mean: 220.0, std: 15.0, confidence: 85.0)
        let originalJitter = JitterMeasures(local: 0.8, absolute: 15.0, rap: 0.6, ppq5: 0.9)
        let originalShimmer = ShimmerMeasures(local: 3.0, db: 0.3, apq3: 2.5, apq5: 3.2)
        let originalHNR = HNRAnalysis(mean: 18.0, std: 2.0)
        let originalQuality = VoiceQualityAnalysis(jitter: originalJitter, shimmer: originalShimmer, hnr: originalHNR)
        
        let originalComponents = StabilityComponents(f0Score: 85.0, jitterScore: 80.0, shimmerScore: 82.0, hnrScore: 78.0)
        let originalStability = VocalStabilityScore(score: 82.0, components: originalComponents)
        
        let originalMetadata = VoiceAnalysisMetadata(
            recordingDuration: 3.0,
            sampleRate: 48000.0,
            voicedRatio: 0.85,
            analysisTimestamp: Date(),
            analysisSource: .hybrid
        )
        
        let originalBiomarkers = VocalBiomarkers(
            f0: originalF0,
            voiceQuality: originalQuality,
            stability: originalStability,
            metadata: originalMetadata
        )
        
        // When: Encoding and decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(originalBiomarkers)
        let decodedBiomarkers = try decoder.decode(VocalBiomarkers.self, from: encodedData)
        
        // Then: Should maintain data integrity
        XCTAssertEqual(originalBiomarkers, decodedBiomarkers, "Encoded and decoded VocalBiomarkers should be equal")
        XCTAssertEqual(originalBiomarkers.f0.mean, decodedBiomarkers.f0.mean, accuracy: 0.001, "F0 mean should be preserved")
        XCTAssertEqual(originalBiomarkers.voiceQuality.jitter.local, decodedBiomarkers.voiceQuality.jitter.local, accuracy: 0.001, "Jitter values should be preserved")
    }
}