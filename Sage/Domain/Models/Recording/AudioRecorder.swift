import Foundation
import AVFoundation
import UIKit
import FirebaseAuth
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
        print("[AudioRecorder] Attempting to start recording for promptID=\(promptID)")
        self.promptID = promptID
        
        do {
            try setupAudioSession()
            let fileURL = createRecordingFile()
            try setupAudioRecorder(at: fileURL)
            startRecordingSession()
        } catch {
            print("[AudioRecorder] Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
    }
    
    private func createRecordingFile() -> URL {
        let userID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let recordingID = UUID().uuidString
        let fileName = "\(userID)_\(recordingID).wav"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        return fileURL
    }
    
    private func setupAudioRecorder(at fileURL: URL) throws {
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
    }
    
    private func startRecordingSession() {
        audioRecorder?.record()
        startTime = Date()
        currentTime = 0
        isRecording = true
        frameFeatures = []
        
        let fileName = audioRecorder?.url.lastPathComponent ?? "unknown"
        print("[AudioRecorder] Recording started: file=\(fileName), userID=\(UIDevice.current.identifierForVendor?.uuidString ?? "unknown"), sampleRate=\(sampleRate), bitDepth=\(bitDepth), channels=\(channelCount)")
        startMeterTimer()
    }

    func stopRecording(promptID: String) {
        print("[AudioRecorder] Stopping recording for promptID=\(promptID)")
        guard let recorder = audioRecorder else {
            print("[AudioRecorder] No active recorder found on stopRecording")
            return
        }
        
        stopRecordingSession(recorder)
        let recording = createRecordingFromRecorder(recorder, promptID: promptID)
        saveRecording(recording)
    }
    
    private func stopRecordingSession(_ recorder: AVAudioRecorder) {
        recorder.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    private func createRecordingFromRecorder(_ recorder: AVAudioRecorder, promptID: String) -> Recording {
        guard let start = startTime else {
            print("[AudioRecorder] No startTime found on stopRecording")
            return Recording.empty // Fallback
        }
        
        let duration = Date().timeIntervalSince(start)
        let url = recorder.url
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let userID = Auth.auth().currentUser?.uid ?? "unknown"
        
        let recording = Recording(
            userID: userID,
            sessionTime: start,
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
        
        print("[AudioRecorder] Recording stopped: file=\(url.lastPathComponent), duration=\(duration)s, frames=\(frameFeatures.count), userID=\(userID)")
        return recording
    }
    
    private func saveRecording(_ recording: Recording) {
        recordings.append(recording)
        saveRecordings()
    }

    func deleteRecording(_ recording: Recording) {
        let url = recording.fileURL
        do {
            try FileManager.default.removeItem(at: url)
            print("[AudioRecorder] Deleted recording file: \(url.lastPathComponent)")
        } catch {
            print("[AudioRecorder] Error deleting recording: \(error.localizedDescription)")
        }
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    // MARK: - Metering & Frame Feature Extraction
    private func startMeterTimer() {
        print("[AudioRecorder] Starting metering timer for frame feature extraction")
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
            if Int(self.currentTime * 100) % 100 == 0 { // Log every second
                print("[AudioRecorder] Frame feature: time=\(self.currentTime)s, power=\(power), isClipped=\(isClipped)")
            }
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
            print("[AudioRecorder] Recordings saved to disk (")
        } catch {
            print("[AudioRecorder] Error saving recordings: \(error.localizedDescription)")
        }
    }
    private func loadRecordings() {
        let path = recordingsFilePath()
        guard FileManager.default.fileExists(atPath: path.path) else { return }
        do {
            let data = try Data(contentsOf: path)
            recordings = try JSONDecoder().decode([Recording].self, from: data)
            print("[AudioRecorder] Loaded \(recordings.count) recordings from disk")
        } catch {
            print("[AudioRecorder] Error loading recordings: \(error.localizedDescription)")
        }
    }
}

extension AudioRecorder {
    /// Requests microphone permission and calls the completion handler with the result.
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    print("[AudioRecorder] Microphone permission granted=\(granted)")
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    print("[AudioRecorder] Microphone permission granted=\(granted)")
                    completion(granted)
                }
            }
        }
    }
} 