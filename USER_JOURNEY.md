# Sage User Journey Documentation

This document provides a comprehensive visual overview of all user journeys through the Sage voice analysis platform. It maps the actual implemented flows, view transitions, and user interactions to help developers and stakeholders understand the complete user experience.

**Document Status**: This document reflects the actual implementation as of January 2025. All flows, views, and interactions are based on the current codebase.

## App Entry Point & Authentication Flow

### Main App Navigation Structure
```mermaid
graph TD
    A[SageApp.swift<br/>Entry Point] --> B{User Authenticated?}
    B -->|No| C[WelcomeView<br/>Landing Screen]
    B -->|Yes| D{Onboarding Complete?}
    D -->|No| E[OnboardingJourneyView<br/>Voice Setup Flow]
    D -->|Yes| F[ContentView<br/>Main App with Tabs]
    
    C --> G[SignUpView<br/>Registration]
    C --> H[LoginView<br/>Sign In]
    C --> I[ContentView<br/>Browse Mode]
    
    G --> J{Authentication Success?}
    H --> J
    J -->|Yes| D
    J -->|No| C
    
    E --> F
    F --> K[HomeView<br/>Today's Analysis]
    F --> L[SessionsView<br/>Recording Interface]
    F --> M[VoiceDashboardView<br/>Longitudinal Trends]
    F --> N[ProfilePagePlaceholderView<br/>User Profile]
    
    classDef entry fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef auth fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef onboarding fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef main fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class A entry
    class B,C,G,H,I,J auth
    class D,E onboarding
    class F,K,L,M,N main
```

## Authentication Journey

### Sign Up Flow
```mermaid
sequenceDiagram
    participant U as User
    participant W as WelcomeView
    participant S as SignUpView
    participant A as AuthViewModel
    participant F as Firebase Auth
    participant O as OnboardingJourneyView
    
    U->>W: Tap "Get Started"
    W->>S: Navigate to SignUpView
    U->>S: Enter email & password
    S->>A: signUp(email, password)
    A->>F: Create user account
    F->>A: Success/Error response
    A->>S: Update UI state
    
    alt Authentication Success
        S->>O: Navigate to Onboarding
        O->>O: Start voice baseline setup
    else Authentication Failed
        S->>S: Show error message
        U->>S: Retry or go back
    end
```

### Login Flow
```mermaid
sequenceDiagram
    participant U as User
    participant W as WelcomeView
    participant L as LoginView
    participant A as AuthViewModel
    participant F as Firebase Auth
    participant O as OnboardingJourneyView
    
    U->>W: Tap "Sign In"
    W->>L: Navigate to LoginView
    U->>L: Enter credentials
    L->>A: signIn(email, password)
    A->>F: Authenticate user
    F->>A: Success/Error response
    A->>L: Update UI state
    
    alt Authentication Success
        L->>O: Navigate to Onboarding (if needed)
        O->>O: Start voice baseline setup
    else Authentication Failed
        L->>L: Show error message
        U->>L: Retry or go back
    end
```

## Onboarding Journey

### Complete Onboarding Flow
```mermaid
graph TD
    A[OnboardingJourneyView<br/>Entry Point] --> B[SignupMethodView<br/>Choose Signup Method]
    B --> C{User Selection}
    C -->|Anonymous| D[UserInfoFormView<br/>Basic Profile]
    C -->|Email| E[SignUpView<br/>Email Registration]
    
    D --> F[VoiceHeroView<br/>Voice Test Explanation]
    E --> F
    
    F --> G[OnboardingJourneyView<br/>Sustained Vowel Test]
    G --> H{Recording Quality}
    H -->|Good| I[OnboardingJourneyView<br/>Reading Prompt]
    H -->|Poor| G
    
    I --> J[OnboardingJourneyView<br/>Final Step]
    J --> K{Baseline Established?}
    K -->|Yes| L[ContentView<br/>Main App]
    K -->|No| M[Wait for Cloud Analysis]
    M --> L
    
    classDef step fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef decision fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef recording fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef completion fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class A,B,D,E,F,I,J step
    class C,H,K decision
    class G,M recording
    class L completion
```

### Voice Recording Process
```mermaid
sequenceDiagram
    participant U as User
    participant O as OnboardingJourneyView
    participant R as AudioRecorder
    participant L as LocalVoiceAnalyzer
    participant C as CloudVoiceAnalysisService
    participant F as Firestore
    
    U->>O: Tap "Start Recording"
    O->>R: Start 10-second recording
    R->>O: Recording in progress
    O->>O: Show countdown timer
    
    R->>O: Recording complete
    O->>L: Analyze locally (F0)
    L->>O: Immediate F0 feedback
    
    O->>C: Upload to cloud
    C->>C: Process with Parselmouth
    C->>F: Store comprehensive results
    F->>O: Real-time updates via listener
    
    O->>O: Show comprehensive analysis
    O->>O: Establish baseline (if ready)
```

## Main App Journey

### Tab Navigation Structure
```mermaid
graph TD
    A[ContentView<br/>Tab Container] --> B[HomeView<br/>Today's Voice Analysis]
    A --> C[SessionsView<br/>Recording Interface]
    A --> D[VoiceDashboardView<br/>Longitudinal Trends]
    A --> E[ProfilePagePlaceholderView<br/>User Profile]
    
    B --> F[VocalAnalysisDashboard<br/>Research UI]
    B --> G[SimpleVocalDashboard<br/>Testing UI]
    
    C --> H[RecordingCard<br/>Individual Sessions]
    C --> I[PoeticSessionsEmptyState<br/>No Sessions]
    
    classDef tab fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef view fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef state fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class A tab
    class B,C,D,E view
    class F,G,H,I state
```

### Home View Journey
```mermaid
graph TD
    A[HomeView<br/>Entry Point] --> B{Has Recent Analysis?}
    B -->|Yes| C[Show Today's Results<br/>F0, Jitter, Shimmer, HNR]
    B -->|No| D[Show Empty State<br/>"Record your voice today"]
    
    C --> E[VocalAnalysisDashboard<br/>Research Interface]
    C --> F[SimpleVocalDashboard<br/>Testing Interface]
    
    E --> G[Show Percentile Bars<br/>Voice Quality Metrics]
    E --> H[Show Clinical Assessment<br/>Stability Score]
    
    F --> I[Show Basic Metrics<br/>F0, Quality Score]
    
    classDef home fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef content fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef display fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class A home
    class B,C,D content
    class E,F,G,H,I display
```

### Sessions View Journey
```mermaid
graph TD
    A[SessionsView<br/>Entry Point] --> B{Has Recordings?}
    B -->|Yes| C[Show Recording Cards<br/>List of past sessions]
    B -->|No| D[PoeticSessionsEmptyState<br/>"Start your voice journey"]
    
    C --> E[RecordingCard<br/>Individual Session]
    E --> F[Show Session Details<br/>Date, Duration, Quality]
    E --> G[Show Analysis Results<br/>F0, Jitter, Shimmer, HNR]
    
    A --> H[Tap Record Button]
    H --> I[Start New Recording<br/>5-second sustained vowel]
    I --> J[Local Analysis<br/>Immediate F0 feedback]
    I --> K[Cloud Upload<br/>Comprehensive analysis]
    K --> L[Real-time Updates<br/>Via Firestore listener]
    L --> C
    
    classDef sessions fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef content fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef recording fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class A sessions
    class B,C,D,E,F,G content
    class H,I,J,K,L recording
```

## Error Handling & Edge Cases

### Authentication Error Flow
```mermaid
graph TD
    A[Authentication Attempt] --> B{Success?}
    B -->|Yes| C[Proceed to Onboarding/App]
    B -->|No| D[Show Error Message]
    
    D --> E{Error Type}
    E -->|Invalid Credentials| F[Show "Invalid email or password"]
    E -->|Network Error| G[Show "Check internet connection"]
    E -->|Email in Use| H[Show "Email already registered"]
    E -->|Unknown| I[Show "Unexpected error occurred"]
    
    F --> J[User Retry]
    G --> J
    H --> J
    I --> J
    
    J --> A
    
    classDef error fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef retry fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class D,E,F,G,H,I error
    class J retry
```

### Recording Quality Gate Flow
```mermaid
graph TD
    A[Start Recording] --> B[Audio Capture]
    B --> C[RMS Signal Analysis]
    C --> D{Quality Gate}
    
    D -->|Pass| E[Proceed with Analysis]
    D -->|Fail| F[Show Quality Error]
    
    F --> G[User Retry]
    G --> A
    
    E --> H[Local Analysis]
    E --> I[Cloud Upload]
    
    H --> J[Immediate Feedback]
    I --> K[Comprehensive Results]
    
    classDef quality fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef error fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef analysis fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class A,B,C quality
    class D,F,G error
    class E,H,I,J,K analysis
```

## User State Management

### Authentication State Flow
```mermaid
stateDiagram-v2
    [*] --> Unauthenticated
    Unauthenticated --> WelcomeView
    WelcomeView --> SignUpView
    WelcomeView --> LoginView
    WelcomeView --> BrowseMode
    
    SignUpView --> Authenticated
    LoginView --> Authenticated
    
    Authenticated --> OnboardingJourneyView
    Authenticated --> ContentView
    
    OnboardingJourneyView --> ContentView
    
    ContentView --> Unauthenticated : Logout
    BrowseMode --> Unauthenticated : Logout
    
    state Authenticated {
        [*] --> CheckingOnboarding
        CheckingOnboarding --> OnboardingNeeded
        CheckingOnboarding --> OnboardingComplete
        OnboardingNeeded --> OnboardingJourneyView
        OnboardingComplete --> ContentView
    }
```

### Onboarding State Flow
```mermaid
stateDiagram-v2
    [*] --> SignupMethod
    SignupMethod --> Explainer
    Explainer --> SustainedVowelTest
    SustainedVowelTest --> ReadingPrompt
    ReadingPrompt --> FinalStep
    FinalStep --> Completed
    
    SustainedVowelTest --> SustainedVowelTest : Retry recording
    FinalStep --> Completed : Baseline established
    
    state SustainedVowelTest {
        [*] --> Recording
        Recording --> Processing
        Processing --> QualityCheck
        QualityCheck --> Success
        QualityCheck --> Failed
        Failed --> Recording : Retry
        Success --> [*]
    }
```

## View Hierarchy & Navigation

### Complete View Hierarchy
```mermaid
graph TD
    subgraph "App Entry"
        A[SageApp.swift]
    end
    
    subgraph "Authentication Views"
        B[WelcomeView]
        C[SignUpView]
        D[LoginView]
        E[AuthChoiceView]
    end
    
    subgraph "Onboarding Views"
        F[OnboardingJourneyView]
        G[SignupMethodView]
        H[UserInfoFormView]
        I[VoiceHeroView]
    end
    
    subgraph "Main App Views"
        J[ContentView]
        K[HomeView]
        L[SessionsView]
        M[VoiceDashboardView]
        N[ProfilePagePlaceholderView]
    end
    
    subgraph "Specialized Views"
        O[VocalAnalysisDashboard]
        P[SimpleVocalDashboard]
        Q[RecordingCard]
        R[PoeticSessionsEmptyState]
    end
    
    A --> B
    A --> C
    A --> D
    A --> F
    
    B --> C
    B --> D
    B --> J
    
    C --> F
    D --> F
    
    F --> J
    J --> K
    J --> L
    J --> M
    J --> N
    
    K --> O
    K --> P
    L --> Q
    L --> R
    
    classDef entry fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef auth fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef onboarding fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef main fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef specialized fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class A entry
    class B,C,D,E auth
    class F,G,H,I onboarding
    class J,K,L,M,N main
    class O,P,Q,R specialized
```

## Data Flow & State Management

### User Data Flow
```mermaid
graph LR
    subgraph "User Input"
        A[Email/Password]
        B[Age/Gender]
        C[Voice Recording]
    end
    
    subgraph "Authentication"
        D[Firebase Auth]
        E[User Profile]
    end
    
    subgraph "Voice Analysis"
        F[Local Analysis]
        G[Cloud Analysis]
        H[Baseline Establishment]
    end
    
    subgraph "Storage"
        I[Firestore]
        J[Firebase Storage]
        K[UserDefaults]
    end
    
    A --> D
    B --> E
    C --> F
    C --> G
    
    D --> I
    E --> I
    F --> I
    G --> I
    C --> J
    H --> K
    
    classDef input fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef process fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class A,B,C input
    class D,E,F,G,H process
    class I,J,K storage
```

## Performance & User Experience

### Loading States & Feedback
```mermaid
graph TD
    A[User Action] --> B{Requires Network?}
    B -->|Yes| C[Show Loading Indicator]
    B -->|No| D[Immediate Response]
    
    C --> E[Network Request]
    E --> F{Success?}
    F -->|Yes| G[Show Success State]
    F -->|No| H[Show Error State]
    
    D --> I[Update UI]
    G --> I
    H --> J[Show Retry Option]
    J --> A
    
    classDef loading fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef success fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef error fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    
    class C,E loading
    class G,I success
    class H,J error
```

## Testing & Validation

### User Journey Testing
```mermaid
graph TD
    A[Test Setup] --> B[Launch App]
    B --> C[Authentication Flow]
    C --> D[Onboarding Flow]
    D --> E[Main App Flow]
    E --> F[Recording Flow]
    F --> G[Analysis Flow]
    G --> H[Results Display]
    
    C --> I[Test Error Cases]
    D --> J[Test Quality Gates]
    E --> K[Test Tab Navigation]
    F --> L[Test Real-time Updates]
    
    classDef test fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef validation fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class A,B,C,D,E,F,G,H test
    class I,J,K,L validation
```

## Legend & Conventions

### View Types
| Symbol | View Type | Description |
|--------|-----------|-------------|
| 📱 | iOS Native | SwiftUI views and components |
| 🔐 | Authentication | Login, signup, and auth flows |
| 🎤 | Voice Recording | Audio capture and analysis |
| 📊 | Data Display | Results, charts, and metrics |
| ⚙️ | Settings | Configuration and preferences |

### Flow Types
| Symbol | Flow Type | Description |
|--------|-----------|-------------|
| ➡️ | Navigation | Screen transitions and routing |
| 🔄 | State Change | Data updates and UI refreshes |
| ⚡ | Real-time | Live updates and listeners |
| ❌ | Error Handling | Error states and recovery |

### Color Coding
- **Blue (#1976d2)**: Authentication and navigation flows
- **Green (#388e3c)**: Voice analysis and recording flows
- **Orange (#f57c00)**: Data display and results flows
- **Red (#d32f2f)**: Error states and edge cases
- **Purple (#7b1fa2)**: Settings and configuration flows

## Maintenance Guidelines

### When to Update This Document
1. **New user flows**: Adding new screens or navigation paths
2. **View changes**: Modifying existing view hierarchies
3. **State management**: Changes to authentication or data flow
4. **Error handling**: New error states or recovery flows
5. **Performance**: Loading states or user feedback changes

### How to Update
1. **Update diagrams**: Ensure Mermaid syntax is valid
2. **Test flows**: Verify navigation paths are accurate
3. **Document changes**: Add notes for significant updates
4. **Review with team**: Ensure all flows are represented
5. **Validate completeness**: Check that all views are included

### Mermaid Tips
- Use `graph TD` for top-down flow diagrams
- Use `sequenceDiagram` for interaction patterns
- Use `stateDiagram-v2` for state management
- Keep diagrams focused and readable
- Use consistent naming and color coding

---

**Maintainers**: This user journey document reflects the actual implementation and should be updated whenever user flows change. All diagrams are based on the current codebase and represent real user experiences. 