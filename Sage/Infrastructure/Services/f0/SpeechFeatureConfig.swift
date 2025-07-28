import Foundation

// MARK: - Speech Feature Configuration System

/// Centralized configuration for speech feature processing
/// - Externalizes hardcoded thresholds and constants
/// - Supports environment-specific configurations
/// - Enables easy testing and customization
struct SpeechFeatureConfig {
    
    // MARK: - Processing Thresholds
    
    struct ProcessingThresholds {
        /// Debounce threshold for duplicate value detection
        let debounceThreshold: Double
        /// Default processing timeout in seconds
        let defaultTimeout: TimeInterval
        /// Minimum confidence threshold for valid results
        let minimumConfidence: Double
        /// Maximum retry attempts for failed operations
        let maxRetryAttempts: Int
        /// Retry delay between attempts in seconds
        let retryDelay: TimeInterval
        
        static let production = ProcessingThresholds(
            debounceThreshold: 0.1,
            defaultTimeout: 60.0,
            minimumConfidence: 0.5,
            maxRetryAttempts: 3,
            retryDelay: 2.0
        )
        
        static let testing = ProcessingThresholds(
            debounceThreshold: 0.01,
            defaultTimeout: 5.0,
            minimumConfidence: 0.0,
            maxRetryAttempts: 1,
            retryDelay: 0.1
        )
    }
    
    // MARK: - Feature-Specific Configurations
    
    struct FeatureConfig {
        let featureType: SpeechFeatureType
        let validRange: ClosedRange<Double>
        let unit: String
        let displayName: String
        let processingTimeout: TimeInterval
        let debounceThreshold: Double
        let minimumConfidence: Double
        
        init(
            featureType: SpeechFeatureType,
            validRange: ClosedRange<Double>,
            unit: String,
            displayName: String,
            processingTimeout: TimeInterval? = nil,
            debounceThreshold: Double? = nil,
            minimumConfidence: Double? = nil
        ) {
            self.featureType = featureType
            self.validRange = validRange
            self.unit = unit
            self.displayName = displayName
            self.processingTimeout = processingTimeout ?? ProcessingThresholds.production.defaultTimeout
            self.debounceThreshold = debounceThreshold ?? ProcessingThresholds.production.debounceThreshold
            self.minimumConfidence = minimumConfidence ?? ProcessingThresholds.production.minimumConfidence
        }
    }
    
    // MARK: - Feature Configurations
    
    static let featureConfigs: [SpeechFeatureType: FeatureConfig] = [
        .f0: FeatureConfig(
            featureType: .f0,
            validRange: 75...500,
            unit: "Hz",
            displayName: "Fundamental Frequency",
            processingTimeout: 60.0,
            debounceThreshold: 0.1,
            minimumConfidence: 0.6
        ),
        
        .jitter: FeatureConfig(
            featureType: .jitter,
            validRange: 0...10,
            unit: "%",
            displayName: "Jitter",
            processingTimeout: 45.0,
            debounceThreshold: 0.05,
            minimumConfidence: 0.5
        ),
        
        .shimmer: FeatureConfig(
            featureType: .shimmer,
            validRange: 0...10,
            unit: "%",
            displayName: "Shimmer",
            processingTimeout: 45.0,
            debounceThreshold: 0.05,
            minimumConfidence: 0.5
        ),
        
        .energy: FeatureConfig(
            featureType: .energy,
            validRange: -60...0,
            unit: "dB",
            displayName: "Energy",
            processingTimeout: 30.0,
            debounceThreshold: 0.5,
            minimumConfidence: 0.4
        )
    ]
    
    // MARK: - Environment Configuration
    
    enum Environment {
        case production
        case testing
        case development
    }
    
    let environment: Environment
    let processingThresholds: ProcessingThresholds
    
    init(environment: Environment = .production) {
        self.environment = environment
        self.processingThresholds = environment == .testing ? 
            ProcessingThresholds.testing : 
            ProcessingThresholds.production
    }
    
    // MARK: - Configuration Access
    
    func config(for featureType: SpeechFeatureType) -> FeatureConfig? {
        return Self.featureConfigs[featureType]
    }
    
    func validRange(for featureType: SpeechFeatureType) -> ClosedRange<Double>? {
        return config(for: featureType)?.validRange
    }
    
    func unit(for featureType: SpeechFeatureType) -> String? {
        return config(for: featureType)?.unit
    }
    
    func displayName(for featureType: SpeechFeatureType) -> String? {
        return config(for: featureType)?.displayName
    }
    
    func processingTimeout(for featureType: SpeechFeatureType) -> TimeInterval {
        return config(for: featureType)?.processingTimeout ?? processingThresholds.defaultTimeout
    }
    
    func debounceThreshold(for featureType: SpeechFeatureType) -> Double {
        return config(for: featureType)?.debounceThreshold ?? processingThresholds.debounceThreshold
    }
    
    func minimumConfidence(for featureType: SpeechFeatureType) -> Double {
        return config(for: featureType)?.minimumConfidence ?? processingThresholds.minimumConfidence
    }
}

// MARK: - Global Configuration Instance

/// Global configuration instance for easy access
/// - Can be customized per environment
/// - Supports dependency injection for testing
var globalSpeechFeatureConfig = SpeechFeatureConfig()

// MARK: - Configuration Extensions

extension SpeechFeatureType {
    var config: SpeechFeatureConfig.FeatureConfig? {
        return globalSpeechFeatureConfig.config(for: self)
    }
    
    var validRange: ClosedRange<Double> {
        return config?.validRange ?? 0...1000
    }
    
    var unit: String {
        return config?.unit ?? "units"
    }
    
    var displayName: String {
        return config?.displayName ?? "Unknown Feature"
    }
    
    var processingTimeout: TimeInterval {
        return globalSpeechFeatureConfig.processingTimeout(for: self)
    }
    
    var debounceThreshold: Double {
        return globalSpeechFeatureConfig.debounceThreshold(for: self)
    }
    
    var minimumConfidence: Double {
        return globalSpeechFeatureConfig.minimumConfidence(for: self)
    }
} 