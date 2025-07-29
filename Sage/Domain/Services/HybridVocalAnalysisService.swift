import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import os.log

// MARK: - Hybrid Vocal Analysis Service Protocol

/// Protocol defining the hybrid vocal analysis service interface
/// GWT: Given need for both immediate and comprehensive voice analysis
/// GWT: When defining service contract
/// GWT: Then protocol supports local + cloud analysis workflow
@MainActor
public protocol VocalAnalysisService: ObservableObject {
    /// Perform hybrid voice analysis (local immediate + cloud comprehensive)
    func analyzeVoice(recording: VoiceRecording, bypassQualityCheck: Bool) async throws -> VocalAnalysisResult
    
    /// Subscribe to real-time comprehensive analysis results
    func subscribeToResults() -> AsyncStream<VocalBiomarkers>
    
    /// Stop listening to real-time updates
    func stopListening()
    
    /// Current analysis state
    var currentState: VocalAnalysisState { get }
}

// MARK: - Hybrid Vocal Analysis Service Implementation

/// Orchestrates local immediate analysis and cloud comprehensive analysis
/// GWT: Given user requests voice analysis
/// GWT: When HybridVocalAnalysisService orchestrates local + remote analysis  
/// GWT: Then user receives immediate feedback and comprehensive results
@MainActor
public final class HybridVocalAnalysisService: VocalAnalysisService, ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var currentState: VocalAnalysisState = .idle
    
    // MARK: - Private Properties
    private let localAnalyzer: LocalVoiceAnalyzer
    private let cloudService: CloudVoiceAnalysisService
    private let firestoreListener: VocalResultsListener
    private var cancellables = Set<AnyCancellable>()
    private let logger = StructuredLogger(component: "HybridAnalysis")
    
    // MARK: - Initialization
    
    public init(
        localAnalyzer: LocalVoiceAnalyzer? = nil,
        cloudService: CloudVoiceAnalysisService? = nil,
        firestoreListener: VocalResultsListener? = nil
    ) {
        self.localAnalyzer = localAnalyzer ?? LocalVoiceAnalyzer()
        self.cloudService = cloudService ?? CloudVoiceAnalysisService()
        self.firestoreListener = firestoreListener ?? VocalResultsListener()
        
        setupSubscriptions()
    }
    
    /// Set up subscriptions to listen for real-time analysis updates
    private func setupSubscriptions() {
        // Listen for VocalResultsListener updates and update our state
        firestoreListener.$latestResults
            .compactMap { $0 } // Only emit when we have results
            .sink { [weak self] biomarkers in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.currentState = .complete(biomarkers)
                    self.logger.info("[HybridVocalAnalysisService] Comprehensive analysis completed - updated state")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - VocalAnalysisService Implementation
    
    /// Performs hybrid voice analysis with immediate local feedback
    /// GWT: Given user completes voice recording
    /// GWT: When analyzing voice with hybrid approach
    /// GWT: Then provides immediate local results and triggers comprehensive analysis
    public func analyzeVoice(recording: VoiceRecording) async throws -> VocalAnalysisResult {
        return try await logger.startAsyncOperation("hybrid_voice_analysis", 
                                                   recordingId: recording.id, 
                                                   userId: recording.userId,
                                                   extra: ["duration": recording.duration]) { operation in
            
            // Phase 1: Immediate Local Analysis (< 5 seconds)
            operation.logProgress("Starting local analysis phase")
            currentState = .localAnalyzing
            
            do {
                let localMetrics = try await performLocalAnalysis(recording: recording, operation: operation)
                
                operation.logProgress("Local analysis completed", extra: [
                    "f0_mean_hz": localMetrics.f0Mean,
                    "confidence_percent": localMetrics.confidence
                ])
                
                // Update state with immediate results
                let immediateResult = VocalAnalysisResult(
                    recordingId: recording.id,
                    localMetrics: localMetrics,
                    comprehensiveAnalysis: nil,
                    status: .localComplete
                )
                
                currentState = .localComplete(localMetrics)
                
                // Phase 2: Cloud Analysis (30-60 seconds)
                operation.logProgress("Triggering cloud analysis phase")
                Task {
                    await triggerCloudAnalysis(recording: recording)
                }
                
                return immediateResult
                
            } catch {
                operation.logError("Local analysis failed", error: error)
                currentState = .error("Local analysis failed: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Subscribe to real-time comprehensive analysis results from Firestore
    /// GWT: Given cloud analysis writes results to Firestore
    /// GWT: When subscribing to real-time updates
    /// GWT: Then receives comprehensive VocalBiomarkers as they become available
    public func subscribeToResults() -> AsyncStream<VocalBiomarkers> {
        return AsyncStream { continuation in
            let cancellable = firestoreListener.resultsPublisher
                .compactMap { $0 }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.logger.error("Results subscription error: \(error.localizedDescription)")
                        }
                        continuation.finish()
                    },
                    receiveValue: { biomarkers in
                        continuation.yield(biomarkers)
                    }
                )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Stop listening to real-time updates and cleanup resources
    public func stopListening() {
        firestoreListener.stopListening()
        cancellables.removeAll()
        currentState = .idle
        logger.info("Stopped listening to vocal analysis results")
    }
    
    // MARK: - Private Methods
    
    /// Perform immediate local analysis using iOS capabilities
    private func performLocalAnalysis(recording: VoiceRecording, operation: OperationLogger) async throws -> BasicVoiceMetrics {
        // Validate audio quality first
        operation.logProgress("Validating audio quality")
        let qualityResult = try localAnalyzer.validateAudioQuality(audioURL: recording.audioURL)
        guard qualityResult.isValid else {
            operation.logError("Audio quality validation failed", extra: ["reason": qualityResult.reason])
            throw VocalAnalysisError.invalidAudioQuality(qualityResult.reason)
        }
        
        operation.logProgress("Audio quality validation passed")
        
        // Perform local analysis
        operation.logProgress("Starting iOS-native voice analysis")
        let startTime = Date()
        let metrics = try await localAnalyzer.analyzeImmediate(audioURL: recording.audioURL)
        let processingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        
        operation.logProgress("Local analysis completed", extra: [
            "processing_time_ms": processingTime,
            "f0_mean_hz": metrics.f0Mean,
            "confidence_percent": metrics.confidence,
            "analysis_method": "ios_native"
        ])
        
        // Log performance metrics
        logger.performance("local_voice_analysis", durationMs: processingTime, 
                          context: LogContext(recordingId: recording.id, operation: "local_analysis"),
                          extra: ["f0_mean_hz": metrics.f0Mean, "confidence_percent": metrics.confidence])
        
        return metrics
    }
    
    /// Trigger comprehensive cloud analysis
    private func triggerCloudAnalysis(recording: VoiceRecording) async {
        await logger.startAsyncOperation("cloud_analysis_trigger", 
                                        recordingId: recording.id, 
                                        userId: recording.userId,
                                        extra: ["duration": recording.duration]) { operation in
            
            currentState = .cloudAnalyzing
            
            do {
                // Upload to Cloud Storage and trigger Cloud Function
                operation.logProgress("Starting cloud storage upload")
                try await cloudService.uploadAndAnalyze(recording: recording)
                operation.logProgress("Cloud storage upload completed")
                
                // Start listening for Firestore results
                operation.logProgress("Starting Firestore listener for results")
                firestoreListener.startListening(for: recording.id)
                
                operation.logProgress("Cloud analysis pipeline triggered successfully")
                
            } catch {
                operation.logError("Cloud analysis trigger failed", error: error, extra: [
                    "error_type": String(describing: type(of: error)),
                    "current_state": String(describing: currentState)
                ])
                currentState = .error("Cloud analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
}

// MARK: - Supporting Types

/// Represents a voice recording for analysis
public struct VoiceRecording: Identifiable, Equatable {
    public let id: String
    public let audioURL: URL
    public let duration: TimeInterval
    public let recordedAt: Date
    public let userId: String
    
    public init(id: String = UUID().uuidString, audioURL: URL, duration: TimeInterval, recordedAt: Date = Date(), userId: String) {
        self.id = id
        self.audioURL = audioURL
        self.duration = duration
        self.recordedAt = recordedAt
        self.userId = userId
    }
}

/// Result of hybrid vocal analysis
public struct VocalAnalysisResult: Equatable {
    public let recordingId: String
    public let localMetrics: BasicVoiceMetrics
    public let comprehensiveAnalysis: VocalBiomarkers?
    public let status: AnalysisStatus
    
    public init(recordingId: String, localMetrics: BasicVoiceMetrics, comprehensiveAnalysis: VocalBiomarkers?, status: AnalysisStatus) {
        self.recordingId = recordingId
        self.localMetrics = localMetrics
        self.comprehensiveAnalysis = comprehensiveAnalysis
        self.status = status
    }
}

/// Status of vocal analysis process
public enum AnalysisStatus: String, Codable, CaseIterable {
    case localComplete = "local_complete"
    case cloudProcessing = "cloud_processing"
    case complete = "complete"
    case failed = "failed"
}

/// State of vocal analysis service
public enum VocalAnalysisState: Equatable {
    case idle
    case localAnalyzing
    case localComplete(BasicVoiceMetrics)
    case cloudAnalyzing  
    case complete(VocalBiomarkers)
    case error(String)
    
    /// User-friendly state description
    public var description: String {
        switch self {
        case .idle:
            return "Ready for voice analysis"
        case .localAnalyzing:
            return "Processing recording..."
        case .localComplete(let metrics):
            return "Initial analysis complete (\(Int(metrics.confidence))% confidence)"
        case .cloudAnalyzing:
            return "Comprehensive analysis in progress..."
        case .complete:
            return "Voice analysis complete"
        case .error(let message):
            return "Analysis error: \(message)"
        }
    }
    
    /// Whether analysis is in progress
    public var isAnalyzing: Bool {
        switch self {
        case .localAnalyzing, .cloudAnalyzing:
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur during vocal analysis
public enum VocalAnalysisError: Error, LocalizedError {
    case invalidAudioQuality(String)
    case localAnalysisFailed(Error)
    case cloudAnalysisFailed(Error)
    case userNotAuthenticated
    case networkError(Error)
    case timeout
    case noAnalysisResult
    case incompleteAnalysis
    case baselineValidationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidAudioQuality(let reason):
            return "Audio quality insufficient: \(reason)"
        case .localAnalysisFailed(let error):
            return "Local analysis failed: \(error.localizedDescription)"
        case .cloudAnalysisFailed(let error):
            return "Cloud analysis failed: \(error.localizedDescription)"
        case .userNotAuthenticated:
            return "User authentication required for voice analysis"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Analysis timed out, please try again"
        case .noAnalysisResult:
            return "No analysis result available"
        case .incompleteAnalysis:
            return "Analysis incomplete - comprehensive data required"
        case .baselineValidationFailed:
            return "Baseline does not meet clinical quality standards"
        }
    }
}

// MARK: - Cloud Voice Analysis Service

/// Service for managing cloud-based comprehensive voice analysis with retry logic
public class CloudVoiceAnalysisService {
    private let storage = Storage.storage()
    private let logger = StructuredLogger(component: "CloudAnalysis")
    
    // Retry configuration
    private let maxRetryAttempts = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private let maxRetryDelay: TimeInterval = 8.0
    
    public init() {}
    
    /// Upload recording to Cloud Storage and trigger analysis with retry logic
    /// GWT: Given voice recording needs comprehensive analysis
    /// GWT: When uploading to Cloud Storage with network issues
    /// GWT: Then retries with exponential backoff and provides detailed error feedback
    public func uploadAndAnalyze(recording: VoiceRecording) async throws {
        try await logger.startAsyncOperation("cloud_upload_and_analyze", 
                                            recordingId: recording.id, 
                                            userId: recording.userId,
                                            extra: ["duration": recording.duration]) { operation in
            
            guard let userId = Auth.auth().currentUser?.uid else {
                operation.logError("No authenticated user found for cloud analysis")
                throw VocalAnalysisError.userNotAuthenticated
            }
            
            operation.logProgress("Authentication verified", extra: ["user_id": userId])
            
            // Validate recording before upload
            operation.logProgress("Validating recording for cloud analysis")
            try validateRecordingForCloudAnalysis(recording)
            
            let storageRef = storage.reference()
                .child("sage-audio-files")
                .child(recording.userId)
                .child("\(recording.id).wav")
            
            operation.logProgress("Storage reference created", extra: [
                "storage_path": "sage-audio-files/\(recording.userId)/\(recording.id).wav"
            ])
            
            // Attempt upload with retry logic
            for attempt in 1...maxRetryAttempts {
                do {
                    operation.logProgress("Starting upload attempt \(attempt)/\(maxRetryAttempts)")
                    try await performUpload(storageRef: storageRef, recording: recording, attempt: attempt, operation: operation)
                    
                    operation.logProgress("Upload successful", extra: [
                        "attempt": attempt,
                        "total_attempts": maxRetryAttempts
                    ])
                    return
                    
                } catch let error as VocalAnalysisError {
                    // Don't retry authentication or validation errors
                    if case .userNotAuthenticated = error,
                       case .invalidAudioQuality = error {
                        operation.logError("Non-retryable error encountered", error: error, extra: [
                            "attempt": attempt,
                            "error_category": "non_retryable"
                        ])
                        throw error
                    }
                    
                    if attempt == self.maxRetryAttempts {
                        operation.logError("Upload failed after all retry attempts", error: error, extra: [
                            "total_attempts": self.maxRetryAttempts,
                            "final_attempt": attempt
                        ])
                        throw error
                    }
                    
                    let retryDelay = min(self.baseRetryDelay * pow(2.0, Double(attempt - 1)), self.maxRetryDelay)
                    operation.logWarning("Upload attempt failed, retrying", extra: [
                        "attempt": attempt,
                        "retry_delay_seconds": retryDelay,
                        "error_message": error.localizedDescription
                    ])
                    
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    
                } catch {
                    if attempt == self.maxRetryAttempts {
                        operation.logError("Upload failed after all retry attempts", error: error, extra: [
                            "total_attempts": self.maxRetryAttempts,
                            "final_attempt": attempt
                        ])
                        throw VocalAnalysisError.cloudAnalysisFailed(error)
                    }
                    
                    let retryDelay = min(self.baseRetryDelay * pow(2.0, Double(attempt - 1)), self.maxRetryDelay)
                    operation.logWarning("Upload attempt failed, retrying", extra: [
                        "attempt": attempt,
                        "retry_delay_seconds": retryDelay,
                        "error_message": error.localizedDescription
                    ])
                    
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
    }
    
    /// Validate recording meets cloud analysis requirements
    private func validateRecordingForCloudAnalysis(_ recording: VoiceRecording) throws {
        // Check file exists
        guard FileManager.default.fileExists(atPath: recording.audioURL.path) else {
            throw VocalAnalysisError.invalidAudioQuality("Audio file not found at path")
        }
        
        // Check minimum duration (0.5 seconds for meaningful analysis)
        guard recording.duration >= 0.5 else {
            throw VocalAnalysisError.invalidAudioQuality("Recording too short for analysis (minimum 0.5s)")
        }
        
        // Check maximum duration (30 seconds to avoid cloud function timeout)
        guard recording.duration <= 30.0 else {
            throw VocalAnalysisError.invalidAudioQuality("Recording too long for analysis (maximum 30s)")
        }
        
        logger.info("Recording validation passed: duration=\(recording.duration)s")
    }
    
    /// Perform single upload attempt
    private func performUpload(storageRef: StorageReference, recording: VoiceRecording, attempt: Int, operation: OperationLogger) async throws {
        logger.info("Upload attempt \(attempt) for recording: \(recording.id)")
        
        let uploadTask = storageRef.putFile(from: recording.audioURL)
        
        // Set upload timeout (60 seconds)
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 60_000_000_000)
            throw VocalAnalysisError.timeout
        }
        
        let uploadContinuation: () async throws -> Void = {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                uploadTask.observe(.success) { snapshot in
                    if let metadata = snapshot.metadata {
                        self.logger.info("Upload completed: size=\(metadata.size) bytes, contentType=\(metadata.contentType ?? "unknown")")
                    }
                    continuation.resume()
                }
                
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        self.logger.error("Upload failed: \(error.localizedDescription)")
                        continuation.resume(throwing: VocalAnalysisError.cloudAnalysisFailed(error))
                    } else {
                        continuation.resume(throwing: VocalAnalysisError.cloudAnalysisFailed(NSError(domain: "UnknownUploadFailure", code: -1)))
                    }
                }
                
                // Monitor upload progress
                uploadTask.observe(.progress) { snapshot in
                    if let progress = snapshot.progress {
                        let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100
                        if Int(percentComplete) % 25 == 0 { // Log every 25%
                            self.logger.info("Upload progress: \(Int(percentComplete))%")
                        }
                    }
                }
            }
        }
        
        // Race between upload and timeout
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await uploadContinuation() }
            group.addTask { try await timeoutTask.value }
            
            try await group.next()
            group.cancelAll()
        }
    }
}


// MARK: - Vocal Results Listener

/// Service for listening to real-time Firestore updates for vocal analysis results
public class VocalResultsListener: ObservableObject {
    private let firestore = Firestore.firestore()
    private let logger = StructuredLogger(component: "VocalResultsListener")
    private var listener: ListenerRegistration?
    
    @Published public private(set) var latestResults: VocalBiomarkers?
    @Published public private(set) var isListening = false
    
    /// Publisher for real-time results updates
    public var resultsPublisher: AnyPublisher<VocalBiomarkers?, Never> {
        return $latestResults.eraseToAnyPublisher()
    }
    
    public init() {}
    
    /// Start listening for analysis results for a specific recording
    public func startListening(for recordingId: String) {
        logger.debug("[VocalResultsListener] Starting to listen for recording: \(recordingId)")
        
        // Stop any previous listener
        stopListening()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.error("[VocalResultsListener] No authenticated user")
            return
        }
        
        isListening = true
        
        // Listen to user-specific path for real-time updates
        let documentRef = firestore
            .collection("users")
            .document(userId)
            .collection("voice_analyses")
            .document(recordingId)
        
        listener = documentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("[VocalResultsListener] Firestore listener error: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot,
                  document.exists,
                  let data = document.data() else {
                self.logger.debug("[VocalResultsListener] No data found for recording: \(recordingId)")
                return
            }
            
            // Parse Firestore data into VocalBiomarkers
            if let biomarkers = self.parseFirestoreData(data) {
                DispatchQueue.main.async {
                    self.latestResults = biomarkers
                    self.logger.info("[VocalResultsListener] Received comprehensive analysis results for: \(recordingId)")
                }
            } else {
                self.logger.warning("[VocalResultsListener] Failed to parse Firestore data for: \(recordingId)")
            }
        }
        
        logger.info("[VocalResultsListener] Started listening for recording: \(recordingId)")
    }
    
    /// Stop listening for analysis results
    public func stopListening() {
        listener?.remove()
        listener = nil
        isListening = false
        logger.debug("[VocalResultsListener] Stopped listening for results")
    }
    
    /// Parse Firestore document data into VocalBiomarkers
    private func parseFirestoreData(_ data: [String: Any]) -> VocalBiomarkers? {
        // Extract all required fields with validation
        guard let f0Mean = data["vocal_analysis_f0_mean"] as? Double,
              let f0Std = data["vocal_analysis_f0_std"] as? Double,
              let f0Confidence = data["vocal_analysis_f0_confidence"] as? Double,
              let jitterLocal = data["vocal_analysis_jitter_local"] as? Double,
              let jitterAbsolute = data["vocal_analysis_jitter_absolute"] as? Double,
              let jitterRap = data["vocal_analysis_jitter_rap"] as? Double,
              let jitterPpq5 = data["vocal_analysis_jitter_ppq5"] as? Double,
              let shimmerLocal = data["vocal_analysis_shimmer_local"] as? Double,
              let shimmerDb = data["vocal_analysis_shimmer_db"] as? Double,
              let shimmerApq3 = data["vocal_analysis_shimmer_apq3"] as? Double,
              let shimmerApq5 = data["vocal_analysis_shimmer_apq5"] as? Double,
              let hnrMean = data["vocal_analysis_hnr_mean"] as? Double,
              let hnrStd = data["vocal_analysis_hnr_std"] as? Double,
              let stabilityScore = data["vocal_analysis_vocal_stability_score"] as? Double else {
            
            logger.warning("[VocalResultsListener] Incomplete vocal analysis data in Firestore document")
            return nil
        }
        
        // Construct domain models
        let f0Analysis = F0Analysis(mean: f0Mean, std: f0Std, confidence: f0Confidence)
        
        let jitterMeasures = JitterMeasures(
            local: jitterLocal,
            absolute: jitterAbsolute,
            rap: jitterRap,
            ppq5: jitterPpq5
        )
        
        let shimmerMeasures = ShimmerMeasures(
            local: shimmerLocal,
            db: shimmerDb,
            apq3: shimmerApq3,
            apq5: shimmerApq5
        )
        
        let hnrAnalysis = HNRAnalysis(mean: hnrMean, std: hnrStd)
        
        let voiceQuality = VoiceQualityAnalysis(
            jitter: jitterMeasures,
            shimmer: shimmerMeasures,
            hnr: hnrAnalysis
        )
        
        let stabilityComponents = StabilityComponents(
            f0Score: f0Confidence * 0.4,
            jitterScore: max(0, 100 - jitterLocal * 20) * 0.2,
            shimmerScore: max(0, 100 - shimmerLocal * 10) * 0.2,
            hnrScore: min(100, hnrMean * 5) * 0.2
        )
        
        let stability = VocalStabilityScore(score: stabilityScore, components: stabilityComponents)
        
        let metadata = VoiceAnalysisMetadata(
            recordingDuration: data["vocal_analysis_metadata_duration"] as? Double ?? 10.0,
            sampleRate: data["vocal_analysis_metadata_sample_rate"] as? Double ?? 48000.0,
            voicedRatio: data["vocal_analysis_metadata_voiced_ratio"] as? Double ?? 0.8,
            analysisTimestamp: Date(),
            analysisSource: .cloudParselmouth
        )
        
        return VocalBiomarkers(
            f0: f0Analysis,
            voiceQuality: voiceQuality,
            stability: stability,
            metadata: metadata
        )
    }
    
    deinit {
        stopListening()
    }
}