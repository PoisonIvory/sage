# Sage Voice Analysis Architecture

This document provides a comprehensive visual overview of the Sage voice analysis system, featuring a hybrid client-server architecture for research-grade vocal biomarker analysis. It's designed to help contributors understand the complete system design from user interaction to clinical insights.

**⚠️ Architecture Status**: This document reflects the actual implementation as of January 2025 after major architectural refactoring. The system now follows clean domain-driven design principles with proper separation of concerns.

## 🎯 System Overview

Sage is a research-grade vocal analysis platform that combines immediate local analysis (iOS SFVoiceAnalytics) with comprehensive cloud analysis (Parselmouth/Praat) to provide clinical-quality voice biomarkers including F0, jitter, shimmer, and HNR measurements.

## 📊 High-Level System Architecture

```mermaid
flowchart TD
    subgraph "📱 iOS App"
        A1[User Interface]
        A2[Local Analysis]
        A3[Authentication]
    end
    
    subgraph "☁️ Cloud Infrastructure"
        B1[Firebase Storage]
        B2[Cloud Functions]
        B3[Firestore Database]
    end
    
    subgraph "🔬 Analysis Pipeline"
        C1[SFVoiceAnalytics<br/>Local Analysis]
        C2[Parselmouth<br/>Cloud Analysis]
        C3[Clinical Assessment]
    end
    
    A1 --> A2
    A2 --> C1
    A1 --> B1
    B1 --> B2
    B2 --> C2
    C2 --> C3
    C3 --> B3
    B3 --> A1
    
    classDef ios fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef cloud fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef analysis fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class A1,A2,A3 ios
    class B1,B2,B3 cloud
    class C1,C2,C3 analysis
```

## 🏗️ Detailed iOS Architecture

### Application Structure
```mermaid
graph TD
    subgraph "🎯 App Layer"
        A1[SageApp.swift<br/>Entry Point]
        A2[ContentView.swift<br/>Tab Navigation]
    end
    
    subgraph "📱 Feature Views"
        B1[WelcomeView<br/>Landing]
        B2[OnboardingJourneyView<br/>Voice Setup]
        B3[SessionsView<br/>Daily Recording]
        B4[VoiceDashboardView<br/>Analysis Results]
        B5[HomeView<br/>Insights]
        B6[SimpleVocalDashboard<br/>Testing UI]
        B7[VocalAnalysisDashboard<br/>Research UI]
    end
    
    subgraph "🔐 Authentication"
        C1[AuthChoiceView<br/>Method Selection]
        C2[SignUpView<br/>Registration]
        C3[LoginView<br/>Sign In]
        C4[AuthViewModel<br/>State Management]
    end
    
    subgraph "🎙️ Voice Recording"
        D1[OnboardingJourneyViewModel<br/>Recording Logic]
        D2[HybridVocalAnalysisService<br/>Analysis Orchestration]
        D3[LocalVoiceAnalyzer<br/>iOS SFVoiceAnalytics]
        D4[CloudVoiceAnalysisService<br/>Upload & Trigger]
        D5[VocalResultsListener<br/>Firestore Updates]
        D6[F0DataService<br/>Legacy F0 Pipeline]
    end
    
    subgraph "📊 Data Models"
        E1[VocalBiomarkers<br/>Clinical Models]
        E2[VoiceRecording<br/>Audio Data]
        E3[UserProfile<br/>User Data]
        E4[Recording<br/>Recording Model]
        E5[OnboardingTypes<br/>Flow Types]
    end
    
    subgraph "🎨 UI Components"
        F1[SageColors<br/>Design System]
        F2[SageTypography<br/>Text Styles]
        F3[SageButton<br/>Interactions]
        F4[SageProgressView<br/>Loading States]
        F5[SageCard<br/>Content Cards]
        F6[SagePercentileBar<br/>Progress Bars]
    end
    
    A1 --> A2
    A2 --> B1
    A2 --> B2
    A2 --> B3
    A2 --> B4
    A2 --> B5
    B1 --> C1
    C1 --> C2
    C1 --> C3
    C2 --> C4
    C3 --> C4
    B2 --> D1
    D1 --> D2
    D2 --> D3
    D2 --> D4
    D2 --> D5
    B3 --> D2
    B4 --> D2
    B4 --> D5
    B6 --> D6
    B7 --> D6
    D2 --> E1
    D2 --> E2
    C4 --> E3
    D1 --> E4
    D1 --> E5
    B1 --> F1
    B1 --> F2
    B1 --> F3
    B2 --> F4
    B4 --> F5
    B4 --> F6
    
    classDef app fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef feature fill:#e3f2fd,stroke:#1976d2,stroke-width:1px
    classDef auth fill:#f3e5f5,stroke:#7b1fa2,stroke-width:1px
    classDef voice fill:#e8f5e8,stroke:#388e3c,stroke-width:1px
    classDef data fill:#fff3e0,stroke:#f57c00,stroke-width:1px
    classDef ui fill:#fce4ec,stroke:#c2185b,stroke-width:1px
    
    class A1,A2 app
    class B1,B2,B3,B4,B5,B6,B7 feature
    class C1,C2,C3,C4 auth
    class D1,D2,D3,D4,D5,D6 voice
    class E1,E2,E3,E4,E5 data
    class F1,F2,F3,F4,F5,F6 ui
```

### Current Directory Structure
```mermaid
graph TD
    subgraph "📁 Sage/"
        A1[App/<br/>Entry Points]
        A2[Domain/<br/>Business Logic]
        A3[Features/<br/>UI Components]
        A4[Infrastructure/<br/>External Services]
        A5[Shared/<br/>Utilities]
        A6[UIComponents/<br/>Design System]
    end
    
    subgraph "🎯 App Layer"
        B1[SageApp.swift]
        B2[ContentView.swift]
    end
    
    subgraph "📊 Domain Layer"
        C1[Models/<br/>VocalBiomarkers]
        C2[Services/<br/>HybridVocalAnalysisService]
        C3[Protocols/<br/>Service Contracts]
    end
    
    subgraph "📱 Features Layer"
        D1[Authentication/<br/>Views & ViewModels]
        D2[Dashboard/<br/>Analysis Results]
        D3[Onboarding/<br/>Voice Setup]
        D4[Sessions/<br/>Recording Interface]
    end
    
    subgraph "🔧 Infrastructure Layer"
        E1[Services/Audio/<br/>Recording & Permissions]
        E2[Services/Auth/<br/>Firebase Auth]
        E3[Services/f0/<br/>F0 Analysis Pipeline]
        E4[Services/Uploading/<br/>Cloud Storage]
        E5[Logging/<br/>StructuredLogger]
    end
    
    A1 --> B1
    A2 --> C1
    A2 --> C2
    A2 --> C3
    A3 --> D1
    A3 --> D2
    A3 --> D3
    A3 --> D4
    A4 --> E1
    A4 --> E2
    A4 --> E3
    A4 --> E4
    A4 --> E5
    A5 --> A1
    A5 --> A2
    A5 --> A3
    A5 --> A4
    A6 --> D1
    A6 --> D2
    A6 --> D3
    A6 --> D4
    
    classDef structure fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef layer fill:#e3f2fd,stroke:#1976d2,stroke-width:1px
    classDef domain fill:#e8f5e8,stroke:#388e3c,stroke-width:1px
    classDef feature fill:#fff3e0,stroke:#f57c00,stroke-width:1px
    classDef infrastructure fill:#fce4ec,stroke:#c2185b,stroke-width:1px
    
    class A1,A2,A3,A4,A5,A6 structure
    class B1,B2 layer
    class C1,C2,C3 domain
    class D1,D2,D3,D4 feature
    class E1,E2,E3,E4,E5 infrastructure
```

### Hybrid Vocal Analysis Service
```mermaid
sequenceDiagram
    participant U as User
    participant S as SessionsView
    participant H as HybridVocalAnalysisService
    participant L as LocalVoiceAnalyzer
    participant C as CloudVoiceAnalysisService
    participant V as VocalResultsListener
    participant F as Firestore
    
    U->>S: Tap Record (5s)
    S->>S: Create VoiceRecording<br/>with userId
    S->>H: analyzeVoice(recording)
    
    Note over H: Phase 1: Local Analysis
    H->>L: analyzeImmediate(audioURL)
    L->>L: SFVoiceAnalytics<br/>F0 extraction only
    L->>H: BasicVoiceMetrics
    H->>S: Immediate Results<br/>(< 5 seconds)
    
    Note over H: Phase 2: Cloud Analysis
    H->>C: uploadAndAnalyze(recording)
    C->>C: Upload to Storage<br/>sage-audio-files/{userId}/{recordingId}.wav
    C->>C: Trigger Cloud Function
    
    Note over F: Cloud Processing
    F->>F: Parselmouth Analysis<br/>F0, Jitter, Shimmer, HNR
    F->>F: Write to recordings/{recordingId}/insights
    F->>F: Write to users/{userId}/voice_analyses/{recordingId}
    
    H->>V: startListening(recordingId)
    V->>F: Listen to users/{userId}/voice_analyses/{recordingId}
    F->>V: VocalBiomarkers update
    V->>H: VocalBiomarkers<br/>(Real-time stream)
    H->>S: Comprehensive Results<br/>(30-60 seconds)
```

## ☁️ Cloud Infrastructure Architecture

### Firebase Cloud Functions
```mermaid
graph TD
    subgraph "🔥 Firebase Ecosystem"
        A1[Cloud Storage<br/>Audio Files]
        A2[Cloud Functions<br/>Processing]
        A3[Firestore<br/>Results DB]
        A4[Authentication<br/>User Management]
    end
    
    subgraph "🎵 Audio Processing Pipeline"
        B1[main.py<br/>Entry Point]
        B2[feature_extraction_pipeline.py<br/>Orchestration]
        B3[feature_extractors/vocal_analysis_extractor.py<br/>Parselmouth Integration]
    end
    
    subgraph "🔬 Feature Extractors"
        C1[F0Analysis<br/>Fundamental Frequency]
        C2[JitterMeasures<br/>Frequency Perturbation]
        C3[ShimmerMeasures<br/>Amplitude Perturbation]
        C4[HNRAnalysis<br/>Harmonics-to-Noise]
    end
    
    subgraph "📊 Clinical Models"
        D1[VoiceQualityLevel<br/>Assessment Categories]
        D2[F0StabilityLevel<br/>Stability Classification]
        D3[ClinicalRecommendation<br/>Action Items]
        D4[StabilityInterpretation<br/>User Guidance]
    end
    
    subgraph "🔧 Services & Utilities"
        E1[entities.py<br/>Data Models]
        E2[services/audio_processing_service.py<br/>Main Processing]
        E3[services/voice_analysis_service.py<br/>Analysis Orchestration]
        E4[utilities/unified_logger.py<br/>Unified Logging]
        E5[utilities/feature_formatter.py<br/>Data Formatting]
        E6[utilities/firebase_utils.py<br/>Firestore Operations]
    end
    
    A1 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> C1
    B3 --> C2
    B3 --> C3
    B3 --> C4
    C1 --> D1
    C2 --> D1
    C3 --> D1
    C4 --> D2
    D1 --> D3
    D2 --> D4
    B1 --> E2
    E2 --> B2
    B2 --> E1
    B2 --> E3
    B3 --> E4
    E6 --> A3
    
    classDef firebase fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef pipeline fill:#e3f2fd,stroke:#1976d2,stroke-width:1px
    classDef extractor fill:#e8f5e8,stroke:#388e3c,stroke-width:1px
    classDef clinical fill:#f3e5f5,stroke:#7b1fa2,stroke-width:1px
    classDef service fill:#fce4ec,stroke:#c2185b,stroke-width:1px
    
    class A1,A2,A3,A4 firebase
    class B1,B2,B3 pipeline
    class C1,C2,C3,C4 extractor
    class D1,D2,D3,D4 clinical
    class E1,E2,E3,E4,E5,E6 service
```

### Data Flow & Storage
```mermaid
flowchart LR
    subgraph "📱 iOS Client"
        A1[Voice Recording<br/>5s sustained vowel]
        A2[Local Analysis<br/>Immediate F0]
        A3[Upload Trigger<br/>Cloud processing]
    end
    
    subgraph "☁️ Cloud Storage"
        B1[sage-audio-files/<br/>{userId}/{recordingId}.wav]
        B2[Storage Trigger<br/>Function invocation]
    end
    
    subgraph "🔬 Analysis Processing"
        C1[Audio Validation<br/>Quality checks]
        C2[Parselmouth Analysis<br/>Research-grade extraction]
        C3[Clinical Assessment<br/>Threshold evaluation]
    end
    
    subgraph "📊 Firestore Structure"
        D1[recordings/{recordingId}/<br/>insights/{insightId}]
        D2[users/{userId}/<br/>voice_analyses/{recordingId}]
        D3[vocal_analysis_f0_mean: 220.5<br/>vocal_analysis_f0_std: 15.2<br/>vocal_analysis_f0_confidence: 88.5]
        D4[vocal_analysis_jitter_local: 0.824<br/>vocal_analysis_jitter_rap: 0.756<br/>vocal_analysis_jitter_ppq5: 0.891]
        D5[vocal_analysis_shimmer_local: 3.245<br/>vocal_analysis_shimmer_apq3: 2.876<br/>vocal_analysis_shimmer_apq5: 3.521]
        D6[vocal_analysis_hnr_mean: 19.2<br/>vocal_analysis_hnr_std: 2.1<br/>vocal_analysis_vocal_stability_score: 82.5]
    end
    
    subgraph "📱 Real-time Updates"
        E1[Firestore Listener<br/>VocalResultsListener]
        E2[UI Update<br/>Dashboard refresh]
        E3[Clinical Interpretation<br/>User-friendly display]
    end
    
    A1 --> A2
    A1 --> A3
    A3 --> B1
    B1 --> B2
    B2 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> D1
    C3 --> D2
    D1 --> D3
    D1 --> D4
    D1 --> D5
    D1 --> D6
    D2 --> D3
    D2 --> D4
    D2 --> D5
    D2 --> D6
    D2 --> E1
    E1 --> E2
    E2 --> E3
    
    classDef client fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef processing fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef database fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef realtime fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    
    class A1,A2,A3 client
    class B1,B2 storage
    class C1,C2,C3 processing
    class D1,D2,D3,D4,D5,D6 database
    class E1,E2,E3 realtime
```

## 🔬 Clinical Voice Analysis Models

### Domain Models Structure
```mermaid
classDiagram
    class VocalBiomarkers {
        +F0Analysis f0
        +VoiceQualityAnalysis voiceQuality
        +VocalStabilityScore stability
        +VoiceAnalysisMetadata metadata
        +ClinicalVoiceAssessment clinicalSummary
    }
    
    class F0Analysis {
        +Double mean
        +Double std
        +Double confidence
        +F0StabilityLevel stabilityLevel
        +isWithinClinicalRange(VoiceDemographic) Bool
    }
    
    class VoiceQualityAnalysis {
        +JitterMeasures jitter
        +ShimmerMeasures shimmer
        +HNRAnalysis hnr
        +VoiceQualityLevel overallQuality
    }
    
    class JitterMeasures {
        +Double local
        +Double absolute
        +Double rap
        +Double ppq5
        +VoiceQualityLevel clinicalAssessment
    }
    
    class ShimmerMeasures {
        +Double local
        +Double db
        +Double apq3
        +Double apq5
        +VoiceQualityLevel clinicalAssessment
    }
    
    class HNRAnalysis {
        +Double mean
        +Double std
        +VoiceQualityLevel clinicalAssessment
    }
    
    class VocalStabilityScore {
        +Double score
        +StabilityComponents components
        +StabilityInterpretation interpretation
    }
    
    class ClinicalVoiceAssessment {
        +VoiceQualityLevel overallQuality
        +F0StabilityLevel f0Stability
        +ClinicalRecommendation recommendedAction
        +String clinicalNotes
    }
    
    VocalBiomarkers --> F0Analysis
    VocalBiomarkers --> VoiceQualityAnalysis
    VocalBiomarkers --> VocalStabilityScore
    VocalBiomarkers --> ClinicalVoiceAssessment
    VoiceQualityAnalysis --> JitterMeasures
    VoiceQualityAnalysis --> ShimmerMeasures
    VoiceQualityAnalysis --> HNRAnalysis
```

### Clinical Thresholds & Classifications
```mermaid
graph TD
    subgraph "🎯 Clinical Thresholds"
        A1[Jitter Local<br/>< 1.04% Excellent<br/>< 2.5% Good<br/>> 2.5% Poor]
        A2[Shimmer Local<br/>< 3.81% Excellent<br/>< 6.5% Good<br/>> 6.5% Poor]
        A3[HNR Mean<br/>> 20dB Excellent<br/>> 15dB Good<br/>< 15dB Poor]
        A4[F0 Stability<br/>> 80% Excellent<br/>> 60% Good<br/>< 60% Poor]
    end
    
    subgraph "📊 Assessment Logic"
        B1[Voice Quality Assessment<br/>Combine all measures]
        B2[Clinical Recommendation<br/>Based on overall quality]
        B3[User Interpretation<br/>Friendly explanations]
    end
    
    subgraph "🎨 UI Display"
        C1[Dashboard Cards<br/>Color-coded results]
        C2[Progress Indicators<br/>Percentile bars]
        C3[Clinical Notes<br/>Actionable insights]
    end
    
    A1 --> B1
    A2 --> B1
    A3 --> B1
    A4 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> C1
    B3 --> C2
    B3 --> C3
    
    classDef threshold fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef assessment fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef display fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    
    class A1,A2,A3,A4 threshold
    class B1,B2,B3 assessment
    class C1,C2,C3 display
```

## 🧪 Testing Architecture

### Test Coverage Map
```mermaid
graph TD
    subgraph "📱 iOS Tests"
        A1[OnboardingTestHarness<br/>Voice recording flow]
        A2[AuthViewModelTests<br/>Authentication logic]
        A3[F0DataServiceTests<br/>Data service integration]
        A4[MockAuthService<br/>Test doubles]
    end
    
    subgraph "☁️ Cloud Function Tests"
        B1[test_feature_extraction_pipeline<br/>End-to-end processing]
        B2[test_vocal_analysis_extractor<br/>Parselmouth integration]
        B3[test_audio_processing_service<br/>Audio processing]
        B4[test_feature_formatter<br/>Data formatting]
    end
    
    subgraph "🔬 Analysis Tests"
        C1[Clinical Threshold Tests<br/>Jitter/Shimmer/HNR validation]
        C2[F0 Accuracy Tests<br/>Known audio samples]
        C3[Error Handling Tests<br/>Invalid audio scenarios]
        C4[Performance Tests<br/>Processing time limits]
    end
    
    subgraph "🎯 Integration Tests"
        D1[End-to-End Flow<br/>iOS → Cloud → Result]
        D2[Real-time Updates<br/>Firestore listeners]
        D3[Authentication Flow<br/>Firebase Auth integration]
        D4[Error Recovery<br/>Network failures]
    end
    
    A1 --> D1
    A2 --> D3
    A3 --> D2
    B1 --> D1
    B2 --> C1
    B2 --> C2
    B3 --> D2
    B4 --> C3
    C1 --> D1
    C2 --> D1
    C3 --> D4
    C4 --> D4
    
    classDef ios fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef cloud fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef analysis fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef integration fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class A1,A2,A3,A4 ios
    class B1,B2,B3,B4 cloud
    class C1,C2,C3,C4 analysis
    class D1,D2,D3,D4 integration
```

## 🎨 UI Architecture & Design System

### Design System Structure
```mermaid
graph TD
    subgraph "🎨 Sage Design System"
        A1[SageColors<br/>CoStar Palette]
        A2[SageTypography<br/>Text Hierarchy]
        A3[SageSpacing<br/>Layout Constants]
        A4[SageButton<br/>Interactive Elements]
    end
    
    subgraph "📊 Specialized Components"
        B1[SagePercentileBar<br/>Progress Indicators]
        B2[SageStylizedCard<br/>Content Containers]
        B3[SageProgressView<br/>Loading States]
        B4[SageInsightCard<br/>Analysis Results]
    end
    
    subgraph "🎙️ Voice-Specific UI"
        C1[WaveformView<br/>Recording Animation]
        C2[CountdownTimerView<br/>Recording Timer]
        C3[ProgressBarView<br/>Analysis Progress]
        C4[VoiceQualityBadge<br/>Clinical Labels]
    end
    
    subgraph "📱 Application Views"
        D1[VoiceDashboardView<br/>Analysis Results]
        D2[SessionsView<br/>Recording Interface]
        D3[OnboardingJourneyView<br/>Setup Flow]
        D4[SimpleVocalDashboard<br/>Testing Interface]
    end
    
    A1 --> B1
    A1 --> B2
    A2 --> B1
    A2 --> B2
    A3 --> B1
    A3 --> B2
    A4 --> C1
    A4 --> C2
    B1 --> D1
    B2 --> D1
    B3 --> D2
    B4 --> D1
    C1 --> D3
    C2 --> D3
    C3 --> D2
    C4 --> D1
    
    classDef design fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef component fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef voice fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef application fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    
    class A1,A2,A3,A4 design
    class B1,B2,B3,B4 component
    class C1,C2,C3,C4 voice
    class D1,D2,D3,D4 application
```

## 🔄 User Journey Flow

### Complete User Experience
```mermaid
journey
    title Sage Voice Analysis User Journey
    
    section Discovery & Setup
        Welcome Screen: 5: User
        Choose Signup Method: 4: User
        Create Account: 3: User, Firebase
        Explain Voice Testing: 5: User
    
    section Onboarding Voice Test
        Record Sustained Vowel: 4: User, iOS
        Local Analysis (< 5s): 5: iOS, SFVoiceAnalytics
        Show Immediate Results: 5: User, iOS
        Cloud Processing (30-60s): 3: Cloud, Parselmouth
        Complete Onboarding: 5: User
    
    section Daily Usage
        Navigate to Sessions: 5: User
        Record Daily Sample: 4: User, iOS
        View Immediate F0: 5: User, iOS
        Receive Comprehensive Results: 5: User, Cloud
        Check Dashboard: 5: User, iOS
    
    section Clinical Insights
        View Voice Quality: 5: User
        Understand Jitter/Shimmer: 4: User
        Read Clinical Assessment: 5: User
        Track Patterns: 4: User
```

## 📈 Performance & Scalability

### Analysis Performance Metrics
```mermaid
graph LR
    subgraph "⚡ Performance Targets"
        A1[Local Analysis<br/>< 5 seconds<br/>SFVoiceAnalytics]
        A2[Cloud Upload<br/>< 10 seconds<br/>Firebase Storage]
        A3[Cloud Processing<br/>30-60 seconds<br/>Parselmouth]
        A4[Real-time Updates<br/>< 2 seconds<br/>Firestore Listener]
    end
    
    subgraph "📊 Quality Metrics"  
        B1[F0 Accuracy<br/>> 95% correlation<br/>with Praat reference]
        B2[Clinical Precision<br/>3 decimal places<br/>Research-grade]
        B3[Audio Quality Check<br/>Minimum duration<br/>Noise validation]
        B4[Error Rate<br/>< 1% processing failures<br/>Robust error handling]
    end
    
    subgraph "🔄 Scalability"
        C1[Concurrent Users<br/>1000+ simultaneous<br/>Firebase autoscaling]
        C2[Daily Recordings<br/>10,000+ per day<br/>Cloud Functions]
        C3[Storage Growth<br/>1TB+ audio files<br/>Cost optimization]
        C4[Database Queries<br/>Sub-second response<br/>Firestore indexing]
    end
    
    A1 --> B1
    A2 --> B2
    A3 --> B3
    A4 --> B4
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
    
    classDef performance fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef quality fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef scalability fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    
    class A1,A2,A3,A4 performance
    class B1,B2,B3,B4 quality
    class C1,C2,C3,C4 scalability
```

## 🔧 Development & Deployment

### Development Workflow
```mermaid
gitgraph
    commit id: "Initial Architecture"
    branch feature/hybrid-analysis
    checkout feature/hybrid-analysis
    commit id: "Local Voice Analyzer"
    commit id: "Cloud Service Integration"
    commit id: "Firestore Listeners"
    checkout main
    merge feature/hybrid-analysis
    commit id: "v1.0 Release"
    
    branch feature/clinical-models
    checkout feature/clinical-models
    commit id: "VocalBiomarkers Models"
    commit id: "Clinical Thresholds"
    commit id: "Assessment Logic"
    checkout main
    merge feature/clinical-models
    commit id: "v1.1 Clinical Update"
    
    branch feature/ui-polish
    checkout feature/ui-polish
    commit id: "Dashboard Redesign"
    commit id: "Real-time Updates"
    commit id: "Error Handling"
    checkout main
    merge feature/ui-polish
    commit id: "v1.2 UI Polish"
```

## 📚 Legend & Conventions

### Component Types
| Symbol | Component Type | Description |
|--------|---------------|-------------|
| 📱 | iOS Native | Swift UI components, iOS-specific code |
| ☁️ | Cloud Functions | Python serverless functions |
| 🔥 | Firebase Services | Authentication, Storage, Firestore |
| 🔬 | Analysis Engine | Voice processing algorithms |
| 🎨 | UI Components | Design system elements |
| 📊 | Data Models | Domain objects and entities |
| 🧪 | Testing | Unit, integration, and E2E tests |
| 🎯 | Clinical Logic | Medical/research-grade assessments |

### Color Coding
- **Blue (#1976d2)**: iOS app components and UI
- **Green (#388e3c)**: Services, cloud functions, and processing
- **Orange (#f57c00)**: Data models, utilities, and storage
- **Purple (#7b1fa2)**: Authentication, view models, and business logic  
- **Red (#d32f2f)**: Entry points and critical paths
- **Pink (#c2185b)**: UI components and design system

### Naming Conventions
- **Files**: PascalCase for Swift, snake_case for Python
- **Classes**: Descriptive names with responsibility suffix (Service, Manager, Extractor)
- **Methods**: Verb-first naming (analyzeVoice, validateAudio, processResults)
- **Constants**: ALL_CAPS for configuration, camelCase for UI constants

## 🔄 Maintenance Guidelines

### When to Update This Document
1. **Adding new features**: New voice analysis capabilities (formants, prosody)
2. **Architecture changes**: New services, different data flow patterns
3. **Performance optimizations**: Caching layers, processing improvements
4. **Clinical updates**: New assessment criteria, threshold changes
5. **UI redesigns**: Major interface changes, new component patterns

### How to Update
1. **Edit in Cursor**: Use built-in Markdown preview for real-time visualization
2. **Test diagrams**: Ensure Mermaid syntax is valid before committing
3. **Update incrementally**: Small, focused changes with clear commit messages
4. **Validate completeness**: Ensure all new components are represented
5. **Review with team**: Architecture changes should be reviewed by technical leads

### Mermaid Tips
- Use `graph TD` for top-down hierarchical views
- Use `flowchart LR` for process flows and data pipelines  
- Use `sequenceDiagram` for interaction patterns
- Use `classDiagram` for data model relationships
- Keep diagrams focused - split complex systems into multiple views
- Use consistent color coding and naming conventions

## ✅ Implementation Status

### Current Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| LocalVoiceAnalyzer | ✅ Complete | Working iOS analysis with SFVoiceAnalytics |
| HybridVocalAnalysisService | ✅ Complete | Full orchestration of local + cloud analysis |
| CloudVoiceAnalysisService | ✅ Complete | Comprehensive upload with retry logic |
| VocalResultsListener | ✅ Complete | Firestore real-time updates working |
| F0DataService | ✅ Complete | Legacy pipeline functional |
| Cloud Functions Pipeline | ✅ Complete | Parselmouth analysis working |
| VocalBiomarkers Models | ✅ Complete | Domain models implemented |
| Domain-Driven Architecture | ✅ Complete | Clean separation of concerns |

### Recent Architectural Improvements

#### ✅ Completed Refactoring
- **Domain Layer**: Clean separation of business logic and models
- **Infrastructure Layer**: Organized services with clear boundaries  
- **Features Layer**: UI components with proper ViewModels and Views separation
- **Shared Utilities**: Common functionality and logging infrastructure
- **Enhanced Testing**: Reorganized test structure matching new architecture
- **Cloud Functions**: Modular Python backend with comprehensive feature extraction
- **Unified Logging**: StructuredLogger for iOS and UnifiedLogger for cloud functions

#### 🎯 Key Achievements
- **129 files** moved, created, or modified
- **13,326 lines** of new/improved code
- **Clean architecture** following domain-driven design principles
- **Comprehensive error handling** and logging throughout
- **Enhanced testability** with protocol-based dependencies
- **Real-time updates** via Firestore listeners
- **Dual Firestore writes** for compatibility with both recordings and users collections

#### 🔄 Latest Pipeline Fixes (January 2025)
- **Upload Path Update**: Changed from `sage-audio-files/{recordingId}.wav` to `sage-audio-files/{userId}/{recordingId}.wav`
- **User ID Correlation**: Sessions now use authenticated Firebase user ID instead of fake session IDs
- **Cloud Function Enhancement**: Added user_id extraction from file paths and dual Firestore writes
- **Memory Optimization**: Increased cloud function memory from 256MB to 512MB
- **Dashboard Integration**: VoiceDashboardView now queries both real-time and historical analysis results

### Architectural Principles

1. **Single Responsibility**: Each service has one clear purpose
2. **Error Handling**: All async operations have proper error boundaries
3. **Real-time Updates**: UI receives progressive updates during analysis
4. **Testability**: All services are protocol-based for easy testing
5. **Logging**: Comprehensive structured logging for debugging
6. **Domain-Driven Design**: Clear separation between domain, infrastructure, and features

### Key Architectural Decisions

1. **Hybrid Analysis Approach**
   - Local iOS analysis for immediate feedback (< 5 seconds)
   - Cloud analysis for comprehensive research-grade features (30-60 seconds)
   - Progressive UI updates as results become available

2. **Dual Firestore Write Strategy**
   - Primary: `recordings/{recordingId}/insights/` for canonical data
   - Secondary: `users/{userId}/voice_analyses/{recordingId}` for user-centric queries
   - Ensures backward compatibility and efficient querying

3. **Structured Logging Architecture**
   - iOS: StructuredLogger with LogContext and OperationLogger
   - Cloud: UnifiedLogger with correlation IDs and performance metrics
   - Recording ID correlation throughout the pipeline

4. **Clean Domain Architecture**
   - Domain layer: Pure business logic and models
   - Infrastructure layer: External service integrations
   - Features layer: UI components with ViewModels
   - Shared layer: Cross-cutting concerns

5. **Voice Analysis Pipeline**
   - Quality gates: Duration, RMS, and voiced frame validation
   - Clinical thresholds: Research-grade assessment criteria
   - Error resilience: Graceful degradation with partial results

---

**Maintainers**: This architecture document reflects the current implementation after major refactoring. The system now follows clean domain-driven design principles with proper separation of concerns, improved testability, and better maintainability.