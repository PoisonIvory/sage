import Foundation
import FirebaseFirestore
import FirebaseAuth

/// F0DataService fetches fundamental frequency data from Firestore
/// - Complies with DATA_STANDARDS.md §3.2.1, DATA_DICTIONARY.md, and code quality patterns
final class F0DataService: ObservableObject {
    // MARK: - Published State
    @Published var f0Value: String = "210 Hz" // Default placeholder
    @Published var f0Confidence: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // MARK: - Public Methods
    
    /// Fetches F0 data for the current user from their most recent sustained vowel recording
    func fetchF0Data() {
        guard let userId = Auth.auth().currentUser?.uid else {
            handleError("User not authenticated")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Query for the most recent sustained vowel recording with F0 data
        let recordingsRef = db.collection("users").document(userId).collection("recordings")
        
        recordingsRef
            .whereField("task", isEqualTo: "vowel")
            .order(by: "sessionTime", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.handleError("Failed to fetch recordings: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        self?.handleError("No sustained vowel recordings found")
                        return
                    }
                    
                    self?.fetchF0FromRecording(document.reference)
                }
            }
    }
    
    /// Stops listening for F0 data updates
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchF0FromRecording(_ recordingRef: DocumentReference) {
        let insightsRef = recordingRef.collection("insights")
        
        insightsRef
            .order(by: "created_at", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.handleError("Failed to fetch F0 data: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        self?.handleError("No F0 analysis found for recording")
                        return
                    }
                    
                    self?.processF0Data(document.data())
                }
            }
    }
    
    private func processF0Data(_ data: [String: Any]) {
        guard let features = data["features"] as? [String: Any],
              let praatFeatures = features["praat"] as? [String: Any],
              let meanF0 = praatFeatures["mean_f0"] as? Double,
              let confidence = praatFeatures["f0_confidence"] as? Double else {
            handleError("Invalid F0 data format")
            return
        }
        
        // Validate F0 range (75-500 Hz per DATA_STANDARDS.md §3.2.1)
        guard meanF0 >= 75 && meanF0 <= 500 else {
            handleError("F0 value outside valid range (75-500 Hz)")
            return
        }
        
        // Format F0 value with one decimal place
        f0Value = String(format: "%.1f Hz", meanF0)
        f0Confidence = confidence
        isLoading = false
        
        print("F0DataService: F0 value updated to \(f0Value) with \(confidence)% confidence")
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        print("F0DataService: Error - \(message)")
    }
} 