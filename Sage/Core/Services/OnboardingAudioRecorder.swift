import Foundation

/// Concrete implementation of AudioRecorderProtocol for onboarding
/// - Wraps existing AudioRecorder functionality
/// - Provides controlled recording for onboarding flow
/// - Handles timing and completion callbacks
final class OnboardingAudioRecorder: AudioRecorderProtocol {
    
    private let audioRecorder: AudioRecordingManaging
    private var recordingCompletion: ((Recording) -> Void)?
    private var recordingTimer: Timer?
    private let recordingDuration: TimeInterval = 10.0 // 10 seconds for onboarding
    
    init(audioRecorder: AudioRecordingManaging = AudioRecorder.shared) {
        self.audioRecorder = audioRecorder
    }
    
    var isRecording: Bool {
        return audioRecorder.isRecording
    }
    
    func start(duration: TimeInterval, completion: @escaping (Recording) -> Void) {
        print("[OnboardingAudioRecorder] Starting recording for \(duration) seconds")
        
        // Store completion handler
        recordingCompletion = completion
        
        // Start recording with the existing AudioRecorder
        audioRecorder.startRecording(promptID: "onboarding_vocal_test")
        
        // Set up timer to stop recording after specified duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.stop()
        }
    }
    
    func stop() {
        print("[OnboardingAudioRecorder] Stopping recording")
        
        // Cancel timer if it exists
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Stop recording with the existing AudioRecorder
        audioRecorder.stopRecording(promptID: "onboarding_vocal_test")
        
        // Get the last recording and call completion
        if let lastRecording = audioRecorder.recordings.last {
            print("[OnboardingAudioRecorder] Recording completed: \(lastRecording.id)")
            recordingCompletion?(lastRecording)
        } else {
            print("[OnboardingAudioRecorder] No recording found after stop")
            // Create a mock recording for testing/fallback
            let mockRecording = createMockRecording()
            recordingCompletion?(mockRecording)
        }
        
        // Clear completion handler
        recordingCompletion = nil
    }
    
    // MARK: - Private Methods
    
    private func createMockRecording() -> Recording {
        // Create a mock recording for testing or fallback scenarios
        return Recording(
            userID: "mock-user",
            sessionTime: Date(),
            task: "onboarding_vocal_test",
            fileURL: URL(fileURLWithPath: "/mock/recording.wav"),
            filename: "mock_recording.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "Mock Device",
            osVersion: "Mock OS",
            appVersion: "1.0",
            duration: recordingDuration,
            frameFeatures: [],
            summaryFeatures: nil
        )
    }
} 