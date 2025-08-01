import Foundation

/// Protocol for audio recording functionality
/// - Provides abstraction for recording operations
/// - Enables mocking and testing of recording logic
/// - Supports different recording implementations
protocol AudioRecorderProtocol {
    /// Starts recording for a specified duration
    /// - Parameters:
    ///   - duration: Recording duration in seconds
    ///   - completion: Called with the completed recording
    func start(duration: TimeInterval, completion: @escaping (Recording) -> Void)
    
    /// Stops the current recording
    func stop()
    
    /// Current recording state
    var isRecording: Bool { get }
} 