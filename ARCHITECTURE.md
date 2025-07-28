# Sage Voice Analysis Architecture

This document provides a visual overview of the Sage voice analysis pipeline, from user audio input to extracted speech features and real-time app display. It is designed to help new contributors understand how audio data flows through the system and how the modular architecture supports feature expansion.

## System Flow Diagram

### Simple Test Diagram
```mermaid
flowchart LR
    A[iOS App] --> B[Firebase Storage]
    B --> C[Cloud Function]
    C --> D[F0Extractor]
    D --> E[Firestore]
    E --> F[iOS Display]
```

### Detailed Architecture
```mermaid
graph TD
    %% iOS App Layer
    subgraph iOS ["iOS App (Swift/SwiftUI)"]
        A1[SageApp.swift]
        A2[ContentView.swift]
        A3[OnboardingJourneyView.swift]
        A4[OnboardingJourneyViewModel.swift]
        A5[AuthChoiceView.swift]
        A6[LoginView.swift]
        A7[SignUpView.swift]
        A8[AuthViewModel.swift]
        A9[VoiceDashboardView.swift]
        A10[HomeView.swift]
        A11[SessionsView.swift]
        A12[SessionsViewModel.swift]
        A13[RecordingCard.swift]
        A14[PoeticSessionsEmptyState.swift]
    end

    %% iOS Services Layer
    subgraph iOS_Services ["iOS Services"]
        B1[AuthService.swift]
        B2[AudioRecorderProtocol.swift]
        B3[MicrophonePermissionManager.swift]
        B4[OnboardingAudioRecorder.swift]
        B5[F0DataService.swift]
        B6[AudioUploader.swift]
        B7[RecordingUploaderService.swift]
        B8[UserProfileRepository.swift]
        B9[AnalyticsService.swift]
    end

    %% iOS Models Layer
    subgraph iOS_Models ["iOS Models"]
        C1[UserProfile.swift]
        C2[UserProfileValidator.swift]
        C3[Recording.swift]
        C4[RecordingValidator.swift]
        C5[AudioRecorder.swift]
        C6[OnboardingProtocols.swift]
        C7[OnboardingTypes.swift]
    end

    %% iOS UI Components
    subgraph iOS_UI ["iOS UI Components"]
        D1[SageButton.swift]
        D2[SageCard.swift]
        D3[SageTextField.swift]
        D4[SageColors.swift]
        D5[SageTypography.swift]
        D6[SageProgressView.swift]
        D7[SageAvatar.swift]
        D8[SageInsightCard.swift]
        D9[SageEmptyState.swift]
        D10[SageSectionHeader.swift]
        D11[SageDivider.swift]
        D12[SageSpacing.swift]
        D13[SageProgressRing.swift]
        D14[AbstractWaveBackground.swift]
        D15[WelcomeView.swift]
    end

    %% Firebase Storage
    E[Firebase Storage: .wav files]

    %% Cloud Functions Entry
    F[main.py: process_audio_file]

    %% Cloud Services Layer
    subgraph Cloud_Services ["Cloud Services"]
        G1[audio_processing_service.py]
        G2[voice_analysis_service.py]
    end

    %% Feature Extractors
    subgraph Feature_Extractors ["Feature Extractors"]
        H1[base.py: BaseFeatureExtractor]
        H2[f0_extractor.py: F0Extractor]
        H3[__init__.py]
    end

    %% Utilities
    subgraph Utilities ["Utilities"]
        I1[audio_utils.py: safe_mean, safe_std]
        I2[feature_formatter.py]
        I3[structured_logging.py]
        I4[firebase_utils.py]
        I5[tool_versions.py]
        I6[constants.py]
    end

    %% Entities
    J1[entities.py: FeatureSet, FeatureMetadata]

    %% Firestore
    K[Firestore: Store Insights]

    %% Tests
    subgraph Tests ["Tests"]
        L1[test_audio_processing_service.py]
        L2[test_feature_formatter.py]
        L3[test_integration.py]
        L4[test_main_integration.py]
    end

    %% iOS Tests
    subgraph iOS_Tests ["iOS Tests"]
        M1[AppFlowTests.swift]
        M2[AuthFlowTests.swift]
        M3[AuthViewModelTests.swift]
        M4[OnboardingTestHarness.swift]
        M5[SignupFlowTests.swift]
        M6[VocalTestScreenTests.swift]
        M7[ReadingPromptTests.swift]
        M8[ExplainerScreenTests.swift]
        M9[FinalStepTests.swift]
        M10[AudioUploadTests.swift]
        M11[HomeViewTests.swift]
        M12[RecordingValidationTests.swift]
        M13[F0DataServiceTests.swift]
    end

    %% Data Flow
    A3 --> A4
    A4 --> B7
    B7 --> E
    E --> F
    F --> G1
    G1 --> H2
    H2 --> I2
    I2 --> K
    K --> A9

    %% Internal Dependencies
    H2 --> H1
    H2 --> I1
    G1 --> I3
    G1 --> I4
    F --> I5
    F --> I6
    H2 --> J1
    G1 --> J1

    %% Test Dependencies
    L1 --> G1
    L2 --> I2
    L3 --> H2
    L4 --> F
    M1 --> A1
    M2 --> A6
    M3 --> A8
    M4 --> A3
    M5 --> A7
    M6 --> A3
    M7 --> A3
    M8 --> A3
    M9 --> A3
    M10 --> B7
    M11 --> A10
    M12 --> C4
    M13 --> B5

    %% UI Dependencies
    A3 --> D1
    A3 --> D2
    A3 --> D3
    A3 --> D4
    A3 --> D5
    A3 --> D6
    A3 --> D7
    A3 --> D8
    A3 --> D9
    A3 --> D10
    A3 --> D11
    A3 --> D12
    A3 --> D13
    A3 --> D14
    A3 --> D15

    %% Service Dependencies
    A4 --> B1
    A4 --> B2
    A4 --> B3
    A4 --> B4
    A4 --> B5
    A4 --> B6
    A4 --> B7
    A4 --> B8
    A4 --> B9

    %% Model Dependencies
    A4 --> C1
    A4 --> C2
    A4 --> C3
    A4 --> C4
    A4 --> C5
    A4 --> C6
    A4 --> C7
```

## Maintaining This Diagram

To keep this diagram useful, it must evolve with your architecture.

### When to Update

Update the diagram when:

- Adding a new feature extractor (e.g., jitter, shimmer)
- Changing how audio is processed, stored, or displayed
- Modifying the Cloud Function's processing logic
- Introducing new services or stages in the pipeline

### How to Update in Cursor

1. Open `ARCHITECTURE.md` in Cursor
2. Edit the Mermaid diagram block using plain Markdown
3. Use the built-in Markdown Preview in Cursor to visualize changes
4. Follow these naming rules:
   - Use `[ComponentName: Description]` format for clarity
   - Maintain left-to-right or top-down direction (`graph TD`)
5. Commit changes with a message like: `docs: update architecture diagram for shimmer extractor`

If you're unsure how to update the diagram, ask in the project Slack or check with the voice pipeline maintainer.

**Maintainers**: Please ensure Mermaid support in your Markdown renderer (e.g., GitHub, Cursor) is active. No external setup is required in Cursor; just use Preview Mode to see it live. 