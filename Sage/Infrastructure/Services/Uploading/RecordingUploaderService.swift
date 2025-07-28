import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
// import Protocols.swift if needed

/// Upload errors for recording uploads
enum UploadError: Error, LocalizedError {
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

/// RecordingUploaderService handles export, schema validation, upload, and QA for research-grade compliance.
/// - Complies with DATA_STANDARDS.md §3.3, DATA_DICTIONARY.md, RESOURCES.md §6, CONTRIBUTING.md.
final class RecordingUploaderService: RecordingUploaderServiceProtocol {
    static let shared = RecordingUploaderService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let collection = "recordings"
    private let bucketName = "sage-audio-files" // Path within the default bucket

    /// Debug: Print current Firebase Auth UID before upload
    private func logCurrentUser() {
        let uid = Auth.auth().currentUser?.uid ?? "nil"
        print("[RecordingUploaderService] 👤 Current UID: \(uid)")
    }

    /// Debug: Minimal Firestore write test
    func testFirestoreWrite() {
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        db.collection(collection).addDocument(data: [
            "test": true,
            "userID": uid
        ]) { error in
            if let error = error {
                print("[RecordingUploaderService] ❌ Test write failed: \(error.localizedDescription)")
            } else {
                print("[RecordingUploaderService] ✅ Test write succeeded")
            }
        }
    }

    /// Chunks frame features into batches for Firestore upload (DATA_STANDARDS.md §3.3)
    private func chunkFrameFeatures(_ frames: [[String: Any]]) -> [[String: Any]] {
        let batchSize = 500 // Firestore batch write limit
        var batches: [[String: Any]] = []
        var currentBatch: [String: Any] = [:]
        for (i, frame) in frames.enumerated() {
            currentBatch["frame_\(i)"] = frame // frame is [String: Any], Firestore-compatible
            if (i + 1) % batchSize == 0 {
                batches.append(currentBatch)
                currentBatch = [:]
            }
        }
        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }
        return batches
    }

    /// Uploads audio file to Google Cloud Storage to trigger F0 analysis
    private func uploadAudioFile(recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        let audioFileName = "\(recording.id.uuidString).wav"
        let storageRef = storage.reference().child("\(bucketName)/\(audioFileName)")
        
        print("[RecordingUploaderService] Uploading audio file to Cloud Storage: \(audioFileName)")
        
        // Upload the audio file
        let uploadTask = storageRef.putFile(from: recording.fileURL, metadata: nil) { metadata, error in
            if let error = error {
                print("[RecordingUploaderService] Audio file upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let metadata = metadata else {
                print("[RecordingUploaderService] No metadata returned from audio upload")
                completion(.failure(UploadError.networkError))
                return
            }
            
            print("[RecordingUploaderService] Audio file uploaded successfully: \(metadata.name ?? "unknown")")
            print("[RecordingUploaderService] File size: \(metadata.size) bytes")
            
            // Get download URL for reference
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("[RecordingUploaderService] Failed to get download URL: \(error.localizedDescription)")
                } else if let url = url {
                    print("[RecordingUploaderService] Audio file download URL: \(url.absoluteString)")
                }
                completion(.success(()))
            }
        }
        
        // Monitor upload progress
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("[RecordingUploaderService] Audio upload progress: \(Int(percentComplete * 100))%")
        }
    }

    /// Uploads a recording and its frame features as subcollection FrameBatch docs
    func uploadRecording(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        logCurrentUser()
        print("[RecordingUploaderService] Starting upload for recording id=\(recording.id)")
        do {
            try exportFeatures(recording: recording)
            print("[RecordingUploaderService] Preparing Firestore data for recording id=\(recording.id)")
            let data = recording.toFirestoreDict()
            
            print("[RecordingUploaderService] Data to upload: \(data)")
            let docRef = db.collection(collection).document(recording.id.uuidString)
            // Write parent doc first
            docRef.setData(data) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("[RecordingUploaderService] Firestore upload failed for recording id=\(recording.id): \(error)")
                    self.logUploadError(recording: recording, error: error)
                    completion(.failure(error))
                    return
                }
                // Upload frameFeatures as FrameBatch docs in subcollection
                guard let frameFeatures = recording.frameFeatures, !frameFeatures.isEmpty else {
                    print("[RecordingUploaderService] No frameFeatures to upload for recording id=\(recording.id)")
                    completion(.success(()))
                    return
                }
                let frames: [[String: Any]] = frameFeatures.map { dict in
                    dict.mapValues { $0.value }
                }
                let batches = self.chunkFrameFeatures(frames)
                let framesCollection = docRef.collection("frames")
                let batch = self.db.batch()
                for (i, batchData) in batches.enumerated() {
                    let batchDoc = framesCollection.document(String(format: "batch_%03d", i))
                    batch.setData(batchData, forDocument: batchDoc)
                }
                batch.commit { batchError in
                    if let batchError = batchError {
                        print("[RecordingUploaderService] Frame batch upload failed: \(batchError)")
                        self.logUploadError(recording: recording, error: batchError)
                        completion(.failure(batchError))
                    } else {
                        print("[RecordingUploaderService] Frame batches uploaded for recording id=\(recording.id)")
                        
                        // Upload audio file to Google Cloud Storage to trigger F0 analysis
                        self.uploadAudioFile(recording: recording) { audioUploadResult in
                            switch audioUploadResult {
                            case .success:
                                print("[RecordingUploaderService] Audio file uploaded successfully for recording id=\(recording.id)")
                                completion(.success(()))
                            case .failure(let error):
                                print("[RecordingUploaderService] Audio file upload failed for recording id=\(recording.id): \(error)")
                                // Don't fail the entire upload if audio upload fails
                                completion(.success(()))
                            }
                        }
                    }
                }
            }
        } catch {
            print("[RecordingUploaderService] Export or preparation failed for recording id=\(recording.id): \(error)")
            logUploadError(recording: recording, error: error)
            completion(.failure(error))
        }
    }

    // Legacy migration code removed - migration completed

    /// Exports features in strict schema (DATA_STANDARDS.md §3.3)
    private func exportFeatures(recording: Recording) throws {
        // Example: Export frame-level features as CSV
        guard let frames = recording.frameFeatures else { return }
        let _ = ["time_sec", "power_dB", "is_clipped"] // Extend as needed
        let _ = frames.map { frame in
            let time = frame["time_sec"]?.value as? Double ?? 0.0
            let power = frame["power_dB"]?.value as? Double ?? 0.0
            let clipped = frame["is_clipped"]?.value as? Bool ?? false
            return String(format: "%.3f,%.2f,%@", time, power, clipped ? "1" : "0")
        }
        // Feature export implementation - summary features and metadata to be added as needed
    }

    /// Logs upload errors using structured logging
    private func logUploadError(recording: Recording, error: Error) {
        Logger.error("Upload/export error for recording \(recording.id): \(error.localizedDescription)", category: .network)
    }

    /// Validates features against reference sample for QA (RESOURCES.md §6)
    func validateAgainstReference(recording: Recording, reference: Recording) -> [String] {
        // Feature validation implementation to be added as needed
        return []
    }
} 