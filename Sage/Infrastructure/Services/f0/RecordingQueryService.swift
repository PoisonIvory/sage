import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Handles Firestore queries for user recordings
/// - Extracted from F0DataService to follow Single Responsibility Principle
/// - Focuses solely on querying and filtering recordings
@MainActor
final class RecordingQueryService {
    private let db: Firestore
    private let auth: Auth
    
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }
    
    /// Queries the most recent vocal test recording for the current user
    /// - Returns the recording document reference if found
    /// - Throws F0DataServiceError if no recording found or query fails
    func queryRecentVocalTestRecording() async throws -> DocumentReference {
        guard let userId = auth.currentUser?.uid else {
            throw SpeechFeatureError.invalidDocumentData // Reuse existing case
        }
        
        Logger.info("RecordingQueryService: Querying recordings for user: \(userId)")
        
        let recordingsRef = db.collection("recordings")
        
        let snapshot = try await recordingsRef
            .whereField("userID", isEqualTo: userId)
            .whereField(FirestoreKeys.task, isEqualTo: "onboarding_vocal_test")
            .order(by: FirestoreKeys.sessionTime, descending: true)
            .limit(to: 1)
            .getDocuments()
        
        Logger.info("RecordingQueryService: Query returned \(snapshot.documents.count) documents")
        
        guard let document = snapshot.documents.first else {
            Logger.error("RecordingQueryService: No vocal test recordings found for user: \(userId)")
            throw SpeechFeatureError.invalidDataFormat // Reuse existing case
        }
        
        Logger.info("RecordingQueryService: Found recording document: \(document.documentID)")
        return document.reference
    }
} 