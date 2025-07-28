import Foundation
import Combine

// MARK: - Generic Feature State

enum FeatureState {
    case idle
    case loading
    case success(value: String, confidence: Double, metadata: SpeechFeatureMetadata?)
    case error(String)
}

// MARK: - Speech Feature Metadata Protocol

protocol SpeechFeatureMetadata {
    init?(from dictionary: [String: Any])
}

// MARK: - Speech Feature Type Enum

enum SpeechFeatureType: String, CaseIterable {
    case f0 = "f0_analysis"
    case jitter = "jitter_analysis"
    case shimmer = "shimmer_analysis"
    case energy = "energy_analysis"
}

// MARK: - Speech Feature Service Protocol

/// Generic protocol for speech feature services
/// - Allows easy addition of new features (jitter, shimmer, etc.)
/// - Maintains consistent interface across all feature types
/// - Supports ObservableObject for SwiftUI integration
@preconcurrency
protocol SpeechFeatureService: ObservableObject {
    var state: FeatureState { get }
    var featureType: SpeechFeatureType { get }
    
    /// Fetches feature data for the current user
    func fetchFeatureData(completion: ((Result<Void, Error>) -> Void)?)
    
    /// Stops any ongoing operations and cleans up resources
    func stopListening()
    
    /// Convenience property for display value
    var displayValue: String { get }
    
    /// Convenience property for confidence
    var confidence: Double { get }
    
    /// Convenience property for loading state
    var isLoading: Bool { get }
    
    /// Convenience property for error message
    var errorMessage: String? { get }
}

// MARK: - Default Implementation

extension SpeechFeatureService {
    var displayValue: String {
        switch state {
        case .idle:
            return "Still Processing..."
        case .loading:
            return "Loading..."
        case .success(let value, _, _):
            return value
        case .error:
            return "Processing Error"
        }
    }
    
    var confidence: Double {
        switch state {
        case .success(_, let confidence, _):
            return confidence
        default:
            return 0.0
        }
    }
    
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
} 