# DOCS_AUTOMATION.md

## 1. Purpose

This document describes the strategy and tools for automating documentation in the Sage project.  
**Goal:** Ensure that all code, data, and processes are documented to a standard that enables seamless onboarding, maintenance, and extension by future engineers, researchers, or data scientists.

---

## 2. Documentation Philosophy

- **Documentation is code:** It should be versioned, reviewed, and updated alongside code.
- **Automate wherever possible:** Use tools and AI (e.g., Cursor) to generate, update, and validate documentation.
- **Single source of truth:** All standards, data definitions, and workflows should be documented in the repo and referenced in code.
- **Continuous improvement:** Documentation should evolve with the project, and feedback should be logged and acted upon.

---

## 3. What to Document

- **Codebase structure and setup (README.md)**
- **Data standards and feature definitions (DATA_STANDARDS.md, DATA_DICTIONARY.md)**
- **Testing strategy and coverage (TEST_PLAN.md)**
- **Changelog and feedback (CHANGELOG.md, Feedback Log in DATA_STANDARDS.md)**
- **Glossary of terms (GLOSSARY.md)**
- **AI prompt cookbook (PROMPTS.md)**
- **Security and privacy (SECURITY.md)**
- **Release notes and onboarding (RELEASE_NOTES.md, ONBOARDING.md)**
- **Any other process, workflow, or automation scripts**

---

## 4. Automation Tools & Practices

### 4.1 AI-Assisted Documentation

- **Use Cursor or GPT-based tools** to:
  - Generate docstrings and comments for all functions, classes, and modules.
  - Summarize code changes and generate PR/commit summaries.
  - Write or update Markdown files (README, DATA_STANDARDS, etc.) using prompts from PROMPTS.md.
  - Generate API documentation from code (e.g., using Jazzy for Swift, Sphinx for Python).

### 4.2 Scripted Documentation

- **Auto-generate documentation** using scripts:
  - `./automation_scripts/generate_docs.sh` — Runs all doc generators (e.g., Jazzy, Sphinx, custom scripts).
  - `./automation_scripts/update_changelog.sh` — Prompts for a summary of recent changes and appends to CHANGELOG.md.
  - `./automation_scripts/summarize_tests.sh` — Runs all tests and generates a summary report for inclusion in TEST_PLAN.md or as a CI artifact.

### 4.3 Continuous Integration (CI)

- **CI pipeline should:**
  - Run documentation generation scripts on every commit.
  - Fail the build if required documentation is missing or out of date.
  - Publish generated docs as artifacts or to a documentation site (if applicable).

### 4.4 Documentation Templates

- **Use templates for:**
  - PRs, issues, bug reports, feature requests (in `.github/` or `TEMPLATES/`)
  - New modules/classes (e.g., `TEMPLATES/module_docstring.txt`)
  - Data dictionary entries

---

## 5. AI Guidance & Prompts

- **Always reference the latest standards and feedback logs** when generating or updating documentation.
- **Example prompts for Cursor:**
  - "Generate docstrings for all functions in AnalysisService.swift, referencing DATA_STANDARDS.md."
  - "Summarize the changes in the last 5 commits and update CHANGELOG.md."
  - "Write a high-level overview of the data pipeline for README.md."
  - "Generate a data dictionary entry for the 'jitter_pct' feature."
  - "Create onboarding instructions for a new engineer joining the project."

---

## 6. Documentation Review & Traceability

- **All documentation changes must be reviewed** (by you or a future maintainer) before merging.
- **Each doc update should reference the relevant code, standard, or feedback log entry.**
- **Major documentation changes must be logged in CHANGELOG.md.**

---

## 7. Feedback Loop

- **All documentation gaps, errors, or improvement ideas** should be logged in the Feedback Log in `DATA_STANDARDS.md`.
- **When a doc is updated,** record the change in CHANGELOG.md with rationale.

---

## 8. Directory Structure for Docs & Automation

```

