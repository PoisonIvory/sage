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
        // Access isRecording through the AudioRecorder instance, not the protocol
        if let audioRecorder = audioRecorder as? AudioRecorder {
            return audioRecorder.isRecording
        }
        return false
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
            // Handle the case where no recording was created
            Logger.error("No recording found after stop in OnboardingAudioRecorder", category: .audio)
        }
        
        // Clear completion handler
        recordingCompletion = nil
    }
    
    // MARK: - Private Methods
    
    // Mock recording logic removed - production code should not contain mock data
} 