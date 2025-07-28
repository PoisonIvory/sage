import SwiftUI
import AVFoundation

/// SessionsView for daily voice recording and analysis using HybridVocalAnalysisService
/// GWT: Given user wants to record daily voice session
/// GWT: When using SessionsView with new vocal analysis
/// GWT: Then provides immediate local analysis and comprehensive cloud results
struct SessionsView: View {
    @StateObject private var vocalAnalysisService = HybridVocalAnalysisService()
    @State private var showRecordingModal = false
    @State private var errorMessage: String?
    @State private var currentAnalysisResult: VocalAnalysisResult?
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?

    var body: some View {
        NavigationView {
            VStack(spacing: SageSpacing.large) {
                Spacer()
                
                if vocalAnalysisService.currentState.isAnalyzing {
                    analysisInProgressView
                } else if let result = currentAnalysisResult {
                    analysisResultView(result)
                } else {
                    emptySessionsView
                }
                
                Spacer()
                
                recordButton
                
                Spacer(minLength: 60)
            }
            .background(sageBackground)
            .navigationTitle("Voice Sessions")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                setupResultsSubscription()
            }
            .onDisappear {
                vocalAnalysisService.stopListening()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var sageBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.3)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var emptySessionsView: some View {
        VStack(spacing: SageSpacing.medium) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 64))
                .foregroundColor(SageColors.sageTeal)
            
            Text("Ready for Voice Session")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
            
            Text("Record your voice to track daily vocal patterns and biomarkers.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.earthClay)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xLarge)
        }
    }
    
    private var analysisInProgressView: some View {
        VStack(spacing: SageSpacing.medium) {
            SageProgressView()
                .scaleEffect(0.8)
            
            Text("Analyzing Voice")
                .font(SageTypography.headline)
                .foregroundColor(SageColors.sageTeal)
            
            Text(vocalAnalysisService.currentState.description)
                .font(SageTypography.body)
                .foregroundColor(SageColors.earthClay)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SageSpacing.xLarge)
        }
    }
    
    private func analysisResultView(_ result: VocalAnalysisResult) -> some View {
        VStack(spacing: SageSpacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(SageColors.sageTeal)
            
            Text("Analysis Complete")
                .font(SageTypography.headline)
                .foregroundColor(SageColors.espressoBrown)
            
            VStack(spacing: SageSpacing.small) {
                HStack {
                    Text("F0 Mean:")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                    Spacer()
                    Text("\(String(format: "%.1f", result.localMetrics.f0Mean)) Hz")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.espressoBrown)
                }
                
                HStack {
                    Text("Confidence:")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                    Spacer()
                    Text("\(Int(result.localMetrics.confidence))%")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.espressoBrown)
                }
                
                HStack {
                    Text("Status:")
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.earthClay)
                    Spacer()
                    Text(result.status.rawValue.capitalized)
                        .font(SageTypography.body)
                        .foregroundColor(SageColors.sageTeal)
                }
            }
            .padding()
            .background(SageColors.sandstone.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal, SageSpacing.xLarge)
            
            if result.comprehensiveAnalysis != nil {
                Text("Comprehensive analysis available in Dashboard")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.cinnamonBark)
                    .italic()
            } else {
                Text("Comprehensive analysis in progress...")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.earthClay)
                    .italic()
            }
        }
    }
    
    private var recordButton: some View {
        Button(action: {
            if isRecording {
                // Stop recording (handled automatically by timer)
            } else {
                startRecording()
            }
        }) {
            HStack {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 24))
                Text(isRecording ? "Recording..." : "Record Voice")
                    .font(SageTypography.headline)
            }
            .foregroundColor(SageColors.fogWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SageSpacing.medium)
            .background(isRecording ? SageColors.coralBlush : SageColors.sageTeal)
            .cornerRadius(16)
        }
        .disabled(vocalAnalysisService.currentState.isAnalyzing)
        .padding(.horizontal, SageSpacing.xLarge)
    }
    
    // MARK: - Helper Methods
    
    private func startRecording() {
        isRecording = true
        
        Task {
            do {
                // Setup audio session for recording
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
                
                // Create recording URL
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("session_recording_\(UUID().uuidString).wav")
                
                // Configure audio recorder settings
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false
                ]
                
                // Create and start audio recorder
                audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
                audioRecorder?.record()
                
                // Get current user ID
                let userId = "session_user_\(UUID().uuidString)" // In production, use actual auth
                
                let voiceRecording = VoiceRecording(
                    audioURL: tempURL,
                    duration: 5.0, // 5 second recording
                    userId: userId
                )
                
                print("SessionsView: Started real audio recording to: \(tempURL.path)")
                
                // Stop recording after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.stopRecording(voiceRecording)
                }
                
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
                isRecording = false
            }
        }
    }
    
    private func stopRecording(_ voiceRecording: VoiceRecording) {
        // Stop the audio recorder
        audioRecorder?.stop()
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("SessionsView: Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        // Verify the audio file was created
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: voiceRecording.audioURL.path) {
            errorMessage = "Recording failed. Please try again."
            isRecording = false
            return
        }
        
        print("SessionsView: Audio file created successfully, starting analysis")
        completeRecording(voiceRecording)
    }
    
    private func completeRecording(_ voiceRecording: VoiceRecording) {
        isRecording = false
        
        Task {
            do {
                let result = try await vocalAnalysisService.analyzeVoice(recording: voiceRecording)
                
                await MainActor.run {
                    currentAnalysisResult = result
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Voice analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func setupResultsSubscription() {
        let resultsStream = vocalAnalysisService.subscribeToResults()
        
        Task {
            for await biomarkers in resultsStream {
                await MainActor.run {
                    // Update current result with comprehensive analysis
                    if var result = currentAnalysisResult {
                        result = VocalAnalysisResult(
                            recordingId: result.recordingId,
                            localMetrics: result.localMetrics,
                            comprehensiveAnalysis: biomarkers,
                            status: .complete
                        )
                        currentAnalysisResult = result
                    }
                }
            }
        }
    }
}

#Preview {
    SessionsView()
} 