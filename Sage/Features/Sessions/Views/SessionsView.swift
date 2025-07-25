import SwiftUI

/// SessionsView displays the user's voice recording sessions using Sage design system components.
/// - Complies with UI_STANDARDS.md, DATA_DICTIONARY.md, DATA_STANDARDS.md §3.3.
struct SessionsView: View {
    @StateObject private var viewModel = SessionsViewModel()
    @State private var showUploadSuccessAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: SageSpacing.large) {
                    SageSectionHeader(title: "Voice Sessions")
                    if viewModel.recordings.isEmpty {
                        SageEmptyState(
                            iconName: "mic.circle.fill",
                            title: "No recordings yet",
                            message: "Start your first voice journal by tapping the + button."
                        ) { }
                    } else {
                        recordingsList
                    }
                }
                .background(SageColors.fogWhite)
                // Floating Action Button (FAB)
                if viewModel.recordings.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            SageFloatingActionButton(action: { viewModel.startNewSession() })
                                .padding(.trailing, SageSpacing.large)
                                .padding(.bottom, SageSpacing.large)
                        }
                    }
                    .allowsHitTesting(true)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.isRecordingActive) {
                RecordingSessionModal(viewModel: viewModel)
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { newValue in if !newValue { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error").font(SageTypography.headline),
                    message: Text(viewModel.errorMessage ?? "").font(SageTypography.body),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showUploadSuccessAlert) {
                Alert(title: Text("Upload Successful"), message: Text("Your recording was uploaded to Firestore."), dismissButton: .default(Text("OK")))
            }
            .onChange(of: viewModel.uploadSuccess) { newValue in
                if newValue {
                    showUploadSuccessAlert = true
                    viewModel.uploadSuccess = false // reset for next session
                }
            }
        }
    }

    private var recordingsList: some View {
        ScrollView {
            LazyVStack(spacing: SageSpacing.medium) {
                ForEach(viewModel.recordings) { recording in
                    RecordingCard(recording: recording)
                        .padding(.horizontal, SageSpacing.large)
                        .accessibilityElement(children: .combine)
                }
            }
            .padding(.bottom, SageSpacing.xlarge)
        }
    }
}

struct RecordingSessionModal: View {
    @ObservedObject var viewModel: SessionsViewModel
    @State private var timer: Timer? = nil
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            Text("Voice Journal Prompt")
                .font(SageTypography.headline)
                .foregroundColor(SageColors.sageTeal)
                .padding(.top, SageSpacing.xLarge)
            Text(viewModel.currentPromptID ?? "...")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xlarge)
            Text(timerString)
                .font(SageTypography.title)
                .foregroundColor(SageColors.coralBlush)
                .padding(.top, SageSpacing.large)
            Spacer()
            SageButton(title: "End Recording") {
                viewModel.endCurrentSession()
            }
            .padding(.bottom, SageSpacing.xLarge)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .background(SageColors.fogWhite.ignoresSafeArea())
    }

    private var timerString: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    SessionsView()
} 