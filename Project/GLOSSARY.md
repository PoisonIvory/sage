# Glossary: Speech Biomarkers in Sage

> **How to Use This Document:**  
> - Reference these definitions in all code, comments, and documentation.  
> - For any new terms, clarifications, or updates, log your feedback in the centralized Feedback Log in `DATA_STANDARDS.md`.
> - When a change is implemented, document it in `CHANGELOG.md` with the date, section(s) affected, description, rationale, and your name.
> - When using AI tools, always check the Feedback Log and `CHANGELOG.md` for the latest terminology and clarifications.

---

## Acoustic Feature Terms

- **Jitter**  
  Cycle-to-cycle variation in pitch (F0); high jitter may correlate with dysphonia or depressive symptoms.  
  *Implemented in `Sage/AnalysisService.swift`, see extraction parameters in `DATA_STANDARDS.md` section 3.1.*

- **Shimmer**  
  Cycle-to-cycle variation in amplitude; often elevated in stress and anxiety states.

- **Pitch / F0 (Fundamental Frequency)**  
  Perceived vocal pitch; can flatten in depression or fluctuate with hormonal cycles.

- **MFCC (Mel-Frequency Cepstral Coefficients)**  
  Spectral features modeling human auditory perception; useful in emotional and health-related speech analysis.

- **HNR (Harmonics-to-Noise Ratio)**  
  Measures voice periodicity; low values suggest breathiness or roughness.

- **Formants**  
  Resonant frequencies of the vocal tract; can shift in certain neurological or hormonal states.

---

## Project Concepts

- **Biomarker**  
  A measurable indicator of a biological condition (e.g., jitter as a proxy for mental health).

- **Speech Task**  
  A structured recording like sustained vowel or passage reading, designed to elicit analyzable voice features.

- **Sustained Phonation**  
  Holding a vowel sound ("aaa") for several seconds—ideal for jitter/shimmer extraction.

---

## Technical Terms

- **TDD (Test-Driven Development)**  
  Practice of writing tests before implementation to ensure reliability.

- **MVVM (Model-View-ViewModel)**  
  Architecture pattern used to separate business logic from UI.

- **AVAudioRecorder**  
  Apple API to record high-quality audio; used to capture speech samples in this app.

---

**AI Guidance:**  
When generating or updating definitions, always check the Feedback Log in `DATA_STANDARDS.md` and the `CHANGELOG.md` for the latest terminology and clarifications.


