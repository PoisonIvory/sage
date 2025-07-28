import Foundation
import AVFoundation
import Speech
import Combine
import UIKit

// MARK: - Voice Permission Manager

/// Centralized manager for voice recording and speech recognition permissions
/// GWT: Given app needs voice analysis capabilities
/// GWT: When managing microphone and speech recognition permissions
/// GWT: Then provides unified permission state and request handling
@MainActor
public class VoicePermissionManager: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var microphoneStatus: MicrophonePermissionStatus = .notDetermined
    @Published public private(set) var speechRecognitionStatus: SpeechRecognitionPermissionStatus = .notDetermined
    @Published public private(set) var overallStatus: VoicePermissionStatus = .incomplete
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        updatePermissionStates()
        setupStateMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Check current permission status without requesting
    public func checkPermissions() {
        updatePermissionStates()
    }
    
    /// Request all necessary permissions for voice analysis
    /// GWT: Given user wants to enable voice analysis
    /// GWT: When requesting all required permissions
    /// GWT: Then shows permission dialogs and updates state
    public func requestAllPermissions() async -> VoicePermissionResult {
        // Request microphone permission first
        let micResult = await requestMicrophonePermission()
        
        // Only request speech recognition if microphone is granted
        guard micResult.isGranted else {
            updateOverallStatus()
            return VoicePermissionResult(
                microphone: micResult,
                speechRecognition: .init(status: "not_requested", isGranted: false),
                canProceed: false
            )
        }
        
        // Request speech recognition permission
        let speechResult = await requestSpeechRecognitionPermission()
        
        updateOverallStatus()
        
        return VoicePermissionResult(
            microphone: micResult,
            speechRecognition: speechResult,
            canProceed: micResult.isGranted && speechResult.isGranted
        )
    }
    
    /// Request only microphone permission
    public func requestMicrophonePermission() async -> PermissionResult {
        let session = AVAudioSession.sharedInstance()
        
        return await withCheckedContinuation { continuation in
            session.requestRecordPermission { granted in
                Task { @MainActor in
                    let status: MicrophonePermissionStatus = granted ? .authorized : .denied
                    self.microphoneStatus = status
                    
                    let result = PermissionResult(
                        status: status.rawValue,
                        isGranted: granted
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Request only speech recognition permission
    public func requestSpeechRecognitionPermission() async -> PermissionResult {
        // Check if speech recognition is available
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            await MainActor.run {
                self.speechRecognitionStatus = .unavailable
            }
            return PermissionResult(status: "unavailable", isGranted: false)
        }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                Task { @MainActor in
                    let status = SpeechRecognitionPermissionStatus.from(authStatus)
                    self.speechRecognitionStatus = status
                    
                    let result = PermissionResult(
                        status: status.rawValue,
                        isGranted: status == .authorized
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Generate user-friendly status message
    public func getStatusMessage() -> String {
        switch overallStatus {
        case .ready:
            return "✅ Voice analysis ready"
        case .incomplete:
            let missing = getMissingPermissions()
            return "⚠️ Need permissions: \(missing.joined(separator: ", "))"
        case .denied:
            return "❌ Permissions denied - enable in Settings"
        case .restricted:
            return "🔒 Voice features restricted on device"
        case .unavailable:
            return "📱 Voice analysis not available on device"
        }
    }
    
    /// Get specific instructions for user
    public func getInstructions() -> String? {
        let missing = getMissingPermissions()
        guard !missing.isEmpty else { return nil }
        
        var instructions: [String] = []
        
        if microphoneStatus == .denied {
            instructions.append("Enable Microphone in Settings > Privacy & Security > Microphone")
        }
        
        if speechRecognitionStatus == .denied {
            instructions.append("Enable Speech Recognition in Settings > Privacy & Security > Speech Recognition")
        }
        
        return instructions.isEmpty ? nil : instructions.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    private func updatePermissionStates() {
        // Update microphone status
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .undetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .notDetermined
        }
        
        // Update speech recognition status
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        speechRecognitionStatus = SpeechRecognitionPermissionStatus.from(authStatus)
        
        updateOverallStatus()
    }
    
    private func updateOverallStatus() {
        // Check if all permissions are ready
        if microphoneStatus == .authorized && speechRecognitionStatus == .authorized {
            overallStatus = .ready
            return
        }
        
        // Check for restricted/unavailable states
        if microphoneStatus == .restricted || speechRecognitionStatus == .restricted {
            overallStatus = .restricted
            return
        }
        
        if speechRecognitionStatus == .unavailable {
            overallStatus = .unavailable
            return
        }
        
        // Check for denied states
        if microphoneStatus == .denied || speechRecognitionStatus == .denied {
            overallStatus = .denied
            return
        }
        
        // Otherwise incomplete
        overallStatus = .incomplete
    }
    
    private func getMissingPermissions() -> [String] {
        var missing: [String] = []
        
        if microphoneStatus != .authorized {
            missing.append("Microphone")
        }
        
        if speechRecognitionStatus != .authorized {
            missing.append("Speech Recognition")
        }
        
        return missing
    }
    
    private func setupStateMonitoring() {
        // Monitor for when app becomes active to refresh permissions
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updatePermissionStates()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

/// Microphone permission status
public enum MicrophonePermissionStatus: String, CaseIterable {
    case authorized = "authorized"
    case denied = "denied"
    case restricted = "restricted"
    case notDetermined = "not_determined"
    
    // Legacy compatibility
    case unknown = "unknown"
    case granted = "granted"
    
    /// Convert legacy status to new status
    static func fromLegacy(_ legacy: String) -> MicrophonePermissionStatus {
        switch legacy {
        case "granted": return .authorized
        case "unknown": return .notDetermined
        default: return .notDetermined
        }
    }
}

/// Speech recognition permission status
public enum SpeechRecognitionPermissionStatus: String, CaseIterable {
    case authorized = "authorized"
    case denied = "denied"
    case restricted = "restricted"
    case notDetermined = "not_determined"
    case unavailable = "unavailable"
    
    static func from(_ sfStatus: SFSpeechRecognizerAuthorizationStatus) -> Self {
        switch sfStatus {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

/// Overall voice permission status
public enum VoicePermissionStatus: String, CaseIterable {
    case ready = "ready"
    case incomplete = "incomplete"
    case denied = "denied"
    case restricted = "restricted"
    case unavailable = "unavailable"
}

/// Permission request result
public struct PermissionResult {
    public let status: String
    public let isGranted: Bool
    
    public init(status: String, isGranted: Bool) {
        self.status = status
        self.isGranted = isGranted
    }
}

/// Complete voice permission result
public struct VoicePermissionResult {
    public let microphone: PermissionResult
    public let speechRecognition: PermissionResult
    public let canProceed: Bool
    
    public init(microphone: PermissionResult, speechRecognition: PermissionResult, canProceed: Bool) {
        self.microphone = microphone
        self.speechRecognition = speechRecognition
        self.canProceed = canProceed
    }
    
    /// User-friendly summary
    public var summary: String {
        if canProceed {
            return "✅ All permissions granted - voice analysis ready!"
        } else {
            var issues: [String] = []
            if !microphone.isGranted {
                issues.append("Microphone access needed")
            }
            if !speechRecognition.isGranted {
                issues.append("Speech recognition access needed")
            }
            return "⚠️ \(issues.joined(separator: " and "))"
        }
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI view modifier for voice permission handling
public struct VoicePermissionModifier: ViewModifier {
    @StateObject private var permissionManager = VoicePermissionManager()
    @State private var showingPermissionAlert = false
    
    let onPermissionResult: (VoicePermissionResult) -> Void
    
    public func body(content: Content) -> some View {
        content
            .environmentObject(permissionManager)
            .alert("Voice Permissions Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionManager.getInstructions() ?? "Enable voice permissions in Settings")
            }
    }
    
    public func requestPermissions() {
        Task {
            let result = await permissionManager.requestAllPermissions()
            await MainActor.run {
                onPermissionResult(result)
                if !result.canProceed {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

extension View {
    /// Add voice permission handling to a view
    public func voicePermissions(onResult: @escaping (VoicePermissionResult) -> Void) -> some View {
        modifier(VoicePermissionModifier(onPermissionResult: onResult))
    }
}
#endif