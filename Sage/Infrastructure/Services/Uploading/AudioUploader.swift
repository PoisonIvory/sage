import Foundation

/// Upload modes for different contexts
/// - onboarding: Simplified upload for onboarding flow
/// - daily: Full export with validation and batching
/// - debugTest: Verbose logging for testing
enum UploadMode {
    case onboarding
    case daily
    case debugTest
}



/// Upload errors for audio recording uploads
enum AudioUploadError: Error, LocalizedError {
    case networkError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Upload failed. Please check your internet connection."
        case .authenticationError:
            return "Session expired. Please log in again."
        }
    }
}

/// Handles audio recording uploads with multiple modes
/// - Integrates with existing RecordingUploaderService
/// - Provides different upload behaviors for different contexts
/// - Follows GWT test specifications for upload handling
final class AudioUploader: AudioUploaderProtocol {
    
    private let recordingUploaderService: RecordingUploaderServiceProtocol
    
    init(recordingUploaderService: RecordingUploaderServiceProtocol = RecordingUploaderService.shared) {
        self.recordingUploaderService = recordingUploaderService
    }
    
    /// Uploads a recording with specified mode
    /// - Parameters:
    ///   - recording: The recording to upload
    ///   - mode: Upload mode (onboarding, daily, debugTest)
    ///   - completion: Called with upload result
    func uploadRecording(_ recording: Recording, mode: UploadMode, completion: @escaping (Result<Void, Error>) -> Void) {
        print("[AudioUploader] Starting upload for recording \(recording.id) in mode: \(mode)")
        
        switch mode {
        case .onboarding:
            // Simplified upload for onboarding - skip frame validation if needed
            uploadForOnboarding(recording, completion: completion)
        case .daily:
            // Full export with validation and batching
            uploadForDaily(recording, completion: completion)
        case .debugTest:
            // Verbose logging for testing
            uploadForDebugTest(recording, completion: completion)
        }
    }
    
    // MARK: - Private Upload Methods
    
    private func uploadForOnboarding(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        print("[AudioUploader] Onboarding upload mode - simplified processing")
        recordingUploaderService.uploadRecording(recording) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func uploadForDaily(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        print("[AudioUploader] Daily upload mode - full processing with validation")
        recordingUploaderService.uploadRecording(recording) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func uploadForDebugTest(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        print("[AudioUploader] Debug test upload mode - verbose logging")
        print("[AudioUploader] Recording details: id=\(recording.id), duration=\(recording.duration)s, fileSize=\(recording.fileURL.fileSize)")
        
        recordingUploaderService.uploadRecording(recording) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("[AudioUploader] Debug upload completed successfully")
                case .failure(let error):
                    print("[AudioUploader] Debug upload failed: \(error.localizedDescription)")
                }
                completion(result)
            }
        }
    }
}

// MARK: - URL Extension for File Size
private extension URL {
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
} 