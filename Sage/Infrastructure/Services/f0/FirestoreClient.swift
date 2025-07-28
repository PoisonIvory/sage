import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Client Protocol

/// Abstract interface for Firestore operations
/// - Decouples domain logic from Firebase implementation
/// - Enables easier testing and potential backend switching
@preconcurrency
protocol FirestoreClient {
    func queryRecentVocalTestRecording() async throws -> DocumentReference
    func setupInsightsListener(
        for recordingRef: DocumentReference,
        insightType: String,
        completion: @escaping (Result<DocumentSnapshot, Error>) -> Void
    ) -> ListenerRegistration
    func removeListener(_ listener: ListenerRegistration)
}

// MARK: - Firebase Firestore Implementation

/// Concrete implementation using Firebase Firestore
/// - Implements FirestoreClient protocol
/// - Handles actual Firebase operations
@MainActor
final class FirebaseFirestoreClient: FirestoreClient {
    private let db: Firestore
    private let auth: Auth
    
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }
    
    func queryRecentVocalTestRecording() async throws -> DocumentReference {
        guard let userId = auth.currentUser?.uid else {
            throw SpeechFeatureError.invalidDocumentData // Reuse existing case
        }
        
        Logger.info("FirebaseFirestoreClient: Querying recordings for user: \(userId)")
        
        let recordingsRef = db.collection("recordings")
        
        let snapshot = try await recordingsRef
            .whereField("userID", isEqualTo: userId)
            .whereField(FirestoreKeys.task, isEqualTo: "onboarding_vocal_test")
            .order(by: FirestoreKeys.sessionTime, descending: true)
            .limit(to: 1)
            .getDocuments()
        
        Logger.info("FirebaseFirestoreClient: Query returned \(snapshot.documents.count) documents")
        
        guard let document = snapshot.documents.first else {
            Logger.error("FirebaseFirestoreClient: No vocal test recordings found for user: \(userId)")
            throw SpeechFeatureError.invalidDataFormat // Reuse existing case
        }
        
        Logger.info("FirebaseFirestoreClient: Found recording document: \(document.documentID)")
        return document.reference
    }
    
    nonisolated func setupInsightsListener(
        for recordingRef: DocumentReference,
        insightType: String,
        completion: @escaping (Result<DocumentSnapshot, Error>) -> Void
    ) -> ListenerRegistration {
        let insightsRef = recordingRef.collection("insights")
        
        Logger.info("FirebaseFirestoreClient: Setting up snapshot listener for \(insightType) insights in recording: \(recordingRef.documentID)")
        
        return insightsRef
            .whereField(FirestoreKeys.insightType, isEqualTo: insightType)
            .order(by: FirestoreKeys.createdAt, descending: true)
            .limit(to: 1)
            .addSnapshotListener { (snapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    Logger.error("FirebaseFirestoreClient: Snapshot listener error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    Logger.info("FirebaseFirestoreClient: No \(insightType) insights found yet for recording: \(recordingRef.documentID)")
                    completion(.failure(SpeechFeatureError.noInsightYet))
                    return
                }
                
                Logger.info("FirebaseFirestoreClient: \(insightType) insight document found: \(document.documentID)")
                completion(.success(document))
            }
    }
    
    nonisolated func removeListener(_ listener: ListenerRegistration) {
        listener.remove()
        Logger.info("FirebaseFirestoreClient: Removed listener")
    }
}

// MARK: - Mock Firestore Client for Testing

/// Mock implementation for testing
/// - Implements FirestoreClient protocol
/// - Provides controlled test data
@MainActor
final class MockFirestoreClient: FirestoreClient {
    var shouldFailQuery = false
    var shouldFailListener = false
    var mockRecordingRef: DocumentReference?
    var mockInsightDocument: DocumentSnapshot?
    
    func queryRecentVocalTestRecording() async throws -> DocumentReference {
        if shouldFailQuery {
            throw SpeechFeatureError.invalidDataFormat // Reuse existing case
        }
        
        guard let mockRef = mockRecordingRef else {
            throw SpeechFeatureError.invalidDataFormat // Reuse existing case
        }
        
        return mockRef
    }
    
    nonisolated func setupInsightsListener(
        for recordingRef: DocumentReference,
        insightType: String,
        completion: @escaping (Result<DocumentSnapshot, Error>) -> Void
    ) -> ListenerRegistration {
        Task { @MainActor in
            if shouldFailListener {
                completion(.failure(SpeechFeatureError.noInsightYet))
            } else if let mockDocument = mockInsightDocument {
                completion(.success(mockDocument))
            } else {
                completion(.failure(SpeechFeatureError.noInsightYet))
            }
        }
        
        // Return a mock listener registration
        return MockListenerRegistration()
    }
    
    nonisolated func removeListener(_ listener: ListenerRegistration) {
        // Mock implementation - no action needed
    }
}

// MARK: - Mock Listener Registration

private class MockListenerRegistration: NSObject, ListenerRegistration {
    func remove() {
        // Mock implementation - no action needed
    }
}

 