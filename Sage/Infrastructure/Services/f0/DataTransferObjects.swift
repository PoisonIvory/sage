import Foundation
import FirebaseFirestore

// MARK: - Data Transfer Objects (DTOs)

/// Abstract data transfer objects to decouple domain from infrastructure
/// - Represents clean domain models independent of storage format
/// - Enables easy testing and backend switching
/// - Provides type-safe data access

// MARK: - Insight DTO

struct InsightDTO {
    let id: String
    let featureType: SpeechFeatureType
    let value: Double
    let confidence: Double
    let metadata: SpeechFeatureMetadata?
    let status: InsightStatus
    let createdAt: Date
    let errorType: String?
    
    enum InsightStatus: String {
        case processing = "processing"
        case completed = "completed"
        case completedWithWarnings = "completed_with_warnings"
        case failed = "failed"
    }
}

// MARK: - Recording DTO

struct RecordingDTO {
    let id: String
    let userID: String
    let task: String
    let sessionTime: Date
    let insights: [InsightDTO]
}

// MARK: - Feature Result DTO

struct FeatureResultDTO {
    let featureType: SpeechFeatureType
    let value: Double
    let confidence: Double
    let metadata: SpeechFeatureMetadata?
    let isValid: Bool
    let validationErrors: [String]
    
    init(
        featureType: SpeechFeatureType,
        value: Double,
        confidence: Double,
        metadata: SpeechFeatureMetadata? = nil
    ) {
        self.featureType = featureType
        self.value = value
        self.confidence = confidence
        self.metadata = metadata
        
        // Validate the result after all properties are initialized
        let validator = FeatureResultValidator()
        let validation = validator.validate(FeatureResultDTO(
            featureType: featureType,
            value: value,
            confidence: confidence,
            metadata: metadata,
            isValid: false, // Temporary value for validation
            validationErrors: [] // Temporary value for validation
        ))
        self.isValid = validation.isValid
        self.validationErrors = validation.errors
    }
    
    // Private initializer for validation
    private init(
        featureType: SpeechFeatureType,
        value: Double,
        confidence: Double,
        metadata: SpeechFeatureMetadata?,
        isValid: Bool,
        validationErrors: [String]
    ) {
        self.featureType = featureType
        self.value = value
        self.confidence = confidence
        self.metadata = metadata
        self.isValid = isValid
        self.validationErrors = validationErrors
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    
    static let valid = ValidationResult(isValid: true, errors: [], warnings: [])
    
    static func invalid(errors: [String], warnings: [String] = []) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors, warnings: warnings)
    }
}

// MARK: - DTO Mappers

/// Protocol for mapping between domain models and infrastructure data
protocol DTOMapper {
    associatedtype DomainModel
    associatedtype InfrastructureModel
    
    func toDomain(_ infrastructure: InfrastructureModel) -> DomainModel?
    func toInfrastructure(_ domain: DomainModel) -> InfrastructureModel?
}

// MARK: - Firestore to DTO Mappers

struct FirestoreInsightMapper: DTOMapper {
    typealias DomainModel = InsightDTO
    typealias InfrastructureModel = DocumentSnapshot
    
    func toDomain(_ document: DocumentSnapshot) -> InsightDTO? {
        guard let data = document.data() else { return nil }
        
        guard let insightTypeString = data[FirestoreKeys.insightType] as? String,
              let featureType = SpeechFeatureType(rawValue: insightTypeString),
              let value = data[FirestoreKeys.f0Mean] as? Double,
              let confidence = data[FirestoreKeys.confidence] as? Double,
              let statusString = data[FirestoreKeys.status] as? String,
              let status = InsightDTO.InsightStatus(rawValue: statusString),
              let createdAtTimestamp = data[FirestoreKeys.createdAt] as? Timestamp else {
            return nil
        }
        
        let metadata = extractMetadata(from: data)
        let errorType = data[FirestoreKeys.errorType] as? String
        
        return InsightDTO(
            id: document.documentID,
            featureType: featureType,
            value: value,
            confidence: confidence,
            metadata: metadata,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            errorType: errorType
        )
    }
    
    func toInfrastructure(_ domain: InsightDTO) -> DocumentSnapshot? {
        // This would be used for creating new documents
        // Implementation depends on specific use case
        return nil
    }
    
    private func extractMetadata(from data: [String: Any]) -> SpeechFeatureMetadata? {
        if let metadataData = data[FirestoreKeys.metadata] as? [String: Any] {
            return F0ProcessingMetadata(from: metadataData)
        }
        return nil
    }
}

struct FirestoreRecordingMapper: DTOMapper {
    typealias DomainModel = RecordingDTO
    typealias InfrastructureModel = DocumentSnapshot
    
    func toDomain(_ document: DocumentSnapshot) -> RecordingDTO? {
        guard let data = document.data() else { return nil }
        
        guard let userID = data["userID"] as? String,
              let task = data[FirestoreKeys.task] as? String,
              let sessionTimeTimestamp = data[FirestoreKeys.sessionTime] as? Timestamp else {
            return nil
        }
        
        // Note: Insights would be loaded separately via subcollection
        return RecordingDTO(
            id: document.documentID,
            userID: userID,
            task: task,
            sessionTime: sessionTimeTimestamp.dateValue(),
            insights: [] // Would be populated separately
        )
    }
    
    func toInfrastructure(_ domain: RecordingDTO) -> DocumentSnapshot? {
        return nil
    }
}

// MARK: - Feature Result Validator

struct FeatureResultValidator {
    func validate(_ result: FeatureResultDTO) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate value range
        let validRange = result.featureType.validRange
        if !validRange.contains(result.value) {
            errors.append("Value \(result.value) outside valid range (\(validRange.lowerBound)-\(validRange.upperBound) \(result.featureType.unit))")
        }
        
        // Validate confidence
        let minConfidence = result.featureType.minimumConfidence
        if result.confidence < minConfidence {
            warnings.append("Low confidence: \(result.confidence) (minimum: \(minConfidence))")
        }
        
        // Validate metadata if present
        if let metadata = result.metadata {
            if let f0Metadata = metadata as? F0ProcessingMetadata {
                if f0Metadata.voicedFrames < 100 {
                    warnings.append("Low voiced frame count: \(f0Metadata.voicedFrames)")
                }
                if f0Metadata.audioDuration < 1.0 {
                    warnings.append("Short audio duration: \(f0Metadata.audioDuration)s")
                }
            }
        }
        
        return errors.isEmpty ? 
            ValidationResult(isValid: true, errors: [], warnings: warnings) :
            ValidationResult(isValid: false, errors: errors, warnings: warnings)
    }
}

// MARK: - DTO Extensions

extension InsightDTO {
    var isCompleted: Bool {
        return status == .completed || status == .completedWithWarnings
    }
    
    var hasWarnings: Bool {
        return status == .completedWithWarnings
    }
    
    var isFailed: Bool {
        return status == .failed
    }
    
    var isProcessing: Bool {
        return status == .processing
    }
}

extension RecordingDTO {
    var isVocalTest: Bool {
        return task == "onboarding_vocal_test"
    }
    
    var hasInsights: Bool {
        return !insights.isEmpty
    }
    
    func insights(for featureType: SpeechFeatureType) -> [InsightDTO] {
        return insights.filter { $0.featureType == featureType }
    }
    
    func latestInsight(for featureType: SpeechFeatureType) -> InsightDTO? {
        return insights(for: featureType)
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
} 