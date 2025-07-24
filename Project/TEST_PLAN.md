# TEST_PLAN.md

## 1. Purpose

This document defines the testing strategy, coverage goals, and automation standards for the Sage iOS app and its backend.  
**All code, features, and data pipelines must be tested according to this plan.**  
AI assistants (e.g., Cursor) and human contributors should reference this document when writing, updating, or reviewing tests.

---

## 2. Testing Philosophy

- **Test-Driven Development (TDD):** Write tests before implementing new features or bug fixes.
- **Automated First:** All critical logic, data processing, and UI flows must be covered by automated tests.
- **Continuous Integration:** All tests must pass before merging code.
- **Traceability:** Each test should reference the relevant requirement, feature, or section of `DATA_STANDARDS.md` or `UI_STANDARDS.md`.
- **Feedback Loop:** All test failures, gaps, or improvements should be logged in the Feedback Log in `DATA_STANDARDS.md` and reflected in `CHANGELOG.md` when addressed.

---

## 3. Test Types & Coverage

### 3.1 Unit Tests

- **Scope:** Individual functions, classes, and modules (e.g., feature extraction, data validation, UI components).
- **Tools:** XCTest (iOS), pytest (Python backend), etc.
- **Examples:**
  - AudioManager: test correct file format, error handling.
  - AnalysisService: test feature extraction (pitch, jitter, shimmer, MFCCs).
  - AuthService: test login, error states, and edge cases.

### 3.2 Integration Tests

- **Scope:** Interactions between modules/services (e.g., audio upload → feature extraction → database write).
- **Tools:** XCTest, custom integration scripts, or API test frameworks.
- **Examples:**
  - End-to-end test: record audio, upload, extract features, verify DB entry.
  - Cloud function triggers and data flow.

### 3.3 UI/UX Tests

- **Scope:** User flows, accessibility, and visual correctness.
- **Tools:** XCUITest, iOSSnapshotTestCase, accessibility checkers.
- **Examples:**
  - Login → record → dashboard flow.
  - Accessibility: VoiceOver, Dynamic Type, color contrast.
  - UI snapshot tests for key screens/components.

### 3.4 Data Validation Tests

- **Scope:** Data quality, schema, and feature output.
- **Tools:** Custom Python scripts, pytest.
- **Examples:**
  - Validate all audio files are 48kHz, 24-bit WAV.
  - Feature output matches schema and plausible ranges.
  - Reference data regression tests.

### 3.5 Security & Privacy Tests

- **Scope:** Data access, encryption, anonymization, and compliance.
- **Tools:** Manual review, automated scripts, static analysis.
- **Examples:**
  - Ensure no PII is present in exported datasets.
  - Test user data deletion and access controls.

---

## 4. Test Automation & CI

- **All tests must be runnable via a single command/script** (e.g., `./run_tests.sh` or `make test`).
- **CI/CD pipeline** (e.g., GitHub Actions, Bitrise, CircleCI) must:
  - Run all tests on every commit and pull request.
  - Block merges if any test fails.
  - Generate a test report and summary.
- **AI Guidance:**  
  When generating or updating tests, always reference the relevant section of this document and the Feedback Log in `DATA_STANDARDS.md`.

---

## 5. Test Coverage Goals

- **Unit test coverage:** ≥90% of all business logic and data processing code.
- **Integration test coverage:** All critical user flows and data pipelines.
- **UI/UX test coverage:** All primary screens and flows, with accessibility checks.
- **Data validation:** 100% of ingested and exported data must pass validation scripts.

---

## 6. Test Documentation & Traceability

- **Each test file/function must include:**
  - A docstring or comment referencing the requirement, feature, or standard it covers (e.g., `# Tests jitter extraction per DATA_STANDARDS.md §3.2.2`).
  - If generated or updated by AI, a note indicating the prompt or rationale.
- **Test results and failures** should be summarized after each run and, if relevant, logged in the Feedback Log and/or `CHANGELOG.md`.

---

## 7. Feedback Loop & Continuous Improvement

- **All test failures, gaps, or improvement ideas** should be logged in the Feedback Log in `DATA_STANDARDS.md`.
- **When a test is added, updated, or removed,** document the change in `CHANGELOG.md` with rationale.
- **AI Guidance:**  
  When generating or updating tests, always check the Feedback Log and `CHANGELOG.md` for recent changes and standards.

---

## 8. Example AI Prompts for Cursor

- "Write a unit test for shimmer extraction in AnalysisService.swift, referencing DATA_STANDARDS.md §3.2.3."
- "Generate an XCUITest for the onboarding → recording → dashboard flow, ensuring accessibility compliance."
- "Create a Python test that validates all feature CSVs match the schema in DATA_DICTIONARY.md."
- "Summarize all test failures from the last CI run and update the Feedback Log in DATA_STANDARDS.md."

---

## 9. Test Directory Structure

```
Sage/
├── SageTests/                # iOS unit and integration tests
├── SageUITests/              # iOS UI and accessibility tests
├── tests/                    # Python backend tests
│   ├── test_feature_pipeline.py
│   ├── feature_validation/
│   └── ...
├── automation_scripts/       # Scripts for running tests, generating reports, etc.
```

---

## 10. Compliance Checklist

- [ ] All new features/bugfixes include relevant unit and integration tests.
- [ ] All tests reference the requirement or standard they cover.
- [ ] All tests pass in CI before merge.
- [ ] Test results are summarized and, if needed, logged in the Feedback Log.
- [ ] All test changes are documented in `CHANGELOG.md`.

---

**AI Guidance:**  
When generating or updating tests, always reference this document, the Feedback Log in `DATA_STANDARDS.md`, and `CHANGELOG.md` for the latest standards and requirements.

---
