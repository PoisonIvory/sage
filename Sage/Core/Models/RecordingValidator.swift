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
        var reasons: [String] = []
        var metrics: [String: AnyCodable] = [:]

        // Duration check
        if recording.duration < Thresholds.minDuration {
            reasons.append("Duration too short (< \(Thresholds.minDuration)s)")
        }
        metrics["duration"] = AnyCodable(recording.duration)

        // Format checks
        if recording.sampleRate != Thresholds.requiredSampleRate {
            reasons.append("Sample rate not 48kHz (found \(recording.sampleRate))")
        }
        if recording.bitDepth != Thresholds.requiredBitDepth {
            reasons.append("Bit depth not 24-bit (found \(recording.bitDepth))")
        }
        if recording.channelCount != Thresholds.requiredChannels {
            reasons.append("Not mono audio (found \(recording.channelCount) channels)")
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
            if silencePct > Thresholds.maxSilencePct {
                reasons.append("Too much silence (\(Int(silencePct * 100))%)")
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
            if clippingPct > Thresholds.maxClippingPct {
                // Format as percentage with one decimal place (DATA_STANDARDS.md §3.4)
                let clippingPercent = clippingPct * 100
                reasons.append("Clipping detected (\(String(format: "%.1f", clippingPercent))% of frames)")
            }
        }

        // SNR estimation (if available)
        if let snr = recording.summaryFeatures?["snr_dB"]?.value as? Double {
            metrics["snr_dB"] = AnyCodable(snr)
            if snr < Thresholds.minSNR {
                reasons.append("Low SNR (< \(Thresholds.minSNR) dB)")
            }
        }

        // Reference sample QA (RESOURCES.md §6)
        // (Stub: actual implementation would compare to reference outputs)
        // if isReferenceSample(recording) { ... compare features, log discrepancies ... }

        return RecordingValidationResult(
            isValid: reasons.isEmpty,
            reasons: reasons,
            metrics: metrics.isEmpty ? nil : metrics
        )
    }

    // MARK: - Reference Sample QA (stub)
    /// Compares extracted features to reference sample outputs for QA.
    /// - See RESOURCES.md §6 for details.
    static func validateAgainstReference(recording: Recording, reference: Recording) -> [String] {
        // TODO: Implement feature-by-feature comparison, log discrepancies
        // Return list of discrepancies for FEEDBACK_LOG.md
        return []
    }
} 