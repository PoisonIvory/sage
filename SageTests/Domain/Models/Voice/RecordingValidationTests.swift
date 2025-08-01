//
//  RecordingValidationTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for recording validation using TDD principles
//  Tests audio quality validation and data integrity

import XCTest
@testable import Sage

@MainActor
class RecordingValidationTests: XCTestCase {
    func testRejectRecording_withShortDuration() async throws {
        // Given: Recording with duration too short
        let recording = Recording(
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
        // When: Recording is validated
        let result = RecordingValidator.validateFull(recording: recording)
        // Then: Should be invalid due to short duration
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reasons.contains { $0.contains("Duration too short") })
    }
    
    func testRejectRecording_withTooMuchSilence() async throws {
        // Given: Recording with 50% silence
        let frames: [[String: AnyCodable]] = (0..<100).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(i < 50 ? -70.0 : -10.0),
                "is_clipped": AnyCodable(false)
            ]
        }
        let recording = Recording(
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
        // When: Recording is validated
        let result = RecordingValidator.validateFull(recording: recording)
        // Then: Should be invalid due to too much silence
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reasons.contains { $0.contains("Too much silence") })
    }
    
    func testRejectRecording_withClipping() async throws {
        // Given: Recording with 2% clipped frames
        let frames: [[String: AnyCodable]] = (0..<100).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(-10.0),
                "is_clipped": AnyCodable(i < 2)
            ]
        }
        let recording = Recording(
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
        // When: Recording is validated
        let result = RecordingValidator.validateFull(recording: recording)
        // Then: Should be invalid due to clipping
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reasons.contains { $0.contains("Clipping detected") })
    }
    
    func testAcceptValidRecording() async throws {
        // Given: Recording with good quality
        let frames: [[String: AnyCodable]] = (0..<100).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(-20.0),
                "is_clipped": AnyCodable(false)
            ]
        }
        let recording = Recording(
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
        // When: Recording is validated
        let result = RecordingValidator.validateFull(recording: recording)
        // Then: Should be valid
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.reasons.isEmpty)
    }
    
    func testValidateSchemaExport() async throws {
        // Given: Valid recording for export
        let frames: [[String: AnyCodable]] = (0..<10).map { i in
            [
                "time_sec": AnyCodable(Double(i) * 0.01),
                "power_dB": AnyCodable(-20.0),
                "is_clipped": AnyCodable(false)
            ]
        }
        let recording = Recording(
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
            frameFeatures: frames,
            summaryFeatures: nil
        )
        // When: Recording is uploaded
        let uploader = RecordingUploaderService()
        let expectation = XCTestExpectation(description: "Upload completion")
        try uploader.uploadRecording(recording) { result in
            // Then: Should upload successfully
            switch result {
            case .success:
                XCTAssertTrue(true) // Success case
            case .failure(let error):
                XCTFail("Upload failed with error: \(error)")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testValidateReferenceSampleQA() async throws {
        // Given: Recording for reference sample QA
        let recording = Recording(
            userID: "U6",
            sessionTime: Date(),
            task: "vowel",
            fileURL: URL(fileURLWithPath: "/tmp/test6.wav"),
            filename: "test6.wav",
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
        // When: Recording is validated against reference
        let uploader = RecordingUploaderService()
        let discrepancies = uploader.validateAgainstReference(recording: recording, reference: recording)
        // Then: Should have no discrepancies
        XCTAssertTrue(discrepancies.isEmpty)
    }
} 