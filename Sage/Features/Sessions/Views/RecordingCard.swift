import SwiftUI

/// RecordingCard displays a summary of a voice session, using Sage design system components.
/// - Complies with UI_STANDARDS.md, DATA_DICTIONARY.md, DATA_STANDARDS.md §3.3.
struct RecordingCard: View {
    let recording: Recording

    var body: some View {
        SageCard {
            VStack(alignment: .leading, spacing: SageSpacing.medium) {
                HStack {
                    Text(formattedDate(recording.sessionTime))
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.espressoBrown)
                    Spacer()
                    Text("\(formattedDuration(recording.duration))")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.sandstone)
                }
                Text("Task: \(recording.task)")
                    .font(SageTypography.body)
                    .foregroundColor(SageColors.sageTeal)
                if let device = recording.deviceModel as String? {
                    Text("Device: \(device)")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.earthClay)
                }
                if let summary = recording.summaryFeatures {
                    SageDivider()
                    HStack {
                        if let f0 = summary["F0_mean"]?.value as? Double {
                            Text("F0: \(String(format: "%.1f", f0)) Hz")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.sageTeal)
                        }
                        if let jitter = summary["jitter_pct"]?.value as? Double {
                            Text("Jitter: \(String(format: "%.2f", jitter)) %")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.coralBlush)
                        }
                        if let shimmer = summary["shimmer_dB"]?.value as? Double {
                            Text("Shimmer: \(String(format: "%.2f", shimmer)) dB")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.earthClay)
                        }
                        if let hnr = summary["HNR_dB"]?.value as? Double {
                            Text("HNR: \(String(format: "%.1f", hnr)) dB")
                                .font(SageTypography.caption)
                                .foregroundColor(SageColors.sandstone)
                        }
                    }
                }
            }
            .padding(SageSpacing.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voice session on \(formattedDate(recording.sessionTime)), duration \(formattedDuration(recording.duration)), task \(recording.task)")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
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
        deviceModel: "iPhone 15",
        osVersion: "17.0",
        appVersion: "1.0",
        duration: 5.0,
        frameFeatures: nil,
        summaryFeatures: [
            "F0_mean": AnyCodable(220.5),
            "jitter_pct": AnyCodable(0.89),
            "shimmer_dB": AnyCodable(0.35),
            "HNR_dB": AnyCodable(18.7)
        ]
    )
    return RecordingCard(recording: rec)
} 