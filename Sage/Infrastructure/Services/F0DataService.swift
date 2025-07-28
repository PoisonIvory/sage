import Foundation
import FirebaseFirestore
import FirebaseAuth
import os.log

// MARK: - Timer Protocol for Testability

protocol TimerHandler {
    func schedule(timeout: TimeInterval, callback: @escaping () -> Void)
    func cancel()
}

class RealTimerHandler: TimerHandler {
    private var timer: Timer?
    
    func schedule(timeout: TimeInterval, callback: @escaping () -> Void) {
        cancel() // Cancel any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            callback()
        }
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Updated F0DataService Using New Architecture

/// Refactored F0DataService that uses the new generic architecture
/// - Conforms to SpeechFeatureService protocol
/// - Uses generic InsightProcessor and InsightFetcher
/// - Maintains backward compatibility
@MainActor
final class F0DataService: SpeechFeatureService, FeatureStateHandler {
    // MARK: - Published State
    @Published private(set) var state: FeatureState = .idle
    
    // MARK: - SpeechFeatureService Implementation
    let featureType: SpeechFeatureType = .f0
    
    // MARK: - Private Properties
    private let firestoreClient: FirestoreClient
    private let insightProcessor: InsightProcessor<F0Feature>
    private let insightFetcher: InsightFetcher<F0Feature>
    private let timerHandler: TimerHandler
    internal let processingTimeout: TimeInterval = 60.0 // 60 seconds timeout
    
    // MARK: - Initialization
    
    init(
        firestoreClient: FirestoreClient? = nil,
        timerHandler: TimerHandler = RealTimerHandler()
    ) {
        let client = firestoreClient ?? FirebaseFirestoreClient()
        self.firestoreClient = client
        self.timerHandler = timerHandler
        
        // Create processor and fetcher
        self.insightProcessor = InsightProcessor<F0Feature>()
        self.insightFetcher = InsightFetcher<F0Feature>(processor: insightProcessor)
        
        // Set the state handler after initialization to avoid circular reference
        Task { @MainActor in
            insightProcessor.setStateHandler(self)
        }
    }
    
    deinit {
        Task { @MainActor in
            stopListening()
        }
    }
    
    // MARK: - SpeechFeatureService Implementation
    
    nonisolated func fetchFeatureData(completion: ((Result<Void, Error>) -> Void)? = nil) {
        Task { @MainActor in
            guard await validateUserAuthentication() else {
                completion?(.failure(SpeechFeatureError.invalidDocumentData)) // Reuse existing case
                return
            }
            
            await startLoading()
            await startTimeoutTimer()
        }
        
        Task {
            do {
                let recordingRef = try await firestoreClient.queryRecentVocalTestRecording()
                await insightFetcher.setupInsightsListener(for: recordingRef, completion: completion)
            } catch {
                handleError(error.localizedDescription)
                completion?(.failure(error))
            }
        }
    }
    
    nonisolated func stopListening() {
        Task { @MainActor in
            await insightFetcher.stopListening()
            timerHandler.cancel()
            insightProcessor.reset()
            state = .idle
            Logger.info("F0DataService: Stopped listening")
        }
    }
    
    // MARK: - FeatureStateHandler Implementation
    
    nonisolated func handleSuccess(value: String, confidence: Double, metadata: SpeechFeatureMetadata?) {
        Task { @MainActor in
            state = .success(value: value, confidence: confidence, metadata: metadata)
            timerHandler.cancel() // Clear timeout on success
        }
    }
    
    nonisolated func handleError(_ message: String) {
        Task { @MainActor in
            state = .error(message)
            timerHandler.cancel() // Clear timeout on error
            Logger.error("F0DataService error: \(message)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func validateUserAuthentication() -> Bool {
        guard Auth.auth().currentUser?.uid != nil else {
            handleError("User not authenticated")
            return false
        }
        return true
    }
    
    private func startLoading() {
        state = .loading
    }
    
    private func startTimeoutTimer() {
        timerHandler.schedule(timeout: processingTimeout) { [weak self] in
            Task { @MainActor in
                self?.handleTimeout()
            }
        }
    }
    
    internal func handleTimeout() {
        // Only handle timeout if still in loading state (race condition protection)
        if case .loading = state {
            Logger.error("F0DataService: Processing timeout after \(processingTimeout) seconds")
            handleError("Processing delayed, please check back later")
        }
    }
}

// MARK: - Backward Compatibility Extensions

extension F0DataService {
    var displayF0Value: String { displayValue }
    var f0Confidence: Double { confidence }
    var lastMetadata: F0ProcessingMetadata? {
        switch state {
        case .success(_, _, let metadata):
            return metadata as? F0ProcessingMetadata
        default:
            return nil
        }
    }
    
    /// Fetches F0 data for the current user from their most recent sustained vowel recording
    /// Uses snapshot listeners for real-time updates when insights are written
    func fetchF0Data() async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            fetchFeatureData { result in
                continuation.resume(returning: result)
            }
        }
    }
} 