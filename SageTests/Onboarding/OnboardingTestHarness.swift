//
//  OnboardingTestHarness.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Reusable test harness for onboarding flow tests
//  Provides shared mocks and factory methods for consistent test setup

import XCTest
import Mixpanel
@testable import Sage
import Mocks.MockAuthService // Import the shared mock

// MARK: - Test Constants

enum TestConstants {
    static let testUserId = "test-user-id"
    static let testDeviceModel = "Test Device"
    static let testOSVersion = "Test OS"
    static let testAppVersion = "1.0"
    static let testEmail = "test@example.com"
    static let testPassword = "password123"
    static let testRecordingDuration: TimeInterval = 10.0
    static let testRecordingTask = "onboarding_vocal_test"
    static let testTimestamp: TimeInterval = 1234567890
}

// MARK: - Mock Classes

class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [String] = []
    var trackedProperties: [String: [String: MixpanelType]] = [:]
    var identifiedUsers: [String] = []
    var userProfiles: [String: UserProfile] = [:]
    
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?) {
        trackedEvents.append(name)
        trackedProperties[name] = properties ?? [:]
        print("[MockAnalytics] Tracked event: \(name), properties: \(properties ?? [:])")
    }
    
    func identifyUser(userId: String, userProfile: UserProfile) {
        identifiedUsers.append(userId)
        userProfiles[userId] = userProfile
        print("[MockAnalytics] Identified user: \(userId)")
    }
    
    // Helper methods for testing
    func getProperties(for event: String) -> [String: MixpanelType]? {
        return trackedProperties[event]
    }
    
    func getOrigin(for event: String) -> String? {
        return trackedProperties[event]?["origin"] as? String
    }
    
    func assertEventContainsProperty(_ event: String, key: String, value: MixpanelType) -> Bool {
        guard let properties = trackedProperties[event] else { 
            print("Event '\(event)' not found in tracked events: \(trackedEvents)")
            return false 
        }
        let actualValue = properties[key]
        if !areMixpanelTypesEqual(actualValue, value) {
            print("Mismatch: expected \(value), got \(String(describing: actualValue)) for key \(key) in event \(event)")
            return false
        }
        return true
    }
    
    private func areMixpanelTypesEqual(_ lhs: MixpanelType?, _ rhs: MixpanelType?) -> Bool {
        // Handle MixpanelType comparison safely
        if let lhs = lhs, let rhs = rhs {
            return String(describing: lhs) == String(describing: rhs)
        }
        return lhs == nil && rhs == nil
    }
    
    func assertEventContainsUserID(_ event: String, expectedUserID: String) -> Bool {
        return assertEventContainsProperty(event, key: "userID", value: expectedUserID)
    }
    
    func assertEventContainsMethod(_ event: String, expectedMethod: String) -> Bool {
        return assertEventContainsProperty(event, key: "method", value: expectedMethod)
    }
    
    func assertEventContainsMode(_ event: String, expectedMode: String) -> Bool {
        return assertEventContainsProperty(event, key: "mode", value: expectedMode)
    }
    
    func assertEventContainsSuccess(_ event: String, expectedSuccess: Bool) -> Bool {
        return assertEventContainsProperty(event, key: "success", value: expectedSuccess)
    }
    
    func assertEventContainsDuration(_ event: String, expectedDuration: TimeInterval) -> Bool {
        return assertEventContainsProperty(event, key: "duration", value: expectedDuration)
    }
    
    func reset() {
        trackedEvents.removeAll()
        trackedProperties.removeAll()
        identifiedUsers.removeAll()
        userProfiles.removeAll()
    }
}

class MockUserProfileRepository: UserProfileRepositoryProtocol {
    var didFetchProfile = false
    var shouldReturnProfile = false
    var mockProfile: UserProfile?
    var fetchUserProfileHandler: ((String) -> UserProfile?)?
    
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        didFetchProfile = true
        let result = fetchUserProfileHandler?(id) ?? (shouldReturnProfile ? mockProfile : nil)
        completion(result)
    }
    
    func reset() {
        didFetchProfile = false
        shouldReturnProfile = false
        mockProfile = nil
        fetchUserProfileHandler = nil
    }
}

class MockMicrophonePermissionManager: MicrophonePermissionManagerProtocol {
    var permissionGranted = true
    var didCheckPermission = false
    var checkPermissionHandler: ((@escaping (Bool) -> Void) -> Void)?
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        didCheckPermission = true
        if let handler = checkPermissionHandler {
            handler(completion)
        } else {
            completion(permissionGranted)
        }
    }
    
    func reset() {
        permissionGranted = true
        didCheckPermission = false
        checkPermissionHandler = nil
    }
}

class MockAudioRecorder: AudioRecorderProtocol {
    var isRecording: Bool = false
    var didStartRecording = false
    var didStopRecording = false
    var lastRecordingDuration: TimeInterval = 0
    private var completionHandler: ((Recording) -> Void)?
    
    func start(duration: TimeInterval, completion: @escaping (Recording) -> Void) {
        didStartRecording = true
        lastRecordingDuration = duration
        isRecording = true
        completionHandler = completion
    }
    
    func stop() {
        didStopRecording = true
        isRecording = false
    }
    
    func simulateRecordingCompletion(_ recording: Recording) {
        completionHandler?(recording)
    }
    
    func reset() {
        isRecording = false
        didStartRecording = false
        didStopRecording = false
        lastRecordingDuration = 0
        completionHandler = nil
    }
}

class MockAudioUploader: AudioUploaderProtocol {
    var didUploadRecording = false
    var shouldSucceed = true
    var errorType: UploadError = .networkError
    var lastUploadMode: UploadMode?
    var uploadHandler: ((Recording, UploadMode, @escaping (Result<Void, Error>) -> Void) -> Void)?
    
    func uploadRecording(_ recording: Recording, mode: UploadMode, completion: @escaping (Result<Void, Error>) -> Void) {
        didUploadRecording = true
        lastUploadMode = mode
        
        if let handler = uploadHandler {
            handler(recording, mode, completion)
        } else if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(errorType))
        }
    }
    
    func reset() {
        didUploadRecording = false
        shouldSucceed = true
        errorType = .networkError
        lastUploadMode = nil
        uploadHandler = nil
    }
}

class MockOnboardingCoordinator: OnboardingCoordinatorProtocol {
    var didCompleteOnboarding = false
    var didTransitionToLogin = false
    var didComplete = false
    var capturedProfile: UserProfile?
    
    func onboardingDidComplete(userProfile: UserProfile) {
        didCompleteOnboarding = true
        didComplete = true
        capturedProfile = userProfile
    }
    
    func transitionToLogin() {
        didTransitionToLogin = true
    }
    
    func reset() {
        didCompleteOnboarding = false
        didTransitionToLogin = false
        didComplete = false
        capturedProfile = nil
    }
}

class MockDateProvider: DateProvider {
    let currentDate: Date
    
    init(currentDate: Date) {
        self.currentDate = currentDate
    }
}

// MARK: - Onboarding Mocks

struct OnboardingMocks {
    let analytics = MockAnalyticsService()
    let auth = MockAuthService()
    let userProfileRepository = MockUserProfileRepository()
    let microphonePermissionManager = MockMicrophonePermissionManager()
    let audioRecorder = MockAudioRecorder()
    let audioUploader = MockAudioUploader()
    let coordinator = MockOnboardingCoordinator()
    let dateProvider = MockDateProvider(currentDate: Date(timeIntervalSince1970: TestConstants.testTimestamp))
}

// MARK: - Onboarding Test Harness

@MainActor
class OnboardingTestHarness {
    
    // MARK: - Shared Mocks
    let mocks = OnboardingMocks()
    
    var mockAnalyticsService: MockAnalyticsService { mocks.analytics }
    var mockAuthService: MockAuthService { mocks.auth }
    var mockMicrophonePermissionManager: MockMicrophonePermissionManager { mocks.microphonePermissionManager }
    var mockAudioRecorder: MockAudioRecorder { mocks.audioRecorder }
    var mockAudioUploader: MockAudioUploader { mocks.audioUploader }
    var mockCoordinator: MockOnboardingCoordinator { mocks.coordinator }
    var mockUserProfileRepository: MockUserProfileRepository { mocks.userProfileRepository }
    var mockDateProvider: MockDateProvider { mocks.dateProvider }
    
    // MARK: - Factory Methods
    
    func makeViewModel() -> OnboardingJourneyViewModel {
        return OnboardingJourneyViewModel(
            analyticsService: mockAnalyticsService,
            authService: mockAuthService,
            userProfileRepository: mockUserProfileRepository,
            microphonePermissionManager: mockMicrophonePermissionManager,
            audioRecorder: mockAudioRecorder,
            audioUploader: mockAudioUploader,
            coordinator: mockCoordinator,
            dateProvider: mockDateProvider
        )
    }
    
    func makeViewModelWithCustomDateProvider(_ dateProvider: DateProvider) -> OnboardingJourneyViewModel {
        return OnboardingJourneyViewModel(
            analyticsService: mockAnalyticsService,
            authService: mockAuthService,
            userProfileRepository: mockUserProfileRepository,
            microphonePermissionManager: mockMicrophonePermissionManager,
            audioRecorder: mockAudioRecorder,
            audioUploader: mockAudioUploader,
            coordinator: mockCoordinator,
            dateProvider: dateProvider
        )
    }
    
    // MARK: - Setup Helpers
    
    func setupForAnonymousSignup() -> OnboardingJourneyViewModel {
        let viewModel = makeViewModel()
        viewModel.currentStep = .signupMethod
        return viewModel
    }
    
    func setupForEmailSignup() -> OnboardingJourneyViewModel {
        let viewModel = makeViewModel()
        viewModel.currentStep = .signupMethod
        viewModel.email = TestConstants.testEmail
        viewModel.password = TestConstants.testPassword
        return viewModel
    }
    
    func setupForVocalTest() -> OnboardingJourneyViewModel {
        let viewModel = makeViewModel()
        viewModel.currentStep = .vocalTest
        mockMicrophonePermissionManager.permissionGranted = true
        viewModel.microphonePermissionStatus = .granted
        return viewModel
    }
    
    func setupForRecordingInProgress() -> OnboardingJourneyViewModel {
        let viewModel = setupForVocalTest()
        viewModel.isRecording = true
        viewModel.recordingState = .recording()
        return viewModel
    }
    
    // MARK: - Reset Methods
    
    func resetAllMocks() {
        mockAnalyticsService.reset()
        mockAuthService.reset()
        mockMicrophonePermissionManager.reset()
        mockAudioRecorder.reset()
        mockAudioUploader.reset()
        mockCoordinator.reset()
        mockUserProfileRepository.reset()
    }
    
    func resetAnalytics() {
        mockAnalyticsService.reset()
    }
    
    func resetAudioMocks() {
        mockAudioRecorder.reset()
        mockAudioUploader.reset()
        mockMicrophonePermissionManager.reset()
    }
}

// MARK: - Test Data Factory

struct OnboardingTestDataFactory {
    
    // MARK: - User Profile Data
    
    static func createValidUserProfileData(
        age: Int = 25,
        gender: String = "female"
    ) -> UserProfileData {
        return UserProfileData(
            age: age,
            gender: gender
        )
    }
    
    static func createInvalidUserProfileData(
        age: Int = 0,
        gender: String = ""
    ) -> UserProfileData {
        return UserProfileData(
            age: age,
            gender: gender
        )
    }
    
    static func createMinimalUserProfile(
        userId: String = TestConstants.testUserId,
        deviceModel: String = TestConstants.testDeviceModel,
        osVersion: String = TestConstants.testOSVersion,
        dateProvider: DateProvider = MockDateProvider(currentDate: Date(timeIntervalSince1970: TestConstants.testTimestamp))
    ) -> UserProfile {
        return UserProfileValidator.createMinimalProfile(
            userId: userId,
            deviceModel: deviceModel,
            osVersion: osVersion,
            dateProvider: dateProvider
        )
    }
    
    static func createCompleteUserProfile(
        age: Int = 25,
        gender: String = "female",
        userId: String = TestConstants.testUserId,
        deviceModel: String = TestConstants.testDeviceModel,
        osVersion: String = TestConstants.testOSVersion,
        dateProvider: DateProvider = MockDateProvider(currentDate: Date(timeIntervalSince1970: TestConstants.testTimestamp))
    ) -> UserProfile {
        let data = createValidUserProfileData(age: age, gender: gender)
        do {
            return try UserProfileValidator.createCompleteProfile(
                from: data,
                userId: userId,
                deviceModel: deviceModel,
                osVersion: osVersion,
                dateProvider: dateProvider
            )
        } catch {
            fatalError("Failed to create complete user profile: \(error)")
        }
    }
    
    // MARK: - Recording Data
    
    static func createMockRecording(
        userID: String = TestConstants.testUserId,
        duration: TimeInterval = TestConstants.testRecordingDuration,
        task: String = TestConstants.testRecordingTask
    ) -> Recording {
        return Recording(
            userID: userID,
            sessionTime: Date(),
            task: task,
            fileURL: URL(fileURLWithPath: "/test/recording.wav"),
            filename: "test_recording.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: TestConstants.testDeviceModel,
            osVersion: TestConstants.testOSVersion,
            appVersion: TestConstants.testAppVersion,
            duration: duration,
            frameFeatures: [],
            summaryFeatures: nil
        )
    }
    
    static func createMockRecordingWithTrimming(
        userID: String = TestConstants.testUserId,
        duration: TimeInterval = TestConstants.testRecordingDuration,
        task: String = TestConstants.testRecordingTask,
        wasTrimmed: Bool = true
    ) -> Recording {
        let recording = createMockRecording(userID: userID, duration: duration, task: task)
        // Note: If Recording model exposes trimming flags, set them here
        // recording.wasTrimmed = wasTrimmed
        return recording
    }
    
    // MARK: - Error Responses
    
    static func createNetworkError() -> UploadError {
        return .networkError
    }
    
    static func createAuthError() -> UploadError {
        return .authenticationError
    }
    
    static func createGenericError() -> Error {
        return NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Generic upload error"])
    }
    
    static func createValidationError(fieldName: String = "age") -> ValidationError {
        return .ageRequired(fieldName: fieldName)
    }
    
    static func createSignupError(type: SignupErrorType = .networkRequestFailed) -> SignupErrorType {
        return type
    }
    
    // MARK: - Date Providers
    
    static func createMockDateProvider(date: Date = Date(timeIntervalSince1970: TestConstants.testTimestamp)) -> MockDateProvider {
        return MockDateProvider(currentDate: date)
    }
    
    // MARK: - Analytics Event Properties
    
    static func createExpectedAnalyticsProperties(
        userID: String = TestConstants.testUserId,
        method: String = "anonymous",
        duration: TimeInterval = TestConstants.testRecordingDuration,
        mode: String = "onboarding",
        success: Bool = true
    ) -> [String: MixpanelType] {
        return [
            "userID": userID,
            "method": method,
            "duration": duration,
            "mode": mode,
            "success": success
        ]
    }
} 