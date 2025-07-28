import Foundation
import FirebaseFirestore
import FirebaseAuth
import os.log

// MARK: - Constants

private struct F0DataServiceStrings {
    static let stillProcessing = "Still Processing..."
    static let loading = "Loading..."
    static let processingError = "Processing Error"
    static let userNotAuthenticated = "User not authenticated"
    static let invalidDocumentData = "Invalid document data"
    static let invalidF0DataFormat = "Invalid F0 data format"
    static let f0ValueOutOfRange = "F0 value outside valid range (75-500 Hz)"
    static let failedToFetchRecordings = "Failed to fetch recordings: "
    static let noVocalTestRecordings = "No vocal test recordings found"
    static let failedToFetchF0Data = "Failed to fetch F0 data: "
    static let noF0AnalysisFound = "No F0 analysis found for recording"
}

private enum FirestoreKeys {
    static let f0Mean = "f0_mean"
    static let confidence = "f0_confidence"
    static let status = "status"
    static let errorType = "error_type"
    static let metadata = "processing_metadata"
    static let audioDuration = "audio_duration"
    static let voicedFrames = "voiced_frames"
    static let totalFrames = "total_frames"
    static let insightType = "insight_type"
    static let createdAt = "created_at"
    static let task = "task"
    static let sessionTime = "session_time"
}

// MARK: - Models

struct F0ProcessingMetadata {
    let audioDuration: Double
    let voicedFrames: Int
    let totalFrames: Int
    
    init(dictionary: [String: Any]) {
        self.audioDuration = dictionary[FirestoreKeys.audioDuration] as? Double ?? 0
        self.voicedFrames = dictionary[FirestoreKeys.voicedFrames] as? Int ?? 0
        self.totalFrames = dictionary[FirestoreKeys.totalFrames] as? Int ?? 0
    }
}

enum F0State {
    case idle
    case loading
    case success(value: String, confidence: Double)
    case error(String)
}

/// F0DataService fetches fundamental frequency data from Firestore
/// - Complies with DATA_STANDARDS.md §3.2.1, DATA_DICTIONARY.md, and code quality patterns
@MainActor
final class F0DataService: ObservableObject {
    // MARK: - Published State
    @Published var state: F0State = .idle
    
    // MARK: - Private Properties
    private let db: Firestore
    private let auth: Auth

    
    // MARK: - Initialization
    
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }
    
    // MARK: - Convenience Properties (for backward compatibility)
    
    var f0Value: String {
        switch state {
        case .idle:
            return F0DataServiceStrings.stillProcessing
        case .loading:
            return F0DataServiceStrings.loading
        case .success(let value, _):
            return value
        case .error:
            return F0DataServiceStrings.processingError
        }
    }
    
    var f0Confidence: Double {
        switch state {
        case .success(_, let confidence):
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
    
    // MARK: - Public Methods
    
    /// Fetches F0 data for the current user from their most recent sustained vowel recording
    func fetchF0Data(completion: (() -> Void)? = nil) {
        guard validateUserAuthentication() else {
            completion?()
            return
        }
        
        startLoading()
        queryRecentRecordings(completion: completion)
    }
    
    // MARK: - Private Helper Methods
    
    private func validateUserAuthentication() -> Bool {
        guard let userId = auth.currentUser?.uid else {
            handleError(F0DataServiceStrings.userNotAuthenticated)
            return false
        }
        return true
    }
    
    private func startLoading() {
        state = .loading
    }
    
    private func queryRecentRecordings(completion: (() -> Void)? = nil) {
        guard let userId = auth.currentUser?.uid else { 
            completion?()
            return 
        }
        
        print("[F0DataService] Querying recordings for user: \(userId)")
        
        // Query the root "recordings" collection, filtered by user_id
        let recordingsRef = db.collection("recordings")
        
        recordingsRef
            .whereField("user_id", isEqualTo: userId)
            .whereField(FirestoreKeys.task, isEqualTo: "onboarding_vocal_test")
            .order(by: FirestoreKeys.sessionTime, descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                Task { @MainActor in
                    if let error = error {
                        print("[F0DataService] Query error: \(error.localizedDescription)")
                        self?.handleError("\(F0DataServiceStrings.failedToFetchRecordings)\(error.localizedDescription)")
                        completion?()
                        return
                    }
                    
                    print("[F0DataService] Query returned \(snapshot?.documents.count ?? 0) documents")
                    
                    guard let document = snapshot?.documents.first else {
                        print("[F0DataService] No vocal test recordings found for user: \(userId)")
                        self?.handleError(F0DataServiceStrings.noVocalTestRecordings)
                        completion?()
                        return
                    }
                    
                    print("[F0DataService] Found recording document: \(document.documentID)")
                    self?.fetchF0FromRecording(document.reference, completion: completion)
                }
            }
    }
    
    // MARK: - Internal Helper Methods (accessible for testing)
    
    internal func processF0Data(_ document: DocumentSnapshot, completion: (() -> Void)? = nil) {
        guard let data = document.data() else {
            handleError(F0DataServiceStrings.invalidDocumentData)
            completion?()
            return
        }
        
        processF0Data(documentID: document.documentID, data: data, completion: completion)
    }
    
    internal func processF0Data(documentID: String, data: [String: Any], completion: (() -> Void)? = nil) {
        let insightId = documentID
        Logger.info("Processing F0 insight document: \(insightId)")
        
        guard validateAndParseF0Data(data, insightId: insightId) else { 
            completion?()
            return 
        }
        processMetadata(data, insightId: insightId)
        completeProcessing(insightId: insightId)
        completion?()
    }
    
    private func validateAndParseF0Data(_ data: [String: Any], insightId: String) -> Bool {
        guard let f0Mean = data[FirestoreKeys.f0Mean] as? Double else {
            handleError(F0DataServiceStrings.invalidF0DataFormat)
            return false
        }
        
        guard f0Mean >= 75 && f0Mean <= 500 else {
            handleError(F0DataServiceStrings.f0ValueOutOfRange)
            return false
        }
        
        let confidence = data[FirestoreKeys.confidence] as? Double ?? 0.0
        handleSuccess(f0: f0Mean, confidence: confidence, insightId: insightId)
        
        return true
    }
    
    private func processMetadata(_ data: [String: Any], insightId: String) {
        if let status = data[FirestoreKeys.status] as? String, status == "completed_with_warnings" {
            Logger.info("F0 analysis completed with warnings for insight: \(insightId)")
        }
        
        if let errorType = data[FirestoreKeys.errorType] as? String {
            Logger.info("F0 analysis error type: \(errorType) for insight: \(insightId)")
        }
        
        if let processingMetadata = data[FirestoreKeys.metadata] as? [String: Any] {
            logProcessingMetadata(processingMetadata)
        }
    }
    
    private func logProcessingMetadata(_ metadata: [String: Any]) {
        let processingMetadata = F0ProcessingMetadata(dictionary: metadata)
        Logger.info("F0 processed: \(processingMetadata.audioDuration)s audio, \(processingMetadata.voicedFrames)/\(processingMetadata.totalFrames) voiced frames")
    }
    
    private func handleSuccess(f0: Double, confidence: Double, insightId: String) {
        let valueString = String(format: "%.1f Hz", f0)
        state = .success(value: valueString, confidence: confidence)
        Logger.info("F0 value updated to \(valueString) with \(confidence)% confidence for insight: \(insightId)")
    }
    
    private func completeProcessing(insightId: String) {
        // State is already set in handleSuccess
        // Additional completion logic can be added here if needed
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchF0FromRecording(_ recordingRef: DocumentReference, completion: (() -> Void)? = nil) {
        let insightsRef = recordingRef.collection("insights")
        
        insightsRef
            .whereField(FirestoreKeys.insightType, isEqualTo: "f0_analysis")
            .order(by: FirestoreKeys.createdAt, descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                Task { @MainActor in
                    if let error = error {
                        self?.handleError("\(F0DataServiceStrings.failedToFetchF0Data)\(error.localizedDescription)")
                        completion?()
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        self?.handleError(F0DataServiceStrings.noF0AnalysisFound)
                        completion?()
                        return
                    }
                    
                    self?.processF0Data(document, completion: completion)
                }
            }
    }
    

    
    private func handleError(_ message: String) {
        state = .error(message)
        Logger.error("F0DataService error: \(message)")
    }
    
    /// Stops any ongoing operations and cleans up resources
    func stopListening() {
        state = .idle
        Logger.info("F0DataService: Stopped listening")
    }
} 