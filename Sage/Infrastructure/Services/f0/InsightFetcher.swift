import Foundation
import FirebaseFirestore

// MARK: - Generic Insight Fetcher

/// Generic fetcher for any speech feature type
/// - Parameterized over the feature type for type safety
/// - Handles snapshot listener setup and parsing
/// - Supports real-time updates when insights are written
@MainActor
final class InsightFetcher<Feature: SpeechFeature> {
    private var insightsListener: ListenerRegistration?
    private let processor: any FeatureProcessor
    
    init(processor: any FeatureProcessor) {
        self.processor = processor
    }
    
    /// Sets up a snapshot listener for insights in a recording
    /// - Listens for real-time updates when analysis is completed
    /// - Calls the processor when new insights are found
    func setupInsightsListener(
        for recordingRef: DocumentReference,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        // Remove any existing listener
        insightsListener?.remove()
        
        let insightsRef = recordingRef.collection("insights")
        
        Logger.info("InsightFetcher: Setting up snapshot listener for \(Feature.featureType.displayName) insights in recording: \(recordingRef.documentID)")
        
        insightsListener = insightsRef
            .whereField(FirestoreKeys.insightType, isEqualTo: Feature.featureType.rawValue)
            .order(by: FirestoreKeys.createdAt, descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                Task { @MainActor in
                    if let error = error {
                        Logger.error("InsightFetcher: Snapshot listener error for \(Feature.featureType.displayName): \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        Logger.info("InsightFetcher: No \(Feature.featureType.displayName) insights found yet for recording: \(recordingRef.documentID)")
                        // Don't show error immediately - insights might still be processing
                        if snapshot?.documents.isEmpty == true {
                            // Complete with success since listener is attached and insight may arrive later
                            completion?(.success(()))
                        } else {
                            // No documents in snapshot - complete with noInsightYet error
                            completion?(.failure(SpeechFeatureError.noInsightYet))
                        }
                        return
                    }
                    
                    Logger.info("InsightFetcher: \(Feature.featureType.displayName) insight document found: \(document.documentID)")
                    self?.processor.processParsedData(document, completion: completion)
                }
            }
    }
    
    /// Stops the snapshot listener and cleans up resources
    func stopListening() {
        insightsListener?.remove()
        insightsListener = nil
        Logger.info("InsightFetcher: Stopped listening for \(Feature.featureType.displayName)")
    }
} 