import Foundation

// MARK: - Rich Domain Error System

/// Rich domain error type for speech feature processing
/// - Replaces string-based errors with structured error types
/// - Provides context-aware error messages
/// - Supports error categorization and recovery strategies
enum DomainError: Error, LocalizedError {
    // MARK: - Authentication Errors
    case userNotAuthenticated
    
    // MARK: - Data Validation Errors
    case invalidDocumentData
    case invalidDataFormat
    case valueOutOfRange(feature: SpeechFeatureType, value: Double, validRange: ClosedRange<Double>)
    case missingRequiredField(field: String, feature: SpeechFeatureType)
    
    // MARK: - Processing Errors
    case processingTimeout(feature: SpeechFeatureType, timeout: TimeInterval)
    case noInsightYet(feature: SpeechFeatureType)
    case duplicateValue(feature: SpeechFeatureType, value: Double)
    
    // MARK: - Network/Infrastructure Errors
    case networkError(underlying: Error)
    case firestoreError(underlying: Error)
    case recordingNotFound(feature: SpeechFeatureType)
    
    // MARK: - Feature-Specific Errors
    case f0ProcessingError(reason: String)
    case jitterProcessingError(reason: String)
    case shimmerProcessingError(reason: String)
    case energyProcessingError(reason: String)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
            
        case .invalidDocumentData:
            return "Invalid document data"
            
        case .invalidDataFormat:
            return "Invalid data format"
            
        case .valueOutOfRange(let feature, let value, let validRange):
            return "\(feature.displayName) value \(value) outside valid range (\(validRange.lowerBound)-\(validRange.upperBound) \(feature.unit))"
            
        case .missingRequiredField(let field, let feature):
            return "Missing required field '\(field)' for \(feature.displayName)"
            
        case .processingTimeout(let feature, let timeout):
            return "\(feature.displayName) processing timeout after \(Int(timeout)) seconds"
            
        case .noInsightYet(let feature):
            return "No \(feature.displayName) insight found yet - processing may still be in progress"
            
        case .duplicateValue(let feature, let value):
            return "Ignoring duplicate \(feature.displayName) value: \(value)"
            
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
            
        case .firestoreError(let underlying):
            return "Firestore error: \(underlying.localizedDescription)"
            
        case .recordingNotFound(let feature):
            return "No recording found for \(feature.displayName) analysis"
            
        case .f0ProcessingError(let reason):
            return "F0 processing error: \(reason)"
            
        case .jitterProcessingError(let reason):
            return "Jitter processing error: \(reason)"
            
        case .shimmerProcessingError(let reason):
            return "Shimmer processing error: \(reason)"
            
        case .energyProcessingError(let reason):
            return "Energy processing error: \(reason)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .userNotAuthenticated:
            return "User authentication required"
            
        case .invalidDocumentData, .invalidDataFormat:
            return "Data validation failed"
            
        case .valueOutOfRange:
            return "Value validation failed"
            
        case .missingRequiredField:
            return "Required data missing"
            
        case .processingTimeout:
            return "Processing exceeded time limit"
            
        case .noInsightYet:
            return "Analysis not yet complete"
            
        case .duplicateValue:
            return "Duplicate value detected"
            
        case .networkError, .firestoreError:
            return "Infrastructure error"
            
        case .recordingNotFound:
            return "No recording available"
            
        case .f0ProcessingError, .jitterProcessingError, .shimmerProcessingError, .energyProcessingError:
            return "Feature-specific processing error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userNotAuthenticated:
            return "Please sign in to continue"
            
        case .invalidDocumentData, .invalidDataFormat:
            return "Please try again or contact support if the problem persists"
            
        case .valueOutOfRange:
            return "Please ensure your recording meets the quality requirements"
            
        case .missingRequiredField:
            return "Please try recording again with clear speech"
            
        case .processingTimeout:
            return "Please check back in a few minutes"
            
        case .noInsightYet:
            return "Please wait for processing to complete"
            
        case .duplicateValue:
            return "This is normal - duplicate values are automatically filtered"
            
        case .networkError:
            return "Please check your internet connection and try again"
            
        case .firestoreError:
            return "Please try again or contact support if the problem persists"
            
        case .recordingNotFound:
            return "Please complete a voice recording first"
            
        case .f0ProcessingError, .jitterProcessingError, .shimmerProcessingError, .energyProcessingError:
            return "Please try recording again with clear speech"
        }
    }
    
    // MARK: - Error Categorization
    
    var category: ErrorCategory {
        switch self {
        case .userNotAuthenticated:
            return .authentication
            
        case .invalidDocumentData, .invalidDataFormat, .valueOutOfRange, .missingRequiredField:
            return .validation
            
        case .processingTimeout, .noInsightYet, .duplicateValue:
            return .processing
            
        case .networkError, .firestoreError, .recordingNotFound:
            return .infrastructure
            
        case .f0ProcessingError, .jitterProcessingError, .shimmerProcessingError, .energyProcessingError:
            return .featureSpecific
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .userNotAuthenticated, .networkError, .firestoreError:
            return true
            
        case .processingTimeout, .noInsightYet:
            return true
            
        case .duplicateValue:
            return true
            
        case .invalidDocumentData, .invalidDataFormat, .valueOutOfRange, .missingRequiredField, .recordingNotFound:
            return false
            
        case .f0ProcessingError, .jitterProcessingError, .shimmerProcessingError, .energyProcessingError:
            return false
        }
    }
}

// MARK: - Error Categories

enum ErrorCategory {
    case authentication
    case validation
    case processing
    case infrastructure
    case featureSpecific
}

// MARK: - Error Context

struct ErrorContext {
    let feature: SpeechFeatureType
    let timestamp: Date
    let userID: String?
    let recordingID: String?
    let insightID: String?
    
    init(
        feature: SpeechFeatureType,
        timestamp: Date = Date(),
        userID: String? = nil,
        recordingID: String? = nil,
        insightID: String? = nil
    ) {
        self.feature = feature
        self.timestamp = timestamp
        self.userID = userID
        self.recordingID = recordingID
        self.insightID = insightID
    }
}

// MARK: - Error with Context

struct DomainErrorWithContext {
    let error: DomainError
    let context: ErrorContext
    
    init(_ error: DomainError, context: ErrorContext) {
        self.error = error
        self.context = context
    }
} 