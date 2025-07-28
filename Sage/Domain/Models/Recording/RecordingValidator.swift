import Foundation
import AVFoundation

/// Validation result for a recording, including reasons for failure and metrics.
/// - Complies with DATA_STANDARDS.md §3.4, DATA_DICTIONARY.md, RESOURCES.md.
struct RecordingValidationResult: Codable, Hashable {
    let isValid: Bool
    let reasons: [String]
    let metrics: [String: AnyCodable]?
}

/// RecordingValidator performs all pre-upload and feature-level validation for research-grade compliance.
/// - See DATA_STANDARDS.md §3.4 for required checks.
/// - See RESOURCES.md §6 for reference sample QA.
final class RecordingValidator {
    // MARK: - Validation Thresholds (DATA_STANDARDS.md §3.4)
    private struct Thresholds {
        static let minDuration: TimeInterval = 3.0 // seconds, task-specific
        static let maxSilencePct: Double = 0.3 // 30% silence
        static let maxClippingPct: Double = 0.001 // 0.1% clipped samples
        static let minSNR: Double = 20.0 // dB
        static let requiredSampleRate: Double = 48000.0 // Hz
        static let requiredBitDepth: Int = 24
        static let requiredChannels: Int = 1 // mono
    }

    /// Full validation pipeline for a recording.
    /// - Returns: RecordingValidationResult with reasons and metrics.
    /// - References DATA_STANDARDS.md §3.4, DATA_DICTIONARY.md, RESOURCES.md.
    static func validateFull(recording: Recording) -> RecordingValidationResult {
        print("[RecordingValidator] Starting validation for recording id=\(recording.id)")
        var reasons: [String] = []
        var metrics: [String: AnyCodable] = [:]

        // Duration check
        if recording.duration < Thresholds.minDuration {
            let msg = "Duration too short (< \(Thresholds.minDuration)s)"
            print("[RecordingValidator] \(msg)")
            reasons.append(msg)
        }
        metrics["duration"] = AnyCodable(recording.duration)

        // Format checks
        if recording.sampleRate != Thresholds.requiredSampleRate {
            let msg = "Sample rate not 48kHz (found \(recording.sampleRate))"
            print("[RecordingValidator] \(msg)")
            reasons.append(msg)
        }
        if recording.bitDepth != Thresholds.requiredBitDepth {
            let msg = "Bit depth not 24-bit (found \(recording.bitDepth))"
            print("[RecordingValidator] \(msg)")
            reasons.append(msg)
        }
        if recording.channelCount != Thresholds.requiredChannels {
            let msg = "Not mono audio (found \(recording.channelCount) channels)"
            print("[RecordingValidator] \(msg)")
            reasons.append(msg)
        }

        // Silence detection (frame-level)
        if let frames = recording.frameFeatures {
            let silenceFrames = frames.filter { frame in
                if let power = frame["power_dB"]?.value as? Double {
                    return power < -60.0
                }
                return false
            }
            let silencePct = Double(silenceFrames.count) / Double(frames.count)
            metrics["silence_pct"] = AnyCodable(silencePct)
            print("[RecordingValidator] Silence percentage: \(Int(silencePct * 100))%")
            if silencePct > Thresholds.maxSilencePct {
                let msg = "Too much silence (\(Int(silencePct * 100))%)"
                print("[RecordingValidator] \(msg)")
                reasons.append(msg)
            }
        }

        // Clipping detection (frame-level or raw)
        if let frames = recording.frameFeatures {
            let clippedFrames = frames.filter { frame in
                if let clipped = frame["is_clipped"]?.value as? Bool {
                    return clipped
                }
                return false
            }
            let clippingPct = Double(clippedFrames.count) / Double(frames.count)
            metrics["clipping_pct"] = AnyCodable(clippingPct)
            print("[RecordingValidator] Clipping percentage: \(String(format: "%.1f", clippingPct * 100))%")
            if clippingPct > Thresholds.maxClippingPct {
                let clippingPercent = clippingPct * 100
                let msg = "Clipping detected (\(String(format: "%.1f", clippingPercent))% of frames)"
                print("[RecordingValidator] \(msg)")
                reasons.append(msg)
            }
        }

        // SNR estimation (if available)
        if let snr = recording.summaryFeatures?["snr_dB"]?.value as? Double {
            metrics["snr_dB"] = AnyCodable(snr)
            print("[RecordingValidator] SNR: \(snr) dB")
            if snr < Thresholds.minSNR {
                let msg = "Low SNR (< \(Thresholds.minSNR) dB)"
                print("[RecordingValidator] \(msg)")
                reasons.append(msg)
            }
        }

        let result = RecordingValidationResult(
            isValid: reasons.isEmpty,
            reasons: reasons,
            metrics: metrics.isEmpty ? nil : metrics
        )
        print("[RecordingValidator] Validation result for recording id=\(recording.id): isValid=\(result.isValid), reasons=\(result.reasons), metrics=\(result.metrics ?? [:])")
        return result
    }

    // MARK: - Reference Sample QA (stub)
    /// Compares extracted features to reference sample outputs for QA.
    /// - See RESOURCES.md §6 for details.
    static func validateAgainstReference(recording: Recording, reference: Recording) -> [String] {
        // Feature comparison implementation to be added as needed
        // Return list of discrepancies for FEEDBACK_LOG.md
        return []
    }
} 