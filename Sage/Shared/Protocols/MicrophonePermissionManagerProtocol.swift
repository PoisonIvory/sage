import Foundation

/// Protocol for microphone permission management (for testability)
protocol MicrophonePermissionManagerProtocol {
    func checkPermission(completion: @escaping (Bool) -> Void)
} 