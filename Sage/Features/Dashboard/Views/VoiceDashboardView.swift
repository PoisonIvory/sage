// VoiceDashboardView.swift
// Sage Voice Biomarker Dashboard (Skeleton)
//
// Implements dashboard structure per UI_STANDARDS.md, DATA_DICTIONARY.md, DATA_STANDARDS.md, and AI_GENERATION_RULES.md.
// All data is placeholder/mock for initial UI development.
//
// See also: TEST_PLAN.md for test requirements, CONTRIBUTING.md for code style, and GLOSSARY.md for terminology.

import SwiftUI

// MARK: - Mock Data (see DATA_DICTIONARY.md for ranges/units)
struct DashboardMockData {
    let stabilityScore: Double = 7.0 // out of 10
    let stabilityPercentile: Double = 0.68 // 68th percentile
    let stabilityInsight = "Your voice carried a gentle steadiness today, like a calm morning breeze."
    let pitch: Double = 210.0 // Hz
    let expressiveness: Double = 0.62 // 0-1
    let prosodyInsight = "Your tone was soft and expressive, hinting at openness."
    let speechRate: Double = 142 // WPM
    let pauseCount: Int = 8
    let fluencyPercentile: Double = 0.41
    let fluencyInsight = "Your words flowed at a slower, thoughtful pace."
    let sentiment: Double = -0.18 // -1 to 1
    let sentimentPercentile: Double = 0.32
    let sentimentInsight = "A gentle melancholy colored your reflections."
    let lexicalDiversity: Double = 0.52 // 0-1
    let lexicalPercentile: Double = 0.57
    let lexicalInsight = "Your vocabulary was quietly varied, like a walk through a familiar forest."
}

// MARK: - Percentile Bar (New UI Pattern, see FEEDBACK_LOG.md)
struct SagePercentileBar: View {
    let value: Double // 0-1
    let accent: Color
    let background: Color
    let label: String
    let percentile: Double // 0-1
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.espressoBrown)
                Spacer()
                Text("\(Int(percentile * 100))th %ile")
                    .font(SageTypography.caption)
                    .foregroundColor(accent)
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(background)
                    .frame(height: 8)
                Capsule()
                    .fill(accent)
                    .frame(width: CGFloat(percentile) * 160, height: 8)
                    .animation(.easeOut(duration: 0.6), value: percentile)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Int(percentile * 100))th percentile")
    }
}

// MARK: - Stylized Card
struct SageStylizedCard<Content: View>: View {
    let background: Color
    let shadow: Color
    let content: Content
    init(background: Color, shadow: Color = SageColors.earthClay.opacity(0.10), @ViewBuilder content: () -> Content) {
        self.background = background
        self.shadow = shadow
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: SageSpacing.medium) {
            content
        }
        .padding(SageSpacing.large)
        .background(background)
        .cornerRadius(20)
        .shadow(color: shadow, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Dashboard View
struct VoiceDashboardView: View {
    let data = DashboardMockData()
    var body: some View {
        print("VoiceDashboardView: body rendered (stylized)")
        return ScrollView {
            VStack(spacing: SageSpacing.xLarge) {
                // Acoustic Features Group
                VStack(spacing: SageSpacing.medium) {
                    Text("Your Voice Today")
                        .font(SageTypography.title)
                        .foregroundColor(SageColors.espressoBrown)
                        .padding(.bottom, SageSpacing.small)
                    SageStylizedCard(background: SageColors.sandstone) {
                        HStack(alignment: .center, spacing: SageSpacing.large) {
                            VStack(alignment: .leading, spacing: SageSpacing.small) {
                                Text("Voice Stability")
                                    .font(SageTypography.headline)
                                    .foregroundColor(SageColors.sageTeal)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", data.stabilityScore))
                                        .font(SageTypography.title)
                                        .foregroundColor(SageColors.espressoBrown)
                                    Text("/10")
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.earthClay)
                                }
                                SagePercentileBar(value: data.stabilityScore/10, accent: SageColors.sageTeal, background: SageColors.fogWhite, label: "Stability", percentile: data.stabilityPercentile)
                                Text(data.stabilityInsight)
                                    .font(SageTypography.body)
                                    .foregroundColor(SageColors.cinnamonBark)
                                    .italic()
                            }
                            Spacer()
                        }
                    }
                    SageStylizedCard(background: SageColors.fogWhite) {
                        VStack(alignment: .leading, spacing: SageSpacing.small) {
                            Text("Prosody & Expression")
                                .font(SageTypography.headline)
                                .foregroundColor(SageColors.coralBlush)
                            HStack(spacing: SageSpacing.medium) {
                                VStack(alignment: .leading) {
                                    Text("Pitch")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    Text(String(format: "%.0f Hz", data.pitch))
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.espressoBrown)
                                }
                                VStack(alignment: .leading) {
                                    Text("Expressiveness")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    SagePercentileBar(value: data.expressiveness, accent: SageColors.coralBlush, background: SageColors.sandstone, label: "Expressiveness", percentile: 0.64)
                                }
                            }
                            Text(data.prosodyInsight)
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.coralBlush)
                                .italic()
                        }
                    }
                }
                // Speech & Content Features Group
                VStack(spacing: SageSpacing.medium) {
                    SageStylizedCard(background: SageColors.sandstone) {
                        VStack(alignment: .leading, spacing: SageSpacing.small) {
                            Text("Speech Rate & Fluency")
                                .font(SageTypography.headline)
                                .foregroundColor(SageColors.sageTeal)
                            HStack(spacing: SageSpacing.medium) {
                                VStack(alignment: .leading) {
                                    Text("WPM")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    Text(String(format: "%.0f", data.speechRate))
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.espressoBrown)
                                }
                                VStack(alignment: .leading) {
                                    Text("Pauses")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    Text("\(data.pauseCount)")
                                        .font(SageTypography.body)
                                        .foregroundColor(SageColors.espressoBrown)
                                }
                                VStack(alignment: .leading) {
                                    SagePercentileBar(value: data.speechRate/200, accent: SageColors.sageTeal, background: SageColors.fogWhite, label: "Fluency", percentile: data.fluencyPercentile)
                                }
                            }
                            Text(data.fluencyInsight)
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.sageTeal)
                                .italic()
                        }
                    }
                    SageStylizedCard(background: SageColors.fogWhite) {
                        VStack(alignment: .leading, spacing: SageSpacing.small) {
                            Text("Verbal Content Analysis")
                                .font(SageTypography.headline)
                                .foregroundColor(SageColors.cinnamonBark)
                            HStack(spacing: SageSpacing.medium) {
                                VStack(alignment: .leading) {
                                    Text("Sentiment")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    SagePercentileBar(value: (data.sentiment+1)/2, accent: SageColors.coralBlush, background: SageColors.sandstone, label: "Sentiment", percentile: data.sentimentPercentile)
                                }
                                VStack(alignment: .leading) {
                                    Text("Lexical Diversity")
                                        .font(SageTypography.caption)
                                        .foregroundColor(SageColors.espressoBrown)
                                    SagePercentileBar(value: data.lexicalDiversity, accent: SageColors.cinnamonBark, background: SageColors.fogWhite, label: "Diversity", percentile: data.lexicalPercentile)
                                }
                            }
                            Text(data.sentimentInsight)
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.coralBlush)
                                .italic()
                            Text(data.lexicalInsight)
                                .font(SageTypography.body)
                                .foregroundColor(SageColors.cinnamonBark)
                                .italic()
                        }
                    }
                }
            }
            .padding([.horizontal, .top], SageSpacing.xLarge)
            .padding(.bottom, 60)
            .background(
                LinearGradient(gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
        .navigationTitle("Dashboard")
        .background(SageColors.fogWhite.ignoresSafeArea())
    }
}

// MARK: - Preview
struct VoiceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceDashboardView()
    }
}
// FEEDBACK_LOG.md: New UI pattern 'SagePercentileBar' introduced for percentile/relative value display. Stylized grouping of cards by feature type. Visual metaphors and color groupings logged for future standardization. 