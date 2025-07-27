import Foundation
import AVFoundation

/// Protocol for microphone permission management (for testability)
protocol MicrophonePermissionManagerProtocol {
    func checkPermission(completion: @escaping (Bool) -> Void)
}

/// Manages microphone permission requests and status
/// - Handles permission checking and requesting
/// - Provides clean interface for onboarding flow
/// - Follows GWT test specifications for permission handling
final class MicrophonePermissionManager: MicrophonePermissionManagerProtocol {
    
    /// Checks current microphone permission status
    /// - Parameter completion: Called with permission status (true = granted, false = denied)
    func checkPermission(completion: @escaping (Bool) -> Void) {
        print("[MicrophonePermissionManager] Checking microphone permission")
        
        let handler: (Bool) -> Void = { granted in
            DispatchQueue.main.async {
                print("[MicrophonePermissionManager] Permission granted=\(granted)")
                completion(granted)
            }
        }
        
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: handler)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(handler)
        }
    }
} 