//
//  SageTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Onboarding tests: DATA_STANDARDS.md §2.2, §2.3; DATA_DICTIONARY.md; TEST_PLAN.md

import Testing
@testable import Sage

final class MockOnboardingCoordinator: OnboardingFlowCoordinating {
    var didComplete = false
    var capturedProfile: UserProfile? = nil
    func onboardingDidComplete(userProfile: UserProfile) {
        didComplete = true
        capturedProfile = userProfile
    }
}

struct SageTests {
    @Test func onboardingFlowViewModel_steps_and_validation() async throws {
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator

        // Step 1: Initial state
        #expect(viewModel.step == .loginSignupChoice)
        #expect(viewModel.isAnonymous == true)

        // Step 2: Select signup
        viewModel.selectSignup()
        #expect(viewModel.step == .signupMethod)

        // Step 3: Select anonymous
        viewModel.selectAnonymous()
        #expect(viewModel.step == .userInfoForm)
        #expect(viewModel.isAnonymous == true)

        // Step 4: Enter invalid user info (empty)
        viewModel.userInfo = UserInfo(name: "", age: 0, gender: "")
        viewModel.completeUserInfo()
        #expect(viewModel.errorMessage != nil)
        #expect(mockCoordinator.didComplete == false)

        // Step 5: Enter valid user info
        viewModel.userInfo = UserInfo(name: "Test User", age: 30, gender: "female")
        viewModel.completeUserInfo()
        #expect(viewModel.step == .completed)
        #expect(mockCoordinator.didComplete == true)
        #expect(mockCoordinator.capturedProfile?.age == 30)
        #expect(mockCoordinator.capturedProfile?.gender == "female")
        #expect(mockCoordinator.capturedProfile?.id.count > 0)
    }
}

struct SageAudioPipelineTests {
    @Test func test_min_duration_validation() async throws {
        // Simulate a short recording
        let rec = Recording(
            userID: "U1",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test.wav"),
            filename: "test.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0",
            duration: 1.0, // too short
            frameFeatures: nil,
            summaryFeatures: nil
        )
        let result = RecordingValidator.validateFull(recording: rec)
        #expect(!result.isValid)
        #expect(result.reasons.contains { $0.contains("Duration too short") })
    }

    @Test func test_silence_detection() async throws {
        // Simulate a recording with 50% silence
        let frames: [[String: AnyCodable]] = (0..<100).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(i < 50 ? -70.0 : -10.0),
                "is_clipped": AnyCodable(false)
            ]
        }
        let rec = Recording(
            userID: "U2",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test2.wav"),
            filename: "test2.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0",
            duration: 5.0,
            frameFeatures: frames,
            summaryFeatures: nil
        )
        let result = RecordingValidator.validateFull(recording: rec)
        #expect(!result.isValid)
        #expect(result.reasons.contains { $0.contains("Too much silence") })
    }

    @Test func test_clipping_detection() async throws {
        // Simulate a recording with 2% clipped frames
        let frames: [[String: AnyCodable]] = (0..<100).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(-10.0),
                "is_clipped": AnyCodable(i < 2)
            ]
        }
        let rec = Recording(
            userID: "U3",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test3.wav"),
            filename: "test3.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0",
            duration: 5.0,
            frameFeatures: frames,
            summaryFeatures: nil
        )
        let result = RecordingValidator.validateFull(recording: rec)
        #expect(!result.isValid)
        #expect(result.reasons.contains { $0.contains("Clipping detected") })
    }

    @Test func test_schema_export() async throws {
        // Simulate a valid recording and test export
        let frames: [[String: AnyCodable]] = (0..<10).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(-20.0),
                "is_clipped": AnyCodable(false)
            ]
        }
        let rec = Recording(
            userID: "U4",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test4.wav"),
            filename: "test4.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0",
            duration: 5.0,
            frameFeatures: frames,
            summaryFeatures: nil
        )
        let uploader = RecordingUploaderService()
        try uploader.uploadRecording(rec) { result in
            #expect(result.isSuccess)
        }
    }

    @Test func test_reference_sample_qa_stub() async throws {
        // Simulate reference sample QA (stub)
        let rec = Recording(
            userID: "U5",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test5.wav"),
            filename: "test5.wav",
            fileFormat: "wav",
            sampleRate: 48000,
            bitDepth: 24,
            channelCount: 1,
            deviceModel: "iPhone",
            osVersion: "17.0",
            appVersion: "1.0",
            duration: 5.0,
            frameFeatures: nil,
            summaryFeatures: nil
        )
        let uploader = RecordingUploaderService()
        let discrepancies = uploader.validateAgainstReference(recording: rec, reference: rec)
        #expect(discrepancies.isEmpty)
    }
}
