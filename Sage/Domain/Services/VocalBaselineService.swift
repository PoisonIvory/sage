//
//  VocalBaselineService.swift
//  Sage
//
//  Domain service for vocal baseline establishment following DDD principles
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation

// MARK: - Vocal Baseline Service Protocol

/// Domain service for establishing and managing vocal baselines
/// - Handles baseline creation, validation, and persistence
/// - Follows single responsibility principle
/// - Uses dependency injection for testability
protocol VocalBaselineServiceProtocol {
    /// Establishes a vocal baseline from analysis results
    /// - Parameter analysis: Voice analysis result containing biomarkers
    /// - Parameter userId: Authenticated user identifier
    /// - Parameter userProfile: User profile containing demographic data
    /// - Returns: Validated vocal baseline
    /// - Throws: VocalBaselineError if validation fails
    func establishBaseline(
        from analysis: VocalAnalysisResult,
        userId: UUID,
        userProfile: UserProfile
    ) async throws -> VocalBaseline
    
    /// Validates if a baseline meets clinical standards
    /// - Parameter baseline: Baseline to validate
    /// - Returns: Validation result with clinical assessment
    func validateBaseline(_ baseline: VocalBaseline) -> BaselineValidationResult
    
    /// Retrieves user's current baseline
    /// - Parameter userId: User identifier
    /// - Returns: Current baseline or nil if none exists
    func getCurrentBaseline(for userId: UUID) async throws -> VocalBaseline?
}

// MARK: - Vocal Baseline Service Implementation

final class VocalBaselineService: VocalBaselineServiceProtocol {
    
    // MARK: - Dependencies
    
    private let validationService: BaselineValidationServiceProtocol
    private let repository: VocalBaselineRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let logger: StructuredLogger
    
    // MARK: - Initialization
    
    init(
        validationService: BaselineValidationServiceProtocol,
        repository: VocalBaselineRepositoryProtocol,
        userProfileRepository: UserProfileRepositoryProtocol,
        logger: StructuredLogger = StructuredLogger(component: "VocalBaselineService")
    ) {
        self.validationService = validationService
        self.repository = repository
        self.userProfileRepository = userProfileRepository
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    func establishBaseline(
        from analysis: VocalAnalysisResult,
        userId: UUID,
        userProfile: UserProfile
    ) async throws -> VocalBaseline {
        
        logger.debug("[VocalBaselineService] Establishing baseline for user: \(userId)")
        
        // Validate analysis result
        guard let comprehensiveAnalysis = analysis.comprehensiveAnalysis else {
            logger.error("[VocalBaselineService] Analysis incomplete for baseline establishment")
            throw VocalBaselineError.incompleteAnalysis
        }
        
        // Extract demographic data from user profile
        let demographic = extractVoiceDemographic(from: userProfile)
        
        // Create baseline with real data
        let baseline = VocalBaseline(
            userId: userId,
            establishedAt: Date(),
            biomarkers: comprehensiveAnalysis,
            demographic: demographic,
            recordingContext: .onboarding
        )
        
        // Validate baseline meets clinical standards
        let validationResult = validateBaseline(baseline)
        
        guard validationResult.isValid else {
            logger.error("[VocalBaselineService] Baseline validation failed: \(validationResult.rejectionReason ?? "Unknown")")
            throw VocalBaselineError.clinicalValidationFailed(
                reason: validationResult.rejectionReason ?? "Baseline does not meet clinical standards"
            )
        }
        
        // Persist baseline
        try await repository.saveBaseline(baseline)
        
        logger.info("[VocalBaselineService] Baseline established successfully for user: \(userId)")
        
        return baseline
    }
    
    func validateBaseline(_ baseline: VocalBaseline) -> BaselineValidationResult {
        return validationService.validateBaseline(baseline)
    }
    
    func getCurrentBaseline(for userId: UUID) async throws -> VocalBaseline? {
        return try await repository.getCurrentBaseline(for: userId)
    }
    
    func getArchivedBaselines(for userId: UUID) async throws -> [ArchivedBaseline] {
        return try await repository.getBaselineHistory(for: userId)
    }
    
    // MARK: - Private Methods
    
    /// Extracts voice demographic from user profile using real data
    /// - Parameter userProfile: User profile containing demographic information
    /// - Returns: Voice demographic for baseline calculation
    private func extractVoiceDemographic(from userProfile: UserProfile) -> VoiceDemographic {
        
        // Use real age from user profile
        let age = userProfile.age
        
        // Use real gender from user profile
        let gender = userProfile.gender
        
        // Calculate demographic based on real data
        switch (age, gender) {
        case (0..<18, _):
            return .adolescent
        case (18..<65, "female"):
            return .adultFemale
        case (18..<65, "male"):
            return .adultMale
        case (18..<65, _):
            return .adultOther
        case (65..., "female"):
            return .seniorFemale
        case (65..., "male"):
            return .seniorMale
        case (65..., _):
            return .seniorOther
        default:
            // Fallback for missing data - this should be rare in production
            logger.warning("[VocalBaselineService] Using fallback demographic for user: \(userProfile.id)")
            return .adultOther
        }
    }
}



 