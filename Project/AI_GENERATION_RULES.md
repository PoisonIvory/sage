# AI_GENERATION_RULES.md

## 1. Purpose

This document defines the rules and validation criteria that all AI-generated code, documentation, and tests must meet before being accepted into the Sage project.  
**Goal:** Ensure that AI agents (e.g., Cursor, GPT) self-audit their outputs for compliance, scientific rigor, and maintainability—reducing human review burden and increasing trustworthiness.

---

## 2. How to Use This Document

- **AI agents must reference this file** before submitting or suggesting code, documentation, or tests.
- **Human reviewers and CI pipelines** should use these rules as a checklist for automated or manual validation.
- **If any rule is not met, the AI must flag the output for human review or refuse to submit.**

---

## 3. Core Self-Audit Rules

### 3.1 Standards & Traceability

- **DATA_STANDARDS.md Citation:**  
  - All generated code, tests, and documentation must cite the relevant section(s) of `DATA_STANDARDS.md` in comments or docstrings.
  - **If not cited:** Reject the output or flag for review.

- **RESOURCES.md Citation:**  
  - Any scientific, clinical, or technical claim must reference the appropriate source in `RESOURCES.md`.
  - **If missing:** Flag for review.

- **DATA_DICTIONARY.md Reference:**  
  - All data fields used in code or docs must be defined in `DATA_DICTIONARY.md`.
  - **If undefined:** Refuse to submit and prompt for schema update.

### 3.2 Test Coverage & Quality

- **Test Coverage Threshold:**  
  - All new or modified code must be accompanied by tests that maintain ≥90% coverage of business logic and data processing.
  - **If coverage < 90%:** Refuse to submit and prompt for additional tests.

- **Test Traceability:**  
  - Each test must reference the requirement, feature, or standard it covers.
  - **If missing:** Flag for review.

### 3.3 Scientific Rationale

- **Rationale Requirement:**  
  - All feature extraction, data processing, and analysis code must include a scientific rationale in comments, referencing peer-reviewed sources from `RESOURCES.md`.
  - **If missing:** Flag for human review.

### 3.4 Documentation & Changelog

- **Documentation Update:**  
  - All new features, fields, or standards must be documented in the appropriate Markdown files.
  - **If not updated:** Refuse to submit and prompt for documentation.
- **CHANGELOG.md Update:**  
  - All significant changes must be logged in `CHANGELOG.md` with date, section, rationale, and author.
  - **If not updated:** Flag for review.

### 3.5 Feedback Loop

- **Feedback Log Update:**  
  - Any gaps, errors, or improvement ideas must be logged in the Feedback Log in `DATA_STANDARDS.md`.
  - **If not logged:** Prompt for update.

---

## 4. Example Self-Audit Prompts

- “Does every function reference the relevant section of DATA_STANDARDS.md?”
- “Is every data field used in code defined in DATA_DICTIONARY.md?”
- “Is there a scientific citation for every algorithm or threshold?”
- “Is test coverage ≥90%? If not, what is missing?”
- “Has CHANGELOG.md been updated for this change?”
- “Is the rationale for each feature or method clear and referenced?”

---

## 5. Enforcement & CI Integration

- **CI pipelines should run a validation script** that checks for:
  - Required citations in code/comments
  - Test coverage threshold
  - Documentation and changelog updates
- **If any rule fails,** the build should fail or the AI should refuse to submit the change.

---

## 6. AI Guidance

- **Before submitting any code, documentation, or test:**
  - Run through all rules in this file.
  - If any rule is not met, flag the output, refuse to submit, or prompt for human review.
  - Always err on the side of caution and traceability.

---

## 7. Example Rule Table

| Rule                                      | Action if Not Met         |
|--------------------------------------------|---------------------------|
| DATA_STANDARDS.md not cited                | Reject/flag for review    |
| Test coverage < 90%                        | Refuse to submit          |
| Scientific rationale missing               | Flag for human review     |
| Data field not in DATA_DICTIONARY.md       | Refuse, prompt for update |
| CHANGELOG.md not updated                   | Flag for review           |
| Documentation not updated                  | Refuse, prompt for update |
| Feedback Log not updated                   | Prompt for update         |

---

## 8. Known Gaps / To-Do

- Add new rules as project standards evolve.
- Integrate with automated linting and CI tools for enforcement.
- Update this file as new documentation or standards are added.

---

**End of AI_GENERATION_RULES.md**  

