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
| ...        | ...                 | ...                                    | ...                          | ...        |

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

**End of FEEDBACK_LOG.md**  

