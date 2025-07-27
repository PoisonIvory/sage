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

// MARK: - Mock Classes

class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [String] = []
    var trackedProperties: [String: [String: MixpanelType]] = [:]
    var trackedOrigins: [String: String] = [:]
    
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?) {
        trackedEvents.append(name)
        if let properties = properties {
            trackedProperties[name] = properties
        }
        if let origin = origin {
            trackedOrigins[name] = origin
        }
    }
    
    // Helper methods for testing
    func getProperties(for event: String) -> [String: MixpanelType]? {
        return trackedProperties[event]
    }
    
    func getOrigin(for event: String) -> String? {
        return trackedOrigins[event]
    }
    
    func assertEventContainsProperty(_ event: String, key: String, value: MixpanelType) -> Bool {
        guard let properties = trackedProperties[event] else { return false }
        return properties[key] == value
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
        trackedOrigins.removeAll()
    }
}

class MockAuthService: AuthServiceProtocol {
    var currentUserId: String? = "test-user-id"
    var shouldReturnError = false
    var errorType: SignupErrorType = .networkRequestFailed
    
    func reset() {
        currentUserId = "test-user-id"
        shouldReturnError = false
        errorType = .networkRequestFailed
    }
}

class MockUserProfileRepository: UserProfileRepositoryProtocol {
    var didFetchProfile = false
    var shouldReturnProfile = false
    var mockProfile: UserProfile?
    
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        didFetchProfile = true
        if shouldReturnProfile {
            completion(mockProfile)
        } else {
            completion(nil)
        }
    }
    
    func reset() {
        didFetchProfile = false
        shouldReturnProfile = false
        mockProfile = nil
    }
}

class MockMicrophonePermissionManager: MicrophonePermissionManagerProtocol {
    var permissionGranted = true
    var didCheckPermission = false
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        didCheckPermission = true
        completion(permissionGranted)
    }
    
    func reset() {
        permissionGranted = true
        didCheckPermission = false
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
    
    func uploadRecording(_ recording: Recording, mode: UploadMode, completion: @escaping (Result<Void, Error>) -> Void) {
        didUploadRecording = true
        lastUploadMode = mode
        
        if shouldSucceed {
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
    }
}

class MockOnboardingCoordinator: OnboardingFlowCoordinating {
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
    
    func now() -> Date {
        return currentDate
    }
}

// MARK: - Onboarding Test Harness

class OnboardingTestHarness {
    
    // MARK: - Shared Mocks
    let mockAnalyticsService = MockAnalyticsService()
    let mockAuthService = MockAuthService()
    let mockMicrophonePermissionManager = MockMicrophonePermissionManager()
    let mockAudioRecorder = MockAudioRecorder()
    let mockAudioUploader = MockAudioUploader()
    let mockCoordinator = MockOnboardingCoordinator()
    let mockUserProfileRepository = MockUserProfileRepository()
    let mockDateProvider = MockDateProvider(currentDate: Date(timeIntervalSince1970: 1234567890))
    
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
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
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
    
    static func createCompleteUserProfile(
        age: Int = 25,
        gender: String = "female",
        userId: String = "test-user-id",
        deviceModel: String = "Test Device",
        osVersion: String = "Test OS",
        dateProvider: DateProvider = MockDateProvider(currentDate: Date(timeIntervalSince1970: 1234567890))
    ) -> UserProfile {
        let data = createValidUserProfileData(age: age, gender: gender)
        return try! UserProfileValidator.createCompleteProfile(
            from: data,
            userId: userId,
            deviceModel: deviceModel,
            osVersion: osVersion,
            dateProvider: dateProvider
        )
    }
    
    // MARK: - Recording Data
    
    static func createMockRecording(
        userID: String = "test-user",
        duration: TimeInterval = 10.0,
        task: String = "onboarding_vocal_test"
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
            deviceModel: "Test Device",
            osVersion: "Test OS",
            appVersion: "1.0",
            duration: duration,
            frameFeatures: [],
            summaryFeatures: nil
        )
    }
    
    static func createMockRecordingWithTrimming(
        userID: String = "test-user",
        duration: TimeInterval = 10.0,
        task: String = "onboarding_vocal_test",
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
    
    static func createMockDateProvider(date: Date = Date(timeIntervalSince1970: 1234567890)) -> MockDateProvider {
        return MockDateProvider(currentDate: date)
    }
    
    // MARK: - Analytics Event Properties
    
    static func createExpectedAnalyticsProperties(
        userID: String = "test-user-id",
        method: String = "anonymous",
        duration: TimeInterval = 10.0,
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