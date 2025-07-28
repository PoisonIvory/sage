import Foundation

// MARK: - F0 Feature Implementation

/// F0 (Fundamental Frequency) feature implementation
/// - Demonstrates how to implement the SpeechFeature protocol
/// - Provides F0-specific metadata and validation
struct F0Feature: SpeechFeature {
    static let featureType: SpeechFeatureType = .f0
    static let valueKey: String = FirestoreKeys.f0Mean
    static let confidenceKey: String = FirestoreKeys.confidence
    static let metadataKey: String = FirestoreKeys.metadata
    
    let value: Double
    let confidence: Double
    let metadata: SpeechFeatureMetadata?
    
    init?(value: Double, confidence: Double, metadata: SpeechFeatureMetadata?) {
        guard F0Feature.featureType.validRange.contains(value) else {
            return nil
        }
        
        self.value = value
        self.confidence = confidence
        self.metadata = metadata
    }
}

// MARK: - F0 Processing Metadata

/// F0-specific processing metadata
/// - Implements SpeechFeatureMetadata protocol
/// - Contains F0-specific fields like voiced frames, audio duration
struct F0ProcessingMetadata: SpeechFeatureMetadata {
    let audioDuration: Double
    let voicedFrames: Int
    let totalFrames: Int
    
    init?(from dictionary: [String: Any]) {
        self.audioDuration = dictionary[FirestoreKeys.audioDuration] as? Double ?? 0
        self.voicedFrames = dictionary[FirestoreKeys.voicedFrames] as? Int ?? 0
        self.totalFrames = dictionary[FirestoreKeys.totalFrames] as? Int ?? 0
    }
    
    // Backward compatibility with existing code
    init(dictionary: [String: Any]) {
        self.audioDuration = dictionary[FirestoreKeys.audioDuration] as? Double ?? 0
        self.voicedFrames = dictionary[FirestoreKeys.voicedFrames] as? Int ?? 0
        self.totalFrames = dictionary[FirestoreKeys.totalFrames] as? Int ?? 0
    }
} 