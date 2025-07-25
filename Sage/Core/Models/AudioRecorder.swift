import Foundation
import AVFoundation
import UIKit
// import Protocols.swift if needed

/// AudioRecorder handles audio capture, frame-level feature extraction, and metadata collection.
/// - Complies with DATA_STANDARDS.md §2.1, §2.3, §3.3, DATA_DICTIONARY.md, RESOURCES.md, CONTRIBUTING.md.
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AudioRecordingManaging {
    static let shared = AudioRecorder()

    // MARK: - Published Properties
    @Published var recordings: [Recording] = []
    @Published var isRecording: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var currentMeterLevel: Float = 0

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var frameFeatures: [[String: AnyCodable]] = []
    private var startTime: Date?
    private var promptID: String = ""

    // MARK: - Audio Configuration (DATA_STANDARDS.md §2.1)
    private let sampleRate: Double = 48000.0
    private let bitDepth: Int = 24
    private let channelCount: Int = 1
    private let audioFormat = kAudioFormatLinearPCM

    // MARK: - Recording Methods
    func startRecording(promptID: String) {
        self.promptID = promptID
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            let userID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            let recordingID = UUID().uuidString
            let fileName = "\(userID)_\(recordingID).wav"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            let settings: [String: Any] = [
                AVFormatIDKey: audioFormat,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channelCount,
                AVLinearPCMBitDepthKey: bitDepth,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            startTime = Date()
            currentTime = 0
            isRecording = true
            frameFeatures = []
            startMeterTimer()
        } catch {
            print("❌ Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording(promptID: String) {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        let url = recorder.url
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let userID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let sessionTime = start
        let recording = Recording(
            userID: userID,
            sessionTime: sessionTime,
            task: promptID,
            fileURL: url,
            filename: url.lastPathComponent,
            fileFormat: "wav",
            sampleRate: sampleRate,
            bitDepth: bitDepth,
            channelCount: channelCount,
            deviceModel: deviceModel,
            osVersion: systemVersion,
            appVersion: appVersion,
            duration: duration,
            frameFeatures: frameFeatures,
            summaryFeatures: nil // To be filled by analysis pipeline
        )
        recordings.append(recording)
        saveRecordings()
    }

    func deleteRecording(_ recording: Recording) {
        let url = recording.fileURL
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("⚠️ Error deleting recording: \(error.localizedDescription)")
        }
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    // MARK: - Metering & Frame Feature Extraction
    private func startMeterTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            self.currentTime += 0.01
            let power = recorder.averagePower(forChannel: 0)
            let isClipped = power >= 0.0
            let frame: [String: AnyCodable] = [
                "time_sec": AnyCodable(self.currentTime),
                "power_dB": AnyCodable(Double(power)),
                "is_clipped": AnyCodable(isClipped)
            ]
            self.frameFeatures.append(frame)
            self.currentMeterLevel = power
        }
    }

    // MARK: - File Management
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private func recordingsFilePath() -> URL {
        getDocumentsDirectory().appendingPathComponent("recordings.json")
    }
    private func saveRecordings() {
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: recordingsFilePath())
        } catch {
            print("💾 Error saving recordings: \(error.localizedDescription)")
        }
    }
    private func loadRecordings() {
        let path = recordingsFilePath()
        guard FileManager.default.fileExists(atPath: path.path) else { return }
        do {
            let data = try Data(contentsOf: path)
            recordings = try JSONDecoder().decode([Recording].self, from: data)
        } catch {
            print("📂 Error loading recordings: \(error.localizedDescription)")
        }
    }
}

extension AudioRecorder {
    /// Requests microphone permission and calls the completion handler with the result.
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
} 