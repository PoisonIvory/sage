import Foundation
import FirebaseFirestore

// MARK: - Generic Feature Processor Protocol

@preconcurrency
protocol FeatureProcessor {
    associatedtype Feature: SpeechFeature
    func processParsedData(_ document: DocumentSnapshot, completion: ((Result<Void, Error>) -> Void)?)
    func processParsedData(documentID: String, data: [String: Any], completion: ((Result<Void, Error>) -> Void)?)
    func reset()
}

// MARK: - Speech Feature Protocol

protocol SpeechFeature {
    static var featureType: SpeechFeatureType { get }
    static var valueKey: String { get }
    static var confidenceKey: String { get }
    static var metadataKey: String { get }
    
    var value: Double { get }
    var confidence: Double { get }
    var metadata: SpeechFeatureMetadata? { get }
    
    init?(value: Double, confidence: Double, metadata: SpeechFeatureMetadata?)
}

// MARK: - Generic Insight Processor

/// Generic processor for any speech feature type
/// - Parameterized over the feature type for type safety
/// - Handles validation, parsing, and state transitions
/// - Supports debouncing and error handling
@MainActor
final class InsightProcessor<Feature: SpeechFeature>: FeatureProcessor {
    private var lastProcessedValue: Double?
    private var stateHandler: FeatureStateHandler?
    
    init(stateHandler: FeatureStateHandler? = nil) {
        self.stateHandler = stateHandler
    }
    
    func setStateHandler(_ handler: FeatureStateHandler) {
        self.stateHandler = handler
    }
    
    // MARK: - FeatureProcessor Implementation
    
    nonisolated func processParsedData(_ document: DocumentSnapshot, completion: ((Result<Void, Error>) -> Void)?) {
        guard let data = document.data() else {
            Task { @MainActor in
                stateHandler?.handleError("Invalid document data")
            }
            completion?(.failure(SpeechFeatureError.invalidDocumentData))
            return
        }
        
        processParsedData(documentID: document.documentID, data: data, completion: completion)
    }
    
    nonisolated func processParsedData(documentID: String, data: [String: Any], completion: ((Result<Void, Error>) -> Void)?) {
        let insightId = documentID
        Logger.info("InsightProcessor: Processing \(Feature.featureType.displayName) insight document: \(insightId)")
        
        Task { @MainActor in
            guard await validateAndParseData(data, insightId: insightId) else { 
                completion?(.failure(SpeechFeatureError.invalidDataFormat))
                return 
            }
            
            await processMetadata(data, insightId: insightId)
            await completeProcessing(insightId: insightId)
            completion?(.success(()))
        }
    }
    
    nonisolated func reset() {
        Task { @MainActor in
            lastProcessedValue = nil
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func validateAndParseData(_ data: [String: Any], insightId: String) -> Bool {
        guard let featureValue = data[Feature.valueKey] as? Double else {
            stateHandler?.handleError("Invalid \(Feature.featureType.displayName) data format")
            return false
        }
        
        guard Feature.featureType.validRange.contains(featureValue) else {
            stateHandler?.handleError("\(Feature.featureType.displayName) value outside valid range (\(Feature.featureType.validRange.lowerBound)-\(Feature.featureType.validRange.upperBound) \(Feature.featureType.unit))")
            return false
        }
        
        // Debounce: Only process if value has changed
        if let lastValue = lastProcessedValue, abs(lastValue - featureValue) < 0.1 {
            Logger.info("InsightProcessor: Ignoring duplicate \(Feature.featureType.displayName) value update")
            return true
        }
        
        let confidence = data[Feature.confidenceKey] as? Double ?? 0.0
        let metadata = extractProcessingMetadata(from: data)
        
        handleSuccess(value: featureValue, confidence: confidence, metadata: metadata, insightId: insightId)
        lastProcessedValue = featureValue
        
        return true
    }
    
    private func extractProcessingMetadata(from data: [String: Any]) -> SpeechFeatureMetadata? {
        if let metadataData = data[Feature.metadataKey] as? [String: Any] {
            // Try to create metadata from the feature's metadata type
            // This is a simplified approach - in production, you'd want proper type mapping
            return F0ProcessingMetadata(from: metadataData)
        }
        return nil
    }
    
    private func processMetadata(_ data: [String: Any], insightId: String) {
        if let status = data[FirestoreKeys.status] as? String, status == "completed_with_warnings" {
            Logger.info("InsightProcessor: \(Feature.featureType.displayName) analysis completed with warnings for insight: \(insightId)")
        }
        
        if let errorType = data[FirestoreKeys.errorType] as? String {
            Logger.info("InsightProcessor: \(Feature.featureType.displayName) analysis error type: \(errorType) for insight: \(insightId)")
        }
        
        if let metadataData = data[Feature.metadataKey] as? [String: Any] {
            logProcessingMetadata(metadataData)
        }
    }
    
    private func logProcessingMetadata(_ metadata: [String: Any]) {
        if let f0Metadata = F0ProcessingMetadata(from: metadata) {
            Logger.info("InsightProcessor: \(Feature.featureType.displayName) processed: \(f0Metadata.audioDuration)s audio, \(f0Metadata.voicedFrames)/\(f0Metadata.totalFrames) voiced frames")
        }
    }
    
    private func handleSuccess(value: Double, confidence: Double, metadata: SpeechFeatureMetadata?, insightId: String) {
        let valueString = String(format: "%.1f \(Feature.featureType.unit)", value)
        stateHandler?.handleSuccess(value: valueString, confidence: confidence, metadata: metadata)
        Logger.info("InsightProcessor: \(Feature.featureType.displayName) value updated to \(valueString) with \(confidence)% confidence for insight: \(insightId)")
    }
    
    private func completeProcessing(insightId: String) {
        // State is already set in handleSuccess
        // Additional completion logic can be added here if needed
    }
}

// MARK: - Feature State Handler Protocol

protocol FeatureStateHandler {
    func handleSuccess(value: String, confidence: Double, metadata: SpeechFeatureMetadata?)
    func handleError(_ message: String)
}

// MARK: - Speech Feature Error Types

enum SpeechFeatureError: Error, LocalizedError {
    case invalidDocumentData
    case invalidDataFormat
    case valueOutOfRange
    case processingTimeout
    case noInsightYet
    
    var errorDescription: String? {
        switch self {
        case .invalidDocumentData:
            return "Invalid document data"
        case .invalidDataFormat:
            return "Invalid data format"
        case .valueOutOfRange:
            return "Value outside valid range"
        case .processingTimeout:
            return "Processing delayed, please check back later"
        case .noInsightYet:
            return "No insight found yet - processing may still be in progress"
        }
    }
} 