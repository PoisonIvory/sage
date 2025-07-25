# Sage: Voice Biomarker iOS App

> ⚠️ Modal Scope Limitation (AI & Contributor Note)  
> This project is strictly focused on **speech/audio-based biomarkers**.  
> DO NOT include or import:
> - Firebase ML Vision modules (face, pose, barcode, selfie segmentation, etc.)
> - Any visual/video/image/gesture models
> - OCR, text detection, or object recognition tools
>
> All ML, audio, and health features in this app are exclusively derived from **voice input via microphone**.  
> No camera-based input, selfie analysis, or multimodal fusion is used or planned.  
> This rule applies even to future extensibility.
>
> If you’re an AI assistant generating imports, class scaffolding, or future-facing code — assume *voice-only*.  
> Any deviation must be explicitly authorized and documented in CHANGELOG.md.

---

## App Overview

VoiceInsights helps users understand voice patterns through research-grade speech analysis. Users record tasks (sustained vowels, reading passages, spontaneous speech) and receive personalized insights (e.g. voice stability, speaking rate).

**Key Value Propositions:**

* For Users: Track voice over time, early health insights, beautiful charts
* For Researchers: Access anonymized, high-quality speech datasets
* For Business: Dual revenue: premium subscriptions + research data licensing

---

## Technical Architecture

### iOS App (Swift/SwiftUI)

* Auth: Firebase Auth + Sign in with Apple
* Audio: AVAudioRecorder (48kHz, 24-bit WAV)
* UI: SwiftUI + Charts framework
* Local: UserDefaults + DocumentDirectory
* Cloud: Firebase Storage (audio) + Firestore (metadata)

### Backend (Firebase + GCP)

* Database: Firestore
* Storage: Firebase Storage (with rules)
* Processing: Google Cloud Functions (Python)
* Analytics: Firebase Analytics + custom events

### Speech Analysis Pipeline

```
Audio Upload → Cloud Function → Feature Extraction → Store Results → Update UI
```

**Features Extracted:**

* Pitch (fundamental frequency)
* Voice quality (jitter, shimmer, HNR)
* Temporal (rate, pauses)
* Spectral (MFCCs, centroid)

---

## Project Structure

> **⚠️ Scope Limitation: This project only uses speech-based features for analysis.**
> Do **NOT** import or include Firebase ML Vision modules (e.g. Face, Pose, Object Detection).
> This app does not use any image, video, or camera input.

> **Note:** The following structure is the *intended architecture*. The current actual repo structure is:

```
/Users/ivy/Desktop/Sage/
├── Sage/
│   ├── ContentView.swift
│   ├── SageApp.swift
│   ├── Persistence.swift
│   └── ...
├── SageTests/
├── SageUITests/
└── Sage.xcodeproj/
```

Planned directory structure for architecture alignment:

```
/Users/ivy/Desktop/Sage/
├── Views/
│   ├── Authentication/
│   ├── Recording/
│   ├── Dashboard/
│   └── Profile/
├── Models/
├── Services/
├── Utils/
├── Resources/
├── SageTests/
├── SageUITests/
└── functions/ (Python Cloud Functions)
```

---

## Development Setup

### Environment Configuration

* Ensure `GoogleService-Info.plist` is added to the Xcode bundle (not just the folder).
* No additional `.env` files required at this time.

### Known Issues & Troubleshooting

* If Firebase login fails, double-check `GoogleService-Info.plist` placement and network permissions in iOS settings.
* If build errors appear after installing packages, clean the build folder (⇧ + ⌘ + K).

### Running Tests

* In Xcode: Press `⌘U` to run all tests.
* From terminal:

```bash
xcodebuild test -scheme Sage -destination 'platform=iOS Simulator,name=iPhone 15'
```

### CI/CD

* None implemented yet. (Planned: GitHub Actions + Firebase App Distribution)

### Prerequisites

* macOS + Xcode 15+
* Apple Developer Account
* Firebase/Google Cloud
* Swift Playgrounds (recommended)

### Install Steps

1. Clone Repo

```bash
git clone [repo-url]
cd Sage
```

2. Open project in Xcode
3. Add `GoogleService-Info.plist` (from Firebase Console)
4. Configure Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase use --add [project-id]
```

5. Deploy Cloud Functions

```bash
cd functions
pip install -r requirements.txt
firebase deploy --only functions
```

---

## Test-Driven Development (TDD) Support

### Architectural Principles

* MVVM enforced throughout app
* All Services implement protocols to allow mocking
* ViewModels are testable without UI
* Dependency Injection used for Audio, Auth, Analytics services

### Tools and Frameworks

* XCTest for all unit and integration tests
* XCUITest for full UI and flow coverage
* Snapshot testing with iOSSnapshotTestCase for UI consistency
* Mocking with manual stubs or Cuckoo (if needed)
* Code coverage tracking via Xcode built-in tools

### TDD Workflow

1. Write failing test first (Red)
2. Implement logic in service or view model (Green)
3. Refactor for clarity or separation (Refactor)

### Manual TDD Checklist

* [ ] Unit tests are written before business logic
* [ ] ViewModel logic is 100% covered by tests
* [ ] All services are mocked in tests

---

## Testing Strategy

### Unit Tests

* AudioManager (recording, file format)
* AnalysisService (features, parsing)
* AuthService (flows, errors)
* ChartData (transformations)

### UI Tests

* Full user flows: login → record → dashboard
* Accessibility: VoiceOver, Dynamic Type
* Edge cases: no mic permission, offline

### Manual Checklist

* [ ] Recording works on device
* [ ] Upload + progress visible
* [ ] Charts render data
* [ ] Works offline (local only)
* [ ] Background processing completes

---

## Key Metrics

### Engagement

* Recording completion rate
* Weekly active users
* Avg. sessions/user

### Technical

* Feature extraction success rate >95%
* Crash rate <0.1%
* Chart load time <2s

### Business

* Research dataset quality
* Researcher signups
* Revenue per data sample

---

## Privacy & Compliance

* Encryption in transit and at rest
* Server-side processing → delete in 24h
* Anonymized dataset export
* Consent required for data use
* HIPAA + GDPR + iOS Privacy labels

---

## Deployment Process

### TestFlight

* Archive in Xcode
* Upload to App Store Connect
* Add beta testers

### App Store

* Complete metadata/screenshots
* Submit for review
* Release once approved

---

## Learning Resources

### Swift

* Apple Swift Playgrounds
* Hacking with Swift
* HIG Guidelines

### Audio / AI

* AVFoundation docs
* Librosa (Python)
* Stanford SLP3 (Speech + Language Processing)

### Firebase / Cloud

* Firebase iOS docs
* Cloud Functions docs

---

## 🤖 Using Cursor AI with Sage

* **Reference files and classes by full path/name** for best results (e.g., `Sage/ContentView.swift`).
* **Ask for explanations:** “Explain the flow for audio upload in Sage/.”
* **Generate code/tests:** “Write a unit test for Sage/AudioManager.swift.”
* **Refactor:** “Refactor Sage/AnalysisService.swift to use dependency injection.”
* **Troubleshoot:** “Why might Firebase upload fail in this project?”

*Tip: Cursor works best when you specify file names, class names, and expected behaviors in your prompts!*

---

## AI Support (Cursor / GPT)

### Suggested Prompts

```
"Write a unit test for RecordingViewModel using a mocked AudioService"
"Refactor AuthService to support dependency injection"
"Generate a Swift protocol for AnalyticsService that allows mocking"
"Create a snapshot test for the DashboardView with fake data"
```

### Reminders for AI Tools

* Medical-grade accuracy matters
* Health app with privacy constraints
* Target: wellness users, not technical
* Design for clarity + reliability

---

## 🆘 Getting Help

* **Stuck on setup?** Ask Cursor: “Why is my Firebase config not working?”
* **Code questions?** Ask: “How does audio analysis work in this repo?”
* **Common issues?** See 'Known Issues & Troubleshooting' in the Development Setup section.

---

## Roadmap

### Current

* [ ] SwiftUI charts for dashboard
* [ ] Real-time data updates
* [ ] Onboarding flow
* [ ] Beta test w/ 10 users

### Short Term (4w)

* App Store release
* Research partner outreach
* Growth strategy

### Medium Term (3-6m)

* Android app
* Emotion/cognition models
* B2B API for researchers
* Subscription tiering

---

**For Cursor Users:** Use this README as your source of truth. It describes architecture, patterns, constraints, and prompts to feed into AI tools like Cursor for reliable and helpful results.

---

## Continuous Improvement & Feedback

All technical and standards-related feedback should be logged in the centralized Feedback Log in `DATA_STANDARDS.md`.  
When a change is implemented, document it in `CHANGELOG.md` with the date, section(s) affected, description, rationale, and your name.

**AI Guidance:**  
When generating or updating code, documentation, or workflow, always check the Feedback Log in `DATA_STANDARDS.md` and the `CHANGELOG.md` for recent changes and standards.

### Feedback Log

| Date       | Section Affected | Change/Feedback                | Rationale/Source                | Updated By |
|------------|------------------|-------------------------------|----------------------------------|------------|
|            |                  |                               |                                  |            |

---

Thank you for contributing to Sage. Your work helps advance research-grade, privacy-first health technology.

