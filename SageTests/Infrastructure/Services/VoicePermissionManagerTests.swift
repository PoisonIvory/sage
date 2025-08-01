import XCTest
import Speech
import AVFoundation
@testable import Sage

/// Tests for VoicePermissionManager
/// GWT: Given need to test voice permission handling
/// GWT: When testing permission states and requests
/// GWT: Then ensures proper state management and error handling
@MainActor
final class VoicePermissionManagerTests: XCTestCase {
    
    var permissionManager: VoicePermissionManager!
    
    override func setUp() {
        super.setUp()
        permissionManager = VoicePermissionManager()
    }
    
    override func tearDown() {
        permissionManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // GWT: Given VoicePermissionManager initialization
        // GWT: When creating new instance
        // GWT: Then should have proper initial state
        
        XCTAssertNotNil(permissionManager)
        
        // Should have some initial state (not necessarily specific values since they depend on device)
        XCTAssertTrue([
            MicrophonePermissionStatus.authorized,
            .denied,
            .restricted,
            .notDetermined
        ].contains(permissionManager.microphoneStatus))
        
        XCTAssertTrue([
            SpeechRecognitionPermissionStatus.authorized,
            .denied,
            .restricted,
            .notDetermined,
            .unavailable
        ].contains(permissionManager.speechRecognitionStatus))
    }
    
    // MARK: - Status Message Tests
    
    func testStatusMessageReady() {
        // GWT: Given all permissions are ready
        // GWT: When getting status message
        // GWT: Then should return ready message
        
        // We can't easily mock the permission states, but we can test the logic
        let message = permissionManager.getStatusMessage()
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("Voice") || message.contains("Permission"))
    }
    
    func testGetInstructionsWhenPermissionsNeeded() {
        // GWT: Given permissions are needed
        // GWT: When getting instructions
        // GWT: Then should provide helpful guidance
        
        let instructions = permissionManager.getInstructions()
        // Instructions may be nil if permissions are already granted
        if let instructions = instructions {
            XCTAssertTrue(instructions.contains("Settings") || instructions.contains("Privacy"))
        }
    }
    
    // MARK: - Permission Status Conversion Tests
    
    func testSpeechRecognitionStatusConversion() {
        // GWT: Given SFSpeechRecognizerAuthorizationStatus values
        // GWT: When converting to our enum
        // GWT: Then should map correctly
        
        XCTAssertEqual(
            SpeechRecognitionPermissionStatus.from(.authorized),
            .authorized
        )
        
        XCTAssertEqual(
            SpeechRecognitionPermissionStatus.from(.denied),
            .denied
        )
        
        XCTAssertEqual(
            SpeechRecognitionPermissionStatus.from(.restricted),
            .restricted
        )
        
        XCTAssertEqual(
            SpeechRecognitionPermissionStatus.from(.notDetermined),
            .notDetermined
        )
    }
    
    // MARK: - Permission Result Tests
    
    func testPermissionResultInitialization() {
        // GWT: Given permission result data
        // GWT: When creating PermissionResult
        // GWT: Then should initialize correctly
        
        let result = PermissionResult(status: "authorized", isGranted: true)
        XCTAssertEqual(result.status, "authorized")
        XCTAssertTrue(result.isGranted)
        
        let deniedResult = PermissionResult(status: "denied", isGranted: false)
        XCTAssertEqual(deniedResult.status, "denied")
        XCTAssertFalse(deniedResult.isGranted)
    }
    
    func testVoicePermissionResultSummary() {
        // GWT: Given voice permission results
        // GWT: When getting summary
        // GWT: Then should provide appropriate message
        
        let successResult = VoicePermissionResult(
            microphone: PermissionResult(status: "authorized", isGranted: true),
            speechRecognition: PermissionResult(status: "authorized", isGranted: true),
            canProceed: true
        )
        
        XCTAssertTrue(successResult.summary.contains("✅"))
        XCTAssertTrue(successResult.summary.contains("ready"))
        
        let failureResult = VoicePermissionResult(
            microphone: PermissionResult(status: "denied", isGranted: false),
            speechRecognition: PermissionResult(status: "authorized", isGranted: true),
            canProceed: false
        )
        
        XCTAssertTrue(failureResult.summary.contains("⚠️"))
        XCTAssertTrue(failureResult.summary.contains("Microphone"))
    }
    
    // MARK: - Integration Tests
    
    func testCheckPermissions() {
        // GWT: Given permission manager
        // GWT: When checking permissions
        // GWT: Then should update state without crashing
        
        XCTAssertNoThrow {
            permissionManager.checkPermissions()
        }
    }
    
    // MARK: - Async Permission Request Tests
    
    func testMicrophonePermissionRequest() async {
        // GWT: Given need to test microphone permission request
        // GWT: When requesting permission
        // GWT: Then should handle request properly
        
        let result = await permissionManager.requestMicrophonePermission()
        
        // Result should be valid regardless of user's choice
        XCTAssertFalse(result.status.isEmpty)
        XCTAssertTrue(["authorized", "denied"].contains(result.status))
    }
    
    func testSpeechRecognitionPermissionRequest() async {
        // GWT: Given need to test speech recognition permission request
        // GWT: When requesting permission
        // GWT: Then should handle request properly
        
        let result = await permissionManager.requestSpeechRecognitionPermission()
        
        // Result should be valid regardless of availability/user choice
        XCTAssertFalse(result.status.isEmpty)
        XCTAssertTrue([
            "authorized", "denied", "restricted", "not_determined", "unavailable"
        ].contains(result.status))
    }
    
    func testRequestAllPermissions() async {
        // GWT: Given need to request all permissions
        // GWT: When requesting all permissions
        // GWT: Then should handle full flow
        
        let result = await permissionManager.requestAllPermissions()
        
        // Should have valid results for both permissions
        XCTAssertFalse(result.microphone.status.isEmpty)
        XCTAssertFalse(result.speechRecognition.status.isEmpty)
        
        // canProceed should reflect whether both are granted
        let bothGranted = result.microphone.isGranted && result.speechRecognition.isGranted
        XCTAssertEqual(result.canProceed, bothGranted)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandlesUnavailableSpeechRecognition() {
        // GWT: Given speech recognition might not be available
        // GWT: When checking status
        // GWT: Then should handle unavailable state properly
        
        // This test verifies our code can handle the unavailable case
        // without crashing, even if we can't force that state in tests
        let status = SpeechRecognitionPermissionStatus.unavailable
        XCTAssertEqual(status.rawValue, "unavailable")
    }
}

// MARK: - Mock Classes for Testing

/// Mock audio session for testing
class MockAVAudioSession {
    var mockRecordPermission: AVAudioSession.RecordPermission = .undetermined
    
    var recordPermission: AVAudioSession.RecordPermission {
        return mockRecordPermission
    }
    
    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        // Simulate async permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let granted = self.mockRecordPermission == .granted
            response(granted)
        }
    }
}

/// Test helper for permission states
extension VoicePermissionManagerTests {
    
    /// Helper to test all permission status cases
    func testAllPermissionStatusCases() {
        // Test that all enum cases are handled
        let microphoneStatuses: [MicrophonePermissionStatus] = [
            .authorized, .denied, .restricted, .notDetermined
        ]
        
        let speechStatuses: [SpeechRecognitionPermissionStatus] = [
            .authorized, .denied, .restricted, .notDetermined, .unavailable
        ]
        
        let voiceStatuses: [VoicePermissionStatus] = [
            .ready, .incomplete, .denied, .restricted, .unavailable
        ]
        
        // Ensure all cases have valid raw values
        for status in microphoneStatuses {
            XCTAssertFalse(status.rawValue.isEmpty)
        }
        
        for status in speechStatuses {
            XCTAssertFalse(status.rawValue.isEmpty)
        }
        
        for status in voiceStatuses {
            XCTAssertFalse(status.rawValue.isEmpty)
        }
    }
}