# FEEDBACK_LOG.md

## Purpose

This log captures all feedback, discoveries, and lessons learned during development—especially those related to AI-generated code, debugging, and refactoring.  
**Goal:** Create a transparent, evolving record of what the AI (or you) got wrong, what needed improvement, and what insights emerged, so that documentation, standards, and code can be continuously updated and improved.

---

## How to Use This File

- **After every debugging session, refactor, or AI misstep,** add a new entry.
- **Log any insights, surprises, or “gotchas”** that could help you or future contributors.
- **Reference this log** when updating `DATA_STANDARDS.md`, `CHANGELOG.md`, or other documentation.
- **AI Guidance:**  
  Cursor and other AI agents should check this file before generating code or documentation, and should prompt to update it after each significant debugging or learning event.

---

## Feedback Log Table

| Date       | Area/Component      | Issue/Discovery/Insight                | Action Taken / Needed         | Updated By |
|------------|---------------------|----------------------------------------|------------------------------|------------|
| YYYY-MM-DD | AnalysisService.swift| AI-generated jitter code missed edge case for silence | Added silence check, updated DATA_STANDARDS.md | Ivy        |
| YYYY-MM-DD | UI_STANDARDS.md     | Chart colors failed accessibility contrast | Adjusted palette, logged in CHANGELOG.md | Ivy        |
| YYYY-MM-DD | Onboarding Flow     | User confusion on consent step         | Updated UI text, flagged for doc update | Ivy        |
| YYYY-MM-DD | Test Coverage       | AI skipped test for error state        | Added test, improved PROMPTS.md | Ivy        |
| 2025-07-25 | OnboardingFlowViewModel | AI imported MLVision modules by mistake | Added modal scope guard to all docs | Ivy |
| 2024-07-XX | Firestore schema, DATA_DICTIONARY.md, DATA_STANDARDS.md | Migrated frameFeatures to FrameBatch subcollection (50 frames/doc, 100Hz, power_dB rounded). Updated docs and added migration helper for legacy data. | Firestore doc size, query efficiency, clinical alignment | AI/automation |
| 2025-07-25 | Dashboard UI     | Introduced SagePercentileBar (capsule-style percentile/progress bar for showing user score relative to population, with color accent and label). Used for metrics like stability, sentiment, lexical diversity. | UI_STANDARDS.md, DATA_DICTIONARY.md | AI/UX Team |
| 2025-07-25 | Dashboard UI     | Added SageStylizedCard (card with variable background, soft shadow, and grouped sectioning for visual hierarchy and emotional resonance). Used to group related dashboard sections (acoustic, content features). | UI_STANDARDS.md | AI/UX Team |
| 2025-07-25 | Dashboard UI     | Added poetic, gentle 1-line insights per section, inspired by Co–Star, to create a more affirming and emotionally resonant user experience. | UI_STANDARDS.md | AI/UX Team |
| 2025-07-25 | Dashboard UI     | Applied color groupings and nature-inspired palette for emotional tone and clarity. | UI_STANDARDS.md | AI/UX Team |
| 2024-07-06: New Welcome Screen Layout Pattern
- Introduced `WelcomeView` (DesignSystem) as the new poetic, emotionally rich entry screen for Sage, inspired by Co–Star.
- Features: serif headline, poetic microcopy, three lyrical actions (Explore Without Signing In, Create My Account, Already a Member?), fade-in animation, and a softly layered abstract SVG background (`AbstractWaveBackground`).
- All colors, spacing, and typography use approved design tokens (`SageColors`, `SageTypography`, `SageSpacing`).
- Accessibility: Each action has a descriptive `.accessibilityLabel`.
- Logging: All user actions and view events are tracked with detailed print statements for debugging and event tracking, following project logging standards.
- AbstractWaveBackground extracted as a reusable design system component for future visual richness needs.
- See UI_STANDARDS.md for spacing, typography, and color rules. | ...        |
| 2025-07-25 | AnalyticsService.swift | Implemented onboarding_complete event tracking per DATA_STANDARDS.md §4.3.1, with documentation and test hooks. | Updated DATA_DICTIONARY.md, PROMPTS.md, DATA_STANDARDS.md | AI        |

---

## Example Entries

- **What AI got wrong:**  
  - “AI-generated code for shimmer extraction did not handle NaN values—caused crash on empty input.”
- **What needs refactoring:**  
  - “AnalysisService.swift: Feature extraction logic too monolithic, needs modularization for testability.”
- **What insights emerged during debugging:**  
  - “Discovered that iOS simulator records at 44.1kHz by default, not 48kHz—added resampling step.”

---

## AI Guidance

- Before generating or updating code, documentation, or tests, **review this log for known issues and lessons learned.**
- After debugging or discovering something new, **prompt to add an entry here.**
- Use this log to inform updates to standards, prompts, and documentation.

---

## Compliance Checklist

- [ ] All major bugs, AI missteps, and refactor needs are logged here.
- [ ] All insights that could improve standards or documentation are captured.
- [ ] Entries reference the relevant file, component, or doc.
- [ ] Updates to standards/docs based on this log are reflected in `CHANGELOG.md`.

---
2025-07-25: Updated onboarding hero screen copy and design to clinical, conviction-driven tone. Implemented new 'Voice Hero' screen (`VoiceHeroView.swift`) with line-art mouth/voice motif and animation. Reference: attached screenshot (ChatGPT Image Jul 25, 2025, 07_49_35 AM.png).



