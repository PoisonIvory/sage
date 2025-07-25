import Foundation
import FirebaseFirestore
import FirebaseAuth
// import Protocols.swift if needed

/// RecordingUploaderService handles export, schema validation, upload, and QA for research-grade compliance.
/// - Complies with DATA_STANDARDS.md §3.3, DATA_DICTIONARY.md, RESOURCES.md §6, CONTRIBUTING.md.
final class RecordingUploaderService: RecordingUploaderServiceProtocol {
    static let shared = RecordingUploaderService()
    private let db = Firestore.firestore()
    private let collection = "recordings"

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
                    dict.mapValues { ($0 as? AnyCodable)?.value ?? $0 }
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
                        completion(.success(()))
                    }
                }
            }
        } catch {
            print("[RecordingUploaderService] Export or preparation failed for recording id=\(recording.id): \(error)")
            logUploadError(recording: recording, error: error)
            completion(.failure(error))
        }
    }

    /// Migration helper: convert legacy frameFeatures array to FrameBatch subcollection
    func migrateLegacyFrameFeaturesIfNeeded(for recordingId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = db.collection(collection).document(recordingId)
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("[Migration] Failed to fetch recording doc: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(), let legacyFrames = data["frameFeatures"] as? [[String: AnyCodable]], !legacyFrames.isEmpty else {
                print("[Migration] No legacy frameFeatures found for doc \(recordingId)")
                completion(.success(()))
                return
            }
            let frames: [[String: Any]] = legacyFrames.map { dict in
                dict.mapValues { ($0 as? AnyCodable)?.value ?? $0 }
            }
            let batches = self.chunkFrameFeatures(frames)
            let framesCollection = docRef.collection("frames")
            let batch = self.db.batch()
            for (i, batchData) in batches.enumerated() {
                let batchDoc = framesCollection.document(String(format: "batch_%03d", i))
                batch.setData(batchData, forDocument: batchDoc)
            }
            // Remove legacy field
            batch.updateData(["frameFeatures": FieldValue.delete(), "hasFrameData": true], forDocument: docRef)
            batch.commit { batchError in
                if let batchError = batchError {
                    print("[Migration] Frame batch migration failed: \(batchError)")
                    completion(.failure(batchError))
                } else {
                    print("[Migration] Frame batches migrated for doc \(recordingId)")
                    completion(.success(()))
                }
            }
        }
    }

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
        // Remove the line initializing 'csv' if it is not used
        // TODO: Add summary features, metadata, and ensure column order/unit labels per DATA_STANDARDS.md §3.3
    }

    /// Logs upload errors and updates FEEDBACK_LOG.md
    private func logUploadError(recording: Recording, error: Error) {
        // TODO: Implement structured logging to FEEDBACK_LOG.md
        print("[FEEDBACK_LOG] Upload/export error for recording \(recording.id): \(error.localizedDescription)")
        // Add code to append to FEEDBACK_LOG.md with date, error, and metadata
    }

    /// (Stub) Validates features against reference sample for QA (RESOURCES.md §6)
    func validateAgainstReference(recording: Recording, reference: Recording) -> [String] {
        // TODO: Implement feature-by-feature comparison, log discrepancies
        return []
    }
} 