# AI Prompt Cookbook

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

## Audio Analysis

- "Implement jitter extraction in AnalysisService.swift according to the parameters in DATA_STANDARDS.md section 3.1, using AVAudioPCMBuffer. Add code comments referencing the relevant research in RESOURCES.md."
- "Write a Swift class named AudioRecorder in Sage/ that records audio at 48kHz, 24-bit WAV using AVAudioRecorder, following the requirements in DATA_STANDARDS.md section 2."
- "Refactor the pitch extraction pipeline in AnalysisService.swift to normalize pitch values across sessions, referencing the normalization method described in RESOURCES.md (Smith et al., 2022). Add a code comment with the citation."
- "Add code comments to shimmer extraction referencing the peer-reviewed method in RESOURCES.md."

---

## Testing and Test-Driven Development (TDD)

- "Generate unit tests for the shimmer extractor in AnalysisService.swift using controlled noise input, ensuring all edge cases are covered and referencing DATA_STANDARDS.md section 4. Add comments explaining how each test case relates to the standard."
- "Write an XCUITest for the end-to-end flow from audio recording to dashboard insight display, ensuring all UI elements are accessible and tested on at least two simulators. Reference the relevant user flow in README.md."
- "Create a test for MFCC extraction in AnalysisService.swift that validates output against the OpenSMILE reference in reference_data/. Add a comment referencing the OpenSMILE configuration in RESOURCES.md."

---

## Research Citations and Documentation

- "Summarize the findings from Navas et al. (2021) on jitter and depression, and add a summary to RESOURCES.md. When generating code that uses jitter as a feature, cite this summary in code comments."
- "Explain why MFCCs are used as voice feature vectors in clinical research, referencing DATA_STANDARDS.md and RESOURCES.md. Add this explanation as a docstring in the relevant function."
- "Document the feature extraction pipeline in AnalysisService.swift, including references to DATA_STANDARDS.md section 3 and the relevant research papers in RESOURCES.md."

---

## Troubleshooting and Debugging

- "List possible causes and solutions for Firebase upload failures in AudioService.swift, referencing the current implementation and DATA_STANDARDS.md. Add inline comments for each solution."
- "Explain the provided stack trace from an Xcode crash log and suggest step-by-step debugging strategies, referencing any relevant standards or known issues in QUESTIONS.md."
- "Diagnose why audio files might not be saved in the correct format according to DATA_STANDARDS.md section 2, and suggest code fixes with comments referencing the standard."

---

## Code Refactoring and Architecture

- "Refactor AuthService.swift to be compatible with dependency injection and MVVM architecture, following the project’s architectural guidelines in README.md. Add comments explaining how the refactor improves testability and maintainability."
- "Split AnalysisService.swift into modular feature extractor classes, each responsible for a single acoustic feature, and ensure each module references the appropriate section in DATA_STANDARDS.md in code comments."
- "Migrate all feature extraction logic to follow the structure and naming conventions in DATA_STANDARDS.md. Add comments to each function referencing the relevant standard."
- "Add protocol definitions for all services in Sage/Services/ to improve testability and maintainability, referencing best practices in README.md."

---

## General Guidance

- "List all files and classes that reference DATA_STANDARDS.md to ensure compliance across the codebase."
- "Generate a checklist for adding a new acoustic feature, including research citation, data validation, and test coverage requirements, referencing DATA_STANDARDS.md and RESOURCES.md."
- "Explain the MVVM pattern as used in this project, and provide a template for structuring new ViewModels in Sage/, referencing the architectural guidelines in README.md."

---

## UI/UX Prompts

- "Generate a new SwiftUI View for [feature] using only the components in `Sage/DesignSystem/` (e.g., SageCard, SageButton, SageTypography)."
- "Refactor this View to use `SageColors` and `SageSpacing` instead of hardcoded values."
- "Add a new card style to the design system and use it in the dashboard."

> **AI Guidance:**  
> Never generate UI code with hardcoded colors, fonts, or spacing.  
> Always use the design system components and extend them as needed.

---

See [UI_STANDARDS.md](./UI_STANDARDS.md) for design system rules.
See [CONTRIBUTING.md](./CONTRIBUTING.md) for developer checklist.

**AI Guidance:**  
When generating or updating prompts, always check the Feedback Log in `DATA_STANDARDS.md` and the `CHANGELOG.md` for the latest standards and refinements.


