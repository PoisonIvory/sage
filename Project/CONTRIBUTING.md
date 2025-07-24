# Contributing to Sage

Welcome! This document outlines how to contribute to the Sage iOS app. Sage uses voice recordings to extract clinically relevant acoustic features as potential health biomarkers.

---

## Development Principles

- **Test-Driven Development (TDD):**
  - Write a test before implementing a new feature.
  - Ensure all tests pass before submitting a pull request.
- **Architecture:**
  - Use MVVM and dependency injection where possible.
  - Keep business logic out of Views; use ViewModels and Services.
- **Research and Data Standards:**
  - All speech features must cite relevant sections of `DATA_STANDARDS.md`.
  - Analysis logic should reference peer-reviewed research as listed in `RESOURCES.md`.
  - Use only validated, research-grade algorithms for feature extraction.

---

## Branching Strategy

- `main`: stable release
- `dev`: active development
- `feature/<name>`: for new features
- `bugfix/<name>`: for patches

---

## Commit Style

Use clear, conventional commit messages:

- `feat: add shimmer extraction pipeline`
- `fix: handle AVAudioRecorder interruption`
- `test: add unit tests for MFCC normalization`
- `docs: update DATA_STANDARDS.md with new feature`
- `refactor: migrate AudioManager to MVVM`

---

## Code Reviews

- Every pull request must be reviewed before merging.
- **Summary:** Include a brief description of changes and, if relevant, a research citation (e.g., “Implements shimmer extraction as described in Smith et al., 2022”).
- **Testing:** If updating UI/UX, test on at least two simulators (for example, iPhone 13 and iPhone 15 Pro).
- **Data/Analysis:** If adding or modifying analysis code, reference the relevant section of `DATA_STANDARDS.md` and cite the research source in code comments.

---

## AI Prompts for Cursor

Use these prompts to optimize code quality and research compliance:

- "Write a test for shimmer calculation in AnalysisService.swift using synthetic input."
- "Refactor AudioManager.swift to follow MVVM."
- "Generate Firestore rule to restrict access to authenticated users only."
- "Document the MFCC extraction function in AnalysisService.swift, referencing DATA_STANDARDS.md section 3.2."
- "Summarize the difference between jitter and shimmer as defined in RESOURCES.md."

---

## Continuous Improvement & Feedback

This project uses a centralized feedback log in `DATA_STANDARDS.md`.  
As you contribute, test, or receive feedback, please log any issues, suggestions, or improvements in the Feedback Log at the top of `DATA_STANDARDS.md`.

When a change is implemented, document it in `CHANGELOG.md` with the date, section(s) affected, description, rationale, and your name.

**AI Guidance:**  
When generating or updating code, documentation, or workflow, always check the latest Feedback Log in `DATA_STANDARDS.md` and the `CHANGELOG.md` for recent changes and standards.

---

Thank you for contributing to Sage. Your work helps advance research-grade, privacy-first health technology.
