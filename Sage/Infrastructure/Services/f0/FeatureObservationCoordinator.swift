import Foundation
import Combine
import FirebaseFirestore

// MARK: - Feature Observation Coordinator

/// Declarative coordinator for managing feature observation lifecycles
/// - Centralizes listener management for multiple parallel features
/// - Provides declarative state management
/// - Supports batch operations and error handling
@MainActor
final class FeatureObservationCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var observationStates: [SpeechFeatureType: ObservationState] = [:]
    @Published private(set) var isObserving = false
    @Published private(set) var activeFeatures: Set<SpeechFeatureType> = []
    
    // MARK: - Private Properties
    
    private var listeners: [SpeechFeatureType: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let firestoreClient: FirestoreClient
    private let config: SpeechFeatureConfig
    
    // MARK: - Observation State
    
    enum ObservationState {
        case idle
        case connecting
        case observing
        case paused
        case error(DomainError)
        
        var isActive: Bool {
            switch self {
            case .connecting, .observing:
                return true
            case .idle, .paused, .error:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        firestoreClient: FirestoreClient? = nil,
        config: SpeechFeatureConfig = globalSpeechFeatureConfig
    ) async {
        if let client = firestoreClient {
            self.firestoreClient = client
        } else {
            self.firestoreClient = FirebaseFirestoreClient()
        }
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// Starts observing a single feature
    func startObserving(
        _ featureType: SpeechFeatureType,
        recordingID: String,
        completion: ((Result<Void, any Error>) -> Void)? = nil
    ) {
        guard !activeFeatures.contains(featureType) else {
            completion?(.failure(NSError(domain: "DuplicateFeature", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature \(featureType) already being observed"])))
            return
        }
        
        observationStates[featureType] = .connecting
        activeFeatures.insert(featureType)
        
        Task {
            do {
                try await setupListener(for: featureType, recordingID: recordingID)
                observationStates[featureType] = .observing
                updateObservingState()
                completion?(.success(()))
            } catch {
                let domainError = mapError(error, for: featureType)
                observationStates[featureType] = .error(domainError)
                activeFeatures.remove(featureType)
                updateObservingState()
                completion?(.failure(domainError))
            }
        }
    }
    
    /// Starts observing multiple features in parallel
    func startObservingMultiple(
        _ featureTypes: [SpeechFeatureType],
        recordingID: String,
        completion: ((Result<Void, any Error>) -> Void)? = nil
    ) {
        let group = DispatchGroup()
        var errors: [DomainError] = []
        
        for featureType in featureTypes {
            group.enter()
            startObserving(featureType, recordingID: recordingID) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if let domainError = error as? DomainError {
                        errors.append(domainError)
                    } else {
                        // Convert generic error to domain error
                        errors.append(VoiceAnalysisError.unknown)
                    }
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
    
    /// Stops observing a specific feature
    func stopObserving(_ featureType: SpeechFeatureType) {
        listeners[featureType]?.remove()
        listeners.removeValue(forKey: featureType)
        observationStates[featureType] = .idle
        activeFeatures.remove(featureType)
        updateObservingState()
    }
    
    /// Stops observing all features
    func stopObservingAll() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
        observationStates.removeAll()
        activeFeatures.removeAll()
        updateObservingState()
    }
    
    /// Pauses observation for a feature
    func pauseObserving(_ featureType: SpeechFeatureType) {
        guard activeFeatures.contains(featureType) else { return }
        observationStates[featureType] = .paused
        updateObservingState()
    }
    
    /// Resumes observation for a feature
    func resumeObserving(_ featureType: SpeechFeatureType) {
        guard activeFeatures.contains(featureType) else { return }
        observationStates[featureType] = .observing
        updateObservingState()
    }
    
    /// Gets the current observation state for a feature
    func observationState(for featureType: SpeechFeatureType) -> ObservationState {
        return observationStates[featureType] ?? .idle
    }
    
    /// Checks if a feature is currently being observed
    func isObserving(_ featureType: SpeechFeatureType) -> Bool {
        return activeFeatures.contains(featureType) && 
               observationStates[featureType]?.isActive == true
    }
    
    /// Gets all currently active features
    func getActiveFeatures() -> Set<SpeechFeatureType> {
        return activeFeatures
    }
    
    // MARK: - Private Methods
    
    private func setupListener(
        for featureType: SpeechFeatureType,
        recordingID: String
    ) async throws {
        // This would be implemented based on your specific Firestore structure
        // For now, we'll create a placeholder implementation
        
        let listener = try await createListener(for: featureType, recordingID: recordingID)
        listeners[featureType] = listener
    }
    
    private func createListener(
        for featureType: SpeechFeatureType,
        recordingID: String
    ) async throws -> ListenerRegistration {
        // Placeholder implementation - would be replaced with actual Firestore listener setup
        return MockListenerRegistration()
    }
    
    private func updateObservingState() {
        isObserving = !activeFeatures.isEmpty && 
                     activeFeatures.allSatisfy { observationStates[$0]?.isActive == true }
    }
    
    private func mapError(_ error: Error, for featureType: SpeechFeatureType) -> DomainError {
        // Map infrastructure errors to domain errors
        switch error {
        case let domainError as DomainError:
            return domainError
        default:
            return VoiceAnalysisError.networkUnavailable
        }
    }
}

// MARK: - Mock Listener Registration

private class MockListenerRegistration: NSObject, ListenerRegistration {
    func remove() {
        // Mock implementation
    }
}

// MARK: - Feature Observation Coordinator Extensions

extension FeatureObservationCoordinator {
    /// Convenience method to observe F0 feature
    func observeF0(recordingID: String, completion: ((Result<Void, any Error>) -> Void)? = nil) {
        startObserving(.f0, recordingID: recordingID, completion: completion)
    }
    
    /// Convenience method to observe all available features
    func observeAllFeatures(recordingID: String, completion: ((Result<Void, any Error>) -> Void)? = nil) {
        let allFeatures = SpeechFeatureType.allCases
        startObservingMultiple(allFeatures, recordingID: recordingID, completion: completion)
    }
    
    /// Convenience method to observe multiple specific features
    func observeFeatures(
        _ features: [SpeechFeatureType],
        recordingID: String,
        completion: ((Result<Void, any Error>) -> Void)? = nil
    ) {
        startObservingMultiple(features, recordingID: recordingID, completion: completion)
    }
}

// MARK: - Observation State Extensions

extension FeatureObservationCoordinator.ObservationState {
    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting..."
        case .observing:
            return "Observing"
        case .paused:
            return "Paused"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    var error: DomainError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
} 