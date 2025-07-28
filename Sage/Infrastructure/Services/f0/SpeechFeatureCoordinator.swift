import Foundation
import Combine

// MARK: - Speech Feature Coordinator

/// Coordinates multiple speech feature services
/// - Manages lifecycle of multiple feature services
/// - Provides unified interface for feature analysis
/// - Supports batch operations and cross-feature analysis
@MainActor
final class SpeechFeatureCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var activeFeatures: Set<SpeechFeatureType> = []
    @Published private(set) var featureStates: [SpeechFeatureType: FeatureState] = [:]
    @Published private(set) var isAnalyzing = false
    
    // MARK: - Private Properties
    
    private var featureServices: [SpeechFeatureType: any SpeechFeatureService] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let firestoreClient: FirestoreClient
    
    // MARK: - Initialization
    
    init(firestoreClient: FirestoreClient? = nil) {
        if let client = firestoreClient {
            self.firestoreClient = client
        } else {
            // Initialize asynchronously to avoid actor isolation issues
            self.firestoreClient = FirebaseFirestoreClient()
        }
    }
    
    // MARK: - Public Methods
    
    /// Registers a feature service for a specific feature type
    func registerFeatureService(_ service: any SpeechFeatureService, for featureType: SpeechFeatureType) {
        featureServices[featureType] = service
        activeFeatures.insert(featureType)
        
        // Subscribe to state changes
        if let observableService = service as? any ObservableObject {
            // Use Combine to observe state changes
            // Note: This is a simplified approach - in production, you'd want proper type erasure
            // For now, we'll update state manually when needed
        }
    }
    
    /// Analyzes a single feature
    func analyzeFeature(_ featureType: SpeechFeatureType, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let service = featureServices[featureType] else {
            completion?(.failure(SpeechFeatureError.invalidDataFormat))
            return
        }
        
        service.fetchFeatureData(completion: completion)
    }
    
    /// Analyzes multiple features in parallel
    func analyzeFeatures(_ featureTypes: [SpeechFeatureType], completion: ((Result<Void, Error>) -> Void)? = nil) {
        let group = DispatchGroup()
        var errors: [Error] = []
        
        for featureType in featureTypes {
            group.enter()
            analyzeFeature(featureType) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if errors.isEmpty {
                completion?(.success(()))
            } else {
                completion?(.failure(errors.first!))
            }
        }
    }
    
    /// Analyzes all active features
    func analyzeAllFeatures(completion: ((Result<Void, Error>) -> Void)? = nil) {
        analyzeFeatures(Array(activeFeatures), completion: completion)
    }
    
    /// Stops analysis for a specific feature
    func stopAnalysis(for featureType: SpeechFeatureType) {
        featureServices[featureType]?.stopListening()
    }
    
    /// Stops analysis for all features
    func stopAllAnalysis() {
        for service in featureServices.values {
            service.stopListening()
        }
    }
    
    /// Gets the current state for a specific feature
    func getFeatureState(for featureType: SpeechFeatureType) -> FeatureState? {
        return featureStates[featureType]
    }
    
    /// Gets the display value for a specific feature
    func getFeatureDisplayValue(for featureType: SpeechFeatureType) -> String {
        return featureServices[featureType]?.displayValue ?? "Not Available"
    }
    
    /// Gets the confidence for a specific feature
    func getFeatureConfidence(for featureType: SpeechFeatureType) -> Double {
        return featureServices[featureType]?.confidence ?? 0.0
    }
    
    /// Checks if a feature is currently loading
    func isFeatureLoading(_ featureType: SpeechFeatureType) -> Bool {
        return featureServices[featureType]?.isLoading ?? false
    }
    
    /// Gets error message for a specific feature
    func getFeatureErrorMessage(for featureType: SpeechFeatureType) -> String? {
        return featureServices[featureType]?.errorMessage
    }
    
    // MARK: - Private Methods
    
    private func updateAnalysisState() {
        let loadingFeatures = activeFeatures.filter { isFeatureLoading($0) }
        isAnalyzing = !loadingFeatures.isEmpty
    }
}

// MARK: - Convenience Extensions

extension SpeechFeatureCoordinator {
    /// Creates and registers an F0 feature service
    func registerF0Service() {
        let f0Service = F0DataService()
        registerFeatureService(f0Service, for: .f0)
    }
    
    /// Creates and registers a jitter feature service (future implementation)
    func registerJitterService() {
        // TODO: Implement JitterDataService when ready
        // let jitterService = JitterDataService()
        // registerFeatureService(jitterService, for: .jitter)
    }
    
    /// Creates and registers a shimmer feature service (future implementation)
    func registerShimmerService() {
        // TODO: Implement ShimmerDataService when ready
        // let shimmerService = ShimmerDataService()
        // registerFeatureService(shimmerService, for: .shimmer)
    }
} 