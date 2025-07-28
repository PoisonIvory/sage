import Foundation

/// Centralized Firestore field keys for consistent database access
/// - Follows DATA_STANDARDS.md §3.2.1 for naming conventions
/// - Reduces duplication and improves maintainability
enum FirestoreKeys {
    // MARK: - F0 Analysis Keys
    static let f0Mean = "f0_mean"
    static let confidence = "f0_confidence"
    static let status = "status"
    static let errorType = "error_type"
    static let metadata = "processing_metadata"
    static let audioDuration = "audio_duration"
    static let voicedFrames = "voiced_frames"
    static let totalFrames = "total_frames"
    static let insightType = "insight_type"
    static let f0Analysis = "f0_analysis"
    
    // MARK: - Recording Keys
    static let task = "task"
    static let sessionTime = "session_time"
    static let createdAt = "created_at"
    
    // MARK: - User Keys
    static let userID = "userID"
    
    // MARK: - Common Keys
    static let id = "id"
    static let name = "name"
    static let email = "email"
} 