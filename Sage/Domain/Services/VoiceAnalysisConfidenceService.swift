import Foundation

// MARK: - Voice Analysis Confidence Service

/// Domain service for calculating voice analysis confidence adjustments
/// - Encapsulates voice condition and medical condition impact on analysis
/// - Follows DDD principles by separating voice analysis concerns
/// - Provides clear bounded context for voice analysis domain logic
public protocol VoiceAnalysisConfidenceServiceProtocol {
    /// Calculates confidence adjustment based on user profile conditions
    /// - Parameter userProfile: User profile containing condition data
    /// - Returns: Confidence adjustment factor (0.6-1.0)
    func calculateConfidenceAdjustment(for userProfile: UserProfile) -> Double
    
    /// Determines if user has conditions that significantly impact voice analysis
    /// - Parameter userProfile: User profile containing condition data
    /// - Returns: True if conditions may affect analysis accuracy
    func hasSignificantVoiceImpact(for userProfile: UserProfile) -> Bool
    
    /// Gets recommended minimum confidence threshold for analysis
    /// - Parameter userProfile: User profile containing condition data
    /// - Returns: Minimum confidence threshold (0.5-0.95)
    func recommendedConfidenceThreshold(for userProfile: UserProfile) -> Double
}

// MARK: - Voice Analysis Confidence Service Implementation

public final class VoiceAnalysisConfidenceService: VoiceAnalysisConfidenceServiceProtocol {
    
    // MARK: - Configuration
    
    private struct ConfidenceFactors {
        static let laryngitis: Double = 0.6
        static let vocalCordDysfunction: Double = 0.7
        static let hoarseness: Double = 0.8
        static let hormonalConditions: Double = 0.9
        static let otherConditions: Double = 0.75
        static let noConditions: Double = 1.0
    }
    
    private struct Thresholds {
        static let highImpact: Double = 0.85
        static let mediumImpact: Double = 0.75
        static let lowImpact: Double = 0.65
        static let noImpact: Double = 0.5
    }
    
    // MARK: - Public Methods
    
    public func calculateConfidenceAdjustment(for userProfile: UserProfile) -> Double {
        // No adjustment needed if no conditions
        if hasNoVoiceConditions(userProfile) && !hasHormonalConditions(userProfile) {
            return ConfidenceFactors.noConditions
        }
        
        // Apply most conservative adjustment for voice conditions
        if let voiceAdjustment = calculateVoiceConditionAdjustment(userProfile) {
            return voiceAdjustment
        }
        
        // Apply hormonal condition adjustment
        if hasHormonalConditions(userProfile) {
            return ConfidenceFactors.hormonalConditions
        }
        
        // Default for other conditions
        return ConfidenceFactors.otherConditions
    }
    
    public func hasSignificantVoiceImpact(for userProfile: UserProfile) -> Bool {
        return !hasNoVoiceConditions(userProfile) || hasHormonalConditions(userProfile)
    }
    
    public func recommendedConfidenceThreshold(for userProfile: UserProfile) -> Double {
        let adjustment = calculateConfidenceAdjustment(for: userProfile)
        
        switch adjustment {
        case ConfidenceFactors.laryngitis:
            return Thresholds.highImpact
        case ConfidenceFactors.vocalCordDysfunction:
            return Thresholds.mediumImpact
        case ConfidenceFactors.hoarseness, ConfidenceFactors.otherConditions:
            return Thresholds.lowImpact
        default:
            return Thresholds.noImpact
        }
    }
    
    // MARK: - Private Methods
    
    private func hasNoVoiceConditions(_ userProfile: UserProfile) -> Bool {
        return userProfile.voiceConditions.contains("None")
    }
    
    private func hasHormonalConditions(_ userProfile: UserProfile) -> Bool {
        let hormonalConditions = ["PMDD", "PCOS", "Endometriosis", "Perimenopause"]
        return userProfile.diagnosedConditions.contains { hormonalConditions.contains($0) } ||
               userProfile.suspectedConditions.contains { hormonalConditions.contains($0) }
    }
    
    private func calculateVoiceConditionAdjustment(_ userProfile: UserProfile) -> Double? {
        // Return most conservative (lowest) adjustment for multiple conditions
        var adjustments: [Double] = []
        
        if userProfile.voiceConditions.contains("Laryngitis") {
            adjustments.append(ConfidenceFactors.laryngitis)
        }
        
        if userProfile.voiceConditions.contains("Vocal Cord Dysfunction") {
            adjustments.append(ConfidenceFactors.vocalCordDysfunction)
        }
        
        if userProfile.voiceConditions.contains("Hoarseness") {
            adjustments.append(ConfidenceFactors.hoarseness)
        }
        
        // Check for other non-"None" conditions
        let otherConditions = userProfile.voiceConditions.filter { 
            !["None", "Laryngitis", "Vocal Cord Dysfunction", "Hoarseness"].contains($0) 
        }
        if !otherConditions.isEmpty {
            adjustments.append(ConfidenceFactors.otherConditions)
        }
        
        return adjustments.min() // Most conservative adjustment
    }
}

// MARK: - UserProfile Extension for Voice Analysis

/// Extension to UserProfile that delegates voice analysis logic to the service
extension UserProfile {
    
    /// Whether user has conditions that impact voice analysis
    /// - Note: Delegates to VoiceAnalysisConfidenceService for separation of concerns
    public var hasVoiceImpactingConditions: Bool {
        let service = VoiceAnalysisConfidenceService()
        return service.hasSignificantVoiceImpact(for: self)
    }
    
    /// Confidence adjustment for voice analysis (0.6-1.0)
    /// - Note: Delegates to VoiceAnalysisConfidenceService for separation of concerns
    public var analysisConfidenceAdjustment: Double {
        let service = VoiceAnalysisConfidenceService()
        return service.calculateConfidenceAdjustment(for: self)
    }
    
    /// Whether user has hormonal conditions
    /// - Note: This could also be moved to a medical condition service in the future
    public var hasHormonalConditions: Bool {
        let hormonalConditions = ["PMDD", "PCOS", "Endometriosis", "Perimenopause"]
        return diagnosedConditions.contains { hormonalConditions.contains($0) } ||
               suspectedConditions.contains { hormonalConditions.contains($0) }
    }
}