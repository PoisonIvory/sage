import Foundation

/// Protocol for audio recording and session management (for testability and MVVM compliance)
/// - See DATA_STANDARDS.md, CONTRIBUTING.md
/// - ObservableObject conformance removed to avoid publisher type mismatch (see DATA_STANDARDS.md §2.2.1)
protocol AudioRecordingManaging: AnyObject {
    var recordings: [Recording] { get }
    func startRecording(promptID: String)
    func stopRecording(promptID: String)
    func deleteRecording(_ recording: Recording)
}

/// Protocol for upload service (for testability and dependency injection)
/// - See DATA_STANDARDS.md, CONTRIBUTING.md
protocol RecordingUploaderServiceProtocol: AnyObject {
    func uploadRecording(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void)
} 