# DATA_DICTIONARY.md

## 1. Purpose

This data dictionary defines every field, feature, and metadata element used in the Sage project’s datasets and feature files.  
**Goal:** Ensure that all data is clearly described, standardized, and traceable for analysis, compliance, and future development.

---

## 2. How to Use This Document

- **Reference this file** whenever you add, update, or use a data field in code, analysis, or documentation.
- **Update this file** whenever a new field is added, removed, or changed in the data schema.
- **AI Guidance:**  
  When generating or updating code, tests, or documentation, always check this data dictionary for field definitions and update it as needed.
- **Feedback Loop:**  
  Log any changes, clarifications, or issues in the Feedback Log in `DATA_STANDARDS.md`.

---

## 3. Data Field Table

| Field Name         | Type      | Description                                      | Example Value         | Source/Section         | Allowed Values/Range         | Notes/References           |
|--------------------|-----------|--------------------------------------------------|-----------------------|------------------------|-----------------------------|----------------------------|
| user_id            | String    | Anonymized unique user identifier                | U1001                | Metadata, §2.3         | [A-Za-z0-9]+                | Never PII, see Privacy     |
| session_time       | DateTime  | ISO 8601 timestamp of recording                  | 2025-01-24T15:30:00Z | Metadata, §2.3         | ISO 8601                     | UTC preferred              |
| task               | String    | Type of speech task                              | vowel                 | Metadata, §2.3         | vowel, reading, spontaneous  | See DATA_STANDARDS.md §2.2 |
| F0_mean            | Float     | Mean fundamental frequency (Hz)                  | 220.5                 | Features, §3.2.1        | 75–500                       | Praat, female range        |
| F0_sd              | Float     | Standard deviation of F0 (Hz)                    | 14.2                  | Features, §3.2.1        | 0–100                        |                            |
| jitter_pct         | Float     | Local jitter, percent (%)                        | 0.89                  | Features, §3.2.2        | 0–5                          | Praat, see §1 rationale    |
| shimmer_dB         | Float     | Local shimmer, decibels (dB)                     | 0.35                  | Features, §3.2.3        | 0–2                          | Praat                      |
| HNR_dB             | Float     | Harmonics-to-noise ratio (dB)                    | 18.7                  | Features, §3.2.4        | 0–30                         | Praat                      |
| MFCC1–MFCC13       | Float[]   | Mel-frequency cepstral coefficients              | [12.1, 8.3, ...]      | Features, §3.2.6        | -100–100                     | openSMILE eGeMAPS          |
| intensity_mean     | Float     | Mean intensity (dB)                              | 72.5                  | Features, §3.2.7        | 40–100                       | Relative dB                |
| speaking_rate      | Float     | Words per minute (WPM)                           | 180                   | Features, §3.2.8        | 50–300                       | Custom, see §3.2.8         |
| device_model       | String    | Device used for recording                        | iPhone 12             | Metadata, §2.3          | [Any iOS model]              |                            |
| cycle_phase        | String    | Menstrual cycle phase                            | luteal                | Metadata, §2.3          | follicular, ovulation, luteal, menstruation | User/self-report/inferred  |
| symptom_mood       | Integer   | Mood rating (user self-report, 1–5)              | 4                     | Metadata, §2.3          | 1–5                          | See survey schema          |
| frameFeatures      | Array    | Frame-level features: array of dicts with time-aligned feature vectors (e.g., time_sec, power_dB, is_clipped, etc.) | [{"time_sec":0.01,"power_dB":-20.0,"is_clipped":false}, ...] | Features, §3.3 | See below | Used for time-aligned analysis, export as CSV/JSON |
| summaryFeatures    | Dict     | Summary features: means, SDs, etc. for each recording | {"F0_mean":220.5,"jitter_pct":0.89,...} | Features, §3.3 | See below | Exported as single-row CSV/JSON |
| fileURL            | String   | Local file path/URL of the audio file | file:///Users/.../test.wav | Metadata, §2.3 | valid file URL | Not exported to research dataset |
| filename           | String   | Name of the audio file | test.wav | Metadata, §2.3 | valid filename | Used for traceability |
| fileFormat         | String   | Audio file format | wav | Metadata, §2.3 | wav | Must be WAV for analysis |
| sampleRate         | Float    | Audio sample rate (Hz) | 48000 | Metadata, §2.3 | 48000 | Must be 48kHz for analysis |
| bitDepth           | Int      | Audio bit depth | 24 | Metadata, §2.3 | 24 | Must be 24-bit for analysis |
| channelCount       | Int      | Number of audio channels | 1 | Metadata, §2.3 | 1 | Must be mono for analysis |
| deviceModel        | String   | Device model used for recording | iPhone 15 | Metadata, §2.3 | [Any iOS model] | For device QA |
| osVersion          | String   | OS version | 17.0 | Metadata, §2.3 | [Any] | For device QA |
| appVersion         | String   | App version | 1.0 | Metadata, §2.3 | [Any] | For traceability |
| duration           | Float    | Duration of the recording (seconds) | 5.0 | Metadata, §2.3 | >0 | Used for validation |
| cyclePhase         | String   | Menstrual cycle phase | luteal | Metadata, §2.3 | follicular, ovulation, luteal, menstruation | Optional |
| symptomMood        | Int      | Mood rating (user self-report, 1–5) | 4 | Metadata, §2.3 | 1–5 | Optional |

*Add new fields as needed. For arrays (e.g., MFCCs), specify the number of elements and order.*

---

## 4. Field Definitions

### user_id
- **Type:** String
- **Description:** Anonymized unique user identifier, never PII.
- **Example:** U1001
- **Source:** Generated by backend at user creation.
- **Notes:** Used in filenames, feature files, and database entries.

### session_time
- **Type:** DateTime (ISO 8601)
- **Description:** Timestamp of the recording session.
- **Example:** 2025-01-24T15:30:00Z
- **Notes:** Always in UTC. Used for chronological analysis.

### task
- **Type:** String
- **Description:** Type of speech task performed.
- **Allowed Values:** vowel, reading, spontaneous
- **Notes:** See DATA_STANDARDS.md §2.2 for task definitions.

### F0_mean
- **Type:** Float
- **Description:** Mean fundamental frequency (Hz) for the session.
- **Computation:** Praat autocorrelation, 75–500 Hz range.
- **Notes:** See DATA_STANDARDS.md §3.2.1.

*...Continue for all fields as in the table above...*

---

## 5. Data Schema Versioning

- **Schema changes must be versioned.**  
  - When a field is added, removed, or changed, increment the schema version.
  - Reference the schema version in all feature files and data exports.

---

## 6. AI Guidance

- When generating or updating code, tests, or documentation, always check this data dictionary for field definitions.
- When adding a new field, update this file and log the change in the Feedback Log in `DATA_STANDARDS.md`.
- When in doubt about a field, consult this file or propose a clarification.

---

## 7. Compliance Checklist

- [ ] All fields in data files are defined here.
- [ ] All field types, allowed values, and ranges are specified.
- [ ] All changes to the schema are logged in `CHANGELOG.md`.
- [ ] All code and documentation reference this file for field definitions.

---

## 8. Resources

- [DATA_STANDARDS.md](./DATA_STANDARDS.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [OpenSMILE Documentation](https://audeering.github.io/opensmile/)
- [Praat Manual](https://www.fon.hum.uva.nl/praat/manual/)

---

**AI Guidance:**  
When generating or updating code, tests, or documentation, always reference this data dictionary, the Feedback Log in `DATA_STANDARDS.md`, and `CHANGELOG.md` for the latest standards and requirements.

---
