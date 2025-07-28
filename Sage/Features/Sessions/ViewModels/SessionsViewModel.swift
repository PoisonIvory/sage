import Foundation
import Combine
import SwiftUI
// import Protocols.swift if needed

/// SessionsViewModel manages the list of voice sessions, validation, and upload.
/// - Complies with DATA_STANDARDS.md §2.1, §2.2, §3.3, §3.4, DATA_DICTIONARY.md, RESOURCES.md, CONTRIBUTING.md.
final class SessionsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var recordings: [Recording] = []
    @Published var errorMessage: String? = nil
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastValidationResult: RecordingValidationResult?
    @Published var currentPromptID: String? = nil
    @Published var showRecordingModal: Bool = false
    @Published var uploadSuccess: Bool = false

    // MARK: - Dependencies
    private let audioManager: AudioRecordingManaging
    private let uploader: RecordingUploaderServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(audioManager: AudioRecordingManaging = AudioRecorder.shared as AudioRecordingManaging,
         uploader: RecordingUploaderServiceProtocol = RecordingUploaderService.shared as RecordingUploaderServiceProtocol) {
        self.audioManager = audioManager
        self.uploader = uploader
        self.recordings = audioManager.recordings
        // Removed objectWillChange observation due to protocol update (see DATA_STANDARDS.md §2.2.1)
    }

    // MARK: - Recording Actions
    func startRecording(promptID: String) {
        audioManager.startRecording(promptID: promptID)
    }

    func stopRecording(promptID: String) {
        audioManager.stopRecording(promptID: promptID)
        // Validate and upload the last recording
        if let last = audioManager.recordings.last {
            validateAndUpload(recording: last)
        }
    }

    func deleteRecording(_ recording: Recording) {
        audioManager.deleteRecording(recording)
    }

    // MARK: - Session Workflow
    /// Starts a new session by selecting a prompt and presenting the recording UI.
    func startNewSession() {
        // Request microphone permission first
        AudioRecorder.shared.requestMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                // Prompt selection logic to be implemented
                let promptID = "default-prompt"
                self.currentPromptID = promptID
                self.showRecordingModal = true
                self.startRecording(promptID: promptID)
            } else {
                self.errorMessage = "Microphone access is required to record your voice journal. Please enable it in Settings."
            }
        }
    }

    /// Ends the current session, stops recording, and triggers upload.
    func endCurrentSession() {
        guard let promptID = currentPromptID else { return }
        stopRecording(promptID: promptID)
        showRecordingModal = false
        currentPromptID = nil
    }

    // MARK: - Validation & Upload
    /// Validates and uploads a recording, logging errors and updating FEEDBACK_LOG.md as needed.
    /// - References DATA_STANDARDS.md §3.4, DATA_DICTIONARY.md, RESOURCES.md §6.
    func validateAndUpload(recording: Recording) {
        // Pre-upload validation: duration, silence, clipping
        let validation = RecordingValidator.validateFull(recording: recording)
        lastValidationResult = validation
        guard validation.isValid else {
            errorMessage = "Validation failed: \(validation.reasons.joined(separator: ", "))"
            logValidationFailure(recording: recording, reasons: validation.reasons)
            return
        }
        isUploading = true
        uploader.uploadRecording(recording) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                switch result {
                case .success:
                    self?.uploadProgress = 1.0
                    self?.uploadSuccess = true
                case .failure(let error):
                    self?.errorMessage = "Upload failed: \(error.localizedDescription)"
                    self?.logUploadFailure(recording: recording, error: error)
                }
            }
        }
    }

    // MARK: - Logging & Feedback
    /// Logs validation failures using structured logging.
    private func logValidationFailure(recording: Recording, reasons: [String]) {
        Logger.error("Validation failed for recording \(recording.id): \(reasons.joined(separator: ", "))", category: .audio)
    }

    /// Logs upload failures using structured logging.
    private func logUploadFailure(recording: Recording, error: Error) {
        Logger.error("Upload failed for recording \(recording.id): \(error.localizedDescription)", category: .network)
    }
} 