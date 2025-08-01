import Foundation

/// Protocol for audio upload service (for testability)
protocol AudioUploaderProtocol {
    func uploadRecording(_ recording: Recording, mode: UploadMode, completion: @escaping (Result<Void, Error>) -> Void)
} 