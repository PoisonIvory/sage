//
//  OnboardingBaselineTests.swift  
//  SageTests
//
//  Tests for onboarding baseline establishment following TDD/BDD principles
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education  
//  AC-003: Re-record Baseline During Onboarding
//

import XCTest
import Combine
import AVFoundation
@testable import Sage

@MainActor
final class OnboardingBaselineTests: XCTestCase {
    
    private var sut: OnboardingJourneyViewModel!
    private var mockAudioRecorder: MockOnboardingAudioRecorder!
    private var mockPermissionManager: MockMicrophonePermissionManager!
    private var mockAnalysisService: MockHybridVocalAnalysisService!
    private var mockAnalyticsService: MockAnalyticsService!
    private var mockVocalBaselineService: MockVocalBaselineService!
    private var mockUserProfileRepository: MockUserProfileRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockAudioRecorder = MockOnboardingAudioRecorder()
        mockPermissionManager = MockMicrophonePermissionManager()
        mockAnalysisService = MockHybridVocalAnalysisService()
        mockAnalyticsService = MockAnalyticsService()
        mockVocalBaselineService = MockVocalBaselineService()
        mockUserProfileRepository = MockUserProfileRepository()
        
        // Create properly initialized OnboardingJourneyViewModel with domain services
        let mockAuth = MockAuthService()
        mockAuth.currentUserId = "test-user-123"
        
        sut = OnboardingJourneyViewModel(
            analyticsService: mockAnalyticsService,
            authService: mockAuth,
            userProfileRepository: mockUserProfileRepository,
            microphonePermissionManager: mockPermissionManager,
            vocalAnalysisService: mockAnalysisService,
            vocalBaselineService: mockVocalBaselineService,
            coordinator: nil
        )
        
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockAudioRecorder = nil
        mockPermissionManager = nil
        mockAnalysisService = nil
        mockAnalyticsService = nil
        mockVocalBaselineService = nil
        mockUserProfileRepository = nil
        
        try await super.tearDown()
    }
    
    // MARK: - AC-001: Record Initial Vocal Baseline Tests
    
    func testUserRecordsBaselineDuringOnboarding() async throws {
        // Given: User completes onboarding voice recording with valid analysis
        mockPermissionManager.mockPermissionStatus = .authorized
        let mockUserProfile = createUserProfile()
        let mockAnalysis = createAnalysisResult(quality: .good)
        
        sut.userProfile = mockUserProfile
        mockAnalysisService.mockAnalysisResult = mockAnalysis
        mockVocalBaselineService.mockBaseline = createVocalBaseline(quality: .good)
        
        // When: User records baseline during onboarding
        try await sut.establishBaseline()
        
        // Then: Baseline should be established and saved
        XCTAssertTrue(sut.hasEstablishedBaseline)
        XCTAssertNotNil(sut.vocalBaseline)
        XCTAssertEqual(sut.vocalBaseline?.recordingContext, .onboarding)
        XCTAssertTrue(sut.vocalBaseline?.isClinicallValid ?? false)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_baseline_established")
    }
    
    
    func testBaselineValidationFailsWithPoorQuality() async throws {
        // Given: User completes low-quality recording below clinical threshold
        mockPermissionManager.mockPermissionStatus = .authorized
        let mockUserProfile = createUserProfile()
        let poorAnalysis = createAnalysisResult(quality: .poor)
        
        sut.userProfile = mockUserProfile
        mockAnalysisService.mockAnalysisResult = poorAnalysis
        mockVocalBaselineService.shouldThrowError = true
        mockVocalBaselineService.mockError = VocalBaselineError.clinicalValidationFailed(reason: "F0 confidence \(TestConstants.poorConfidence)% below minimum \(TestConstants.minimumClinicalConfidence)%")
        
        // When: User attempts to establish baseline
        do {
            try await sut.establishBaseline()
            XCTFail("Should have thrown error for poor quality baseline")
        } catch VocalBaselineError.clinicalValidationFailed {
            // Then: Baseline should be rejected with clinical reason and contextual guidance
            XCTAssertFalse(sut.hasEstablishedBaseline)
            XCTAssertNil(sut.vocalBaseline)
            XCTAssertNotNil(sut.baselineError)
            XCTAssertTrue(sut.baselineError?.contains("quieter room") ?? false, "Should provide contextual guidance for confidence issues")
        }
    }
    
    func testBaselineEstablishmentFailsWithoutUserProfile() async throws {
        // Given: User has no profile data
        mockPermissionManager.mockPermissionStatus = .authorized
        let mockAnalysis = createAnalysisResult(quality: .good)
        
        sut.userProfile = nil
        mockAnalysisService.mockAnalysisResult = mockAnalysis
        
        // When: User attempts to establish baseline
        do {
            try await sut.establishBaseline()
            XCTFail("Should have thrown error for missing user profile")
        } catch VocalBaselineError.userProfileNotFound {
            // Then: Baseline establishment should fail
            XCTAssertFalse(sut.hasEstablishedBaseline)
            XCTAssertNil(sut.vocalBaseline)
            XCTAssertNotNil(sut.baselineError)
        }
    }
    
    // MARK: - AC-002: Display Baseline Summary and Education Tests
    
    func testUserViewsBaselineSummaryAfterEstablishment() async throws {
        // Given: User has successfully established baseline
        let mockUserProfile = createUserProfile()
        let mockBaseline = createVocalBaseline(quality: .excellent)
        
        sut.userProfile = mockUserProfile
        sut.vocalBaseline = mockBaseline
        sut.hasEstablishedBaseline = true
        
        // When: User views baseline summary
        let baselineSummary = sut.getBaselineSummary()
        
        // Then: Summary should display formatted baseline metrics
        XCTAssertTrue(baselineSummary.contains("F0: \(String(format: "%.1f", TestConstants.excellentF0Mean))Hz"))
        XCTAssertTrue(baselineSummary.contains("Confidence: \(Int(TestConstants.excellentConfidence))%"))
        XCTAssertTrue(baselineSummary.contains("Quality: excellent"))
    }
    
    func testContextualErrorGuidanceForDifferentFailures() async throws {
        // Given: User has profile and various error conditions
        mockPermissionManager.mockPermissionStatus = .authorized  
        let mockUserProfile = createUserProfile()
        sut.userProfile = mockUserProfile
        mockAnalysisService.mockAnalysisResult = createAnalysisResult(quality: .poor)
        mockVocalBaselineService.shouldThrowError = true
        
        // Test confidence-related error guidance
        mockVocalBaselineService.mockError = VocalBaselineError.clinicalValidationFailed(reason: "F0 confidence too low")
        do {
            try await sut.establishBaseline()
        } catch {
            XCTAssertTrue(sut.baselineError?.contains("quieter room") ?? false)
        }
        
        // Reset for next test
        sut.baselineError = nil
        
        // Test duration-related error guidance  
        mockVocalBaselineService.mockError = VocalBaselineError.clinicalValidationFailed(reason: "Recording duration too short")
        do {
            try await sut.establishBaseline()
        } catch {
            XCTAssertTrue(sut.baselineError?.contains("full duration") ?? false)
        }
    }
    
    // MARK: - AC-003: Re-record Baseline During Onboarding Tests
    
    func testUserReRecordsBaselineAfterFailure() async throws {
        // Given: User's first baseline attempt fails
        mockPermissionManager.mockPermissionStatus = .authorized
        let mockUserProfile = createUserProfile()
        
        sut.userProfile = mockUserProfile
        sut.baselineError = "Clinical validation failed"
        sut.hasCompletedRecording = true
        
        // When: User chooses to re-record
        await sut.reRecordBaseline()
        
        // Then: Recording state should reset for new attempt
        XCTAssertFalse(sut.hasCompletedRecording)
        XCTAssertFalse(sut.shouldShowNextButton)
        XCTAssertNil(sut.currentAnalysisResult)
        XCTAssertNil(sut.baselineError)
        XCTAssertNil(sut.successMessage)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_baseline_re_record_requested")
    }
    
    func testUserCompletesOnboardingWithBaseline() async throws {
        // Given: User has established baseline
        let mockUserProfile = createUserProfile()
        let mockBaseline = createVocalBaseline(quality: .good)
        
        sut.userProfile = mockUserProfile
        sut.vocalBaseline = mockBaseline
        sut.hasEstablishedBaseline = true
        
        // When: User completes onboarding
        await sut.completeOnboarding()
        
        // Then: Onboarding should be marked complete with baseline context
        XCTAssertTrue(sut.onboardingComplete)
        XCTAssertEqual(mockAnalyticsService.lastLoggedEvent, "onboarding_completed_with_baseline")
        
        // Verify analytics properties contain baseline data
        let properties = mockAnalyticsService.lastLoggedProperties
        XCTAssertEqual(properties["has_baseline"] as? Bool, true)
        XCTAssertEqual(properties["baseline_quality"] as? String, "good")
    }
    

    // MARK: - Test Data Factory
    
    private struct TestConstants {
        static let validF0Mean: Double = 220.0
        static let validF0Std: Double = 15.0
        static let validConfidence: Double = 85.0
        static let excellentF0Mean: Double = 215.0
        static let excellentF0Std: Double = 8.5
        static let excellentConfidence: Double = 92.0
        static let poorF0Mean: Double = 180.0
        static let poorF0Std: Double = 25.0
        static let poorConfidence: Double = 35.0
        static let minimumClinicalConfidence: Double = 50.0
        static let validRecordingDuration: Double = 5.0
        static let shortRecordingDuration: Double = 2.5
        static let validVoicedRatio: Double = 0.75
        static let lowVoicedRatio: Double = 0.4
    }
    
    private func createUserProfile(age: Int = 25, gender: String = "female") -> UserProfile {
        return UserProfile(
            id: UUID().uuidString,
            age: age,
            gender: gender,
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            createdAt: Date()
        )
    }
    
    private func createAnalysisResult(quality: VoiceQuality) -> VocalAnalysisResult {
        let (f0Mean, f0Std, confidence) = metricsForQuality(quality)
        return VocalAnalysisResult(
            recordingId: UUID(),
            localMetrics: BasicVoiceMetrics(
                f0Mean: f0Mean,
                f0Std: f0Std,
                confidence: confidence,
                analysisDate: Date()
            ),
            comprehensiveAnalysis: createVocalBiomarkers(quality: quality),
            status: .comprehensiveComplete
        )
    }
    
    private func metricsForQuality(_ quality: VoiceQuality) -> (Double, Double, Double) {
        switch quality {
        case .excellent:
            return (TestConstants.excellentF0Mean, TestConstants.excellentF0Std, TestConstants.excellentConfidence)
        case .good:
            return (TestConstants.validF0Mean, TestConstants.validF0Std, TestConstants.validConfidence)
        case .poor:
            return (TestConstants.poorF0Mean, TestConstants.poorF0Std, TestConstants.poorConfidence)
        }
    }
    
    private enum VoiceQuality {
        case excellent, good, poor
    }
    
    private func createVocalBiomarkers(quality: VoiceQuality) -> VocalBiomarkers {
        let (f0Mean, f0Std, confidence) = metricsForQuality(quality)
        let (stabilityLevel, overallQuality, stabilityScore, voicedRatio, duration, clinicalNotes) = clinicalParametersForQuality(quality)
        
        return VocalBiomarkers(
            f0: F0Analysis(
                mean: f0Mean,
                std: f0Std,
                confidence: confidence,
                stabilityLevel: stabilityLevel
            ),
            voiceQuality: VoiceQualityAnalysis(
                jitter: jitterForQuality(quality),
                shimmer: shimmerForQuality(quality),
                hnr: hnrForQuality(quality),
                overallQuality: overallQuality
            ),
            stability: VocalStabilityScore(score: stabilityScore, components: StabilityComponents(), interpretation: stabilityLevel),
            metadata: VoiceAnalysisMetadata(
                recordingDuration: duration,
                voicedRatio: voicedRatio,
                analysisDate: Date()
            ),
            clinicalSummary: ClinicalVoiceAssessment(
                overallQuality: overallQuality,
                f0Stability: stabilityLevel,
                recommendedAction: quality == .poor ? .reRecord : .continueMonitoring,
                clinicalNotes: clinicalNotes
            )
        )
    }
    
    private func clinicalParametersForQuality(_ quality: VoiceQuality) -> (F0StabilityLevel, VoiceQualityLevel, Double, Double, Double, String) {
        switch quality {
        case .excellent:
            return (.veryStable, .excellent, 95.0, 0.85, TestConstants.validRecordingDuration, "Excellent baseline quality")
        case .good:
            return (.stable, .good, 82.0, TestConstants.validVoicedRatio, TestConstants.validRecordingDuration, "Baseline established successfully")
        case .poor:
            return (.unstable, .poor, 45.0, TestConstants.lowVoicedRatio, TestConstants.shortRecordingDuration, "Poor recording quality")
        }
    }
    
    private func jitterForQuality(_ quality: VoiceQuality) -> JitterMeasures {
        switch quality {
        case .excellent: return JitterMeasures(local: 0.5, absolute: 0.4, rap: 0.3, ppq5: 0.6)
        case .good: return JitterMeasures(local: 0.8, absolute: 0.6, rap: 0.5, ppq5: 0.7)
        case .poor: return JitterMeasures(local: 2.5, absolute: 2.0, rap: 1.8, ppq5: 2.8)
        }
    }
    
    private func shimmerForQuality(_ quality: VoiceQuality) -> ShimmerMeasures {
        switch quality {
        case .excellent: return ShimmerMeasures(local: 1.8, db: 1.5, apq3: 1.7, apq5: 2.0)
        case .good: return ShimmerMeasures(local: 2.5, db: 2.1, apq3: 2.3, apq5: 2.7)
        case .poor: return ShimmerMeasures(local: 8.0, db: 7.5, apq3: 7.8, apq5: 8.2)
        }
    }
    
    private func hnrForQuality(_ quality: VoiceQuality) -> HNRAnalysis {
        switch quality {
        case .excellent: return HNRAnalysis(mean: 25.0, std: 1.2)
        case .good: return HNRAnalysis(mean: 22.0, std: 1.8)
        case .poor: return HNRAnalysis(mean: 12.0, std: 4.0)
        }
    }
    
    private func createVocalBaseline(quality: VoiceQuality = .good, demographic: VoiceDemographic = .adultFemale) -> VocalBaseline {
        return VocalBaseline(
            userId: UUID(),
            establishedAt: Date(),
            biomarkers: createVocalBiomarkers(quality: quality),
            demographic: demographic,
            recordingContext: .onboarding
        )
    }
}

// MARK: - Mock Vocal Baseline Service

class MockVocalBaselineService: VocalBaselineServiceProtocol {
    var mockBaseline: VocalBaseline?
    var shouldThrowError = false
    var mockError: Error?
    
    func establishBaseline(
        from analysis: VocalAnalysisResult,
        userId: UUID,
        userProfile: UserProfile
    ) async throws -> VocalBaseline {
        if shouldThrowError {
            throw mockError ?? VocalBaselineError.clinicalValidationFailed(reason: "Mock error")
        }
        return mockBaseline ?? createVocalBaseline(quality: .good)
    }
    
    func validateBaseline(_ baseline: VocalBaseline) -> BaselineValidationResult {
        return BaselineValidationResult(
            isValid: true,
            clinicalQuality: .good,
            confidenceScore: 85.0
        )
    }
    
    func getCurrentBaseline(for userId: UUID) async throws -> VocalBaseline? {
        return mockBaseline
    }
    
    private func createVocalBaseline(quality: VoiceQuality = .good) -> VocalBaseline {
        return VocalBaseline(
            userId: UUID(),
            establishedAt: Date(),
            biomarkers: createVocalBiomarkers(quality: quality),
            demographic: .adultFemale,
            recordingContext: .onboarding
        )
    }
}

// MARK: - Mock Analytics Service

class MockAnalyticsService: AnalyticsServiceProtocol {
    var lastLoggedEvent: String?
    var lastLoggedProperties: [String: Any] = [:]
    
    func track(_ eventName: String, properties: [String: Any], origin: String) {
        lastLoggedEvent = eventName
        lastLoggedProperties = properties
    }
    
    func identifyUser(userId: String, userProfile: UserProfile) {
        // Mock implementation
    }
}

// MARK: - Mock User Profile Repository

class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
    
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        completion(nil)
    }
}