DATA_STANDARDS.md
(Sage Voice Biomarker Project – Data & Development Standards)
How to Use This Document
This document is a reference manual for both developers and AI assistants working on the Sage voice biomarker project. It defines all requirements and standards that must be followed. To maximize utility:
Reference Specific Sections: All code, tests, and documentation must cite the relevant section numbers from this document when implementing features or making changes. This creates traceability between the standards and the implementation. For example, if you write code to calculate jitter, include a comment referencing the jitter section (§3.2.2) of this document.
AI and Human Contributors: Whether an AI assistant (e.g. Cursor, GPT-4) or a human developer is writing code or docs, they should actively refer to section numbers here. This ensures consistency and compliance. For instance, an AI-generated function for feature extraction should prompt itself with instructions like "Use parameters from DATA_STANDARDS.md §3.2.1 for pitch range."
Code Comment Examples: Every function docstring or important code comment should cite this standards document. For example:
# Implements jitter extraction as per DATA_STANDARDS.md §3.2.2
Or in another language, e.g. C/C++:
// See DATA_STANDARDS.md section 2.1 for audio format requirements
This way, reviewers (and automated tools) can quickly verify that the code adheres to the specified standards by checking the cited sections.
Section Numbering: The sections below are numbered hierarchically (e.g., 2.1, 3.2.1) specifically so you can reference them easily. When adding new features or tests, update or cite the exact section that governs that aspect.
Change Management: If a contribution requires deviating from these standards, the document must be updated (with a new section or revised rule) before or along with the code change, and the change logged in the Changelog (§12). No unrecorded deviations are allowed.
In summary, use this document as the single source of truth. Every commit, code review, or AI-generated suggestion should trace back to a section here. This ensures that the project remains coherent, reproducible, and aligned with the scientific goals. Failure to follow these standards will result in requests for change in code review or automated checks flagging the issue.
Purpose
This document defines the scientific, technical, and data standards for the Sage voice biomarker project. All code, data collection protocols, and analysis pipelines must comply with these requirements to ensure research-grade quality, reproducibility, and clinical relevance. By strictly following this guide, we ensure that our methods are transparent and that any AI assistant or developer contributing to the project works from the same playbook.
1. Scientific Rationale
Goal: Leverage speech as a digital biomarker for women's health, especially to monitor hormonal fluctuations and menstrual cycle–related conditions (PMS/PMDD, PCOS, endometriosis). The hypothesis is that subtle voice changes correlate with hormonal status and symptoms, providing an accessible tool for health monitoring. Key Biomarkers: Prior research has identified changes in voice fundamental frequency (pitch), voice stability (jitter, shimmer, harmonic-to-noise ratio or HNR), and speech dynamics across hormonal cycles and conditions. For example, studies have found that women's voices can subtly change with menstrual cycle phase: pitch tends to be higher and more variable around ovulation, while voice quality can worsen (higher noise, lower HNR) during menstruation. Women with severe premenstrual symptoms (PMS/PMDD) show increased vocal perturbation (jitter) in the late luteal phase, indicating objective vocal changes when hormone levels shift. In polycystic ovary syndrome (PCOS, a condition of chronic hyperandrogenism), traditional anecdotes suggest voice "deepening," but rigorous studies found no significant difference in average vocal parameters compared to controls. (Some PCOS patients do report deeper voice and vocal fatigue, but quantitative measures didn't show strong deviations.) By tracking these features over time, the project aims to correlate voice changes with hormone levels, cycle phase, and symptom severity. Research References: Key studies guiding these standards include Chae et al., 2001 (jitter increases premenstrually in PMS), Fischer et al., 2011 (daily voice analysis showed higher pitch variability before ovulation and increased voice noise during menses), and Lobmaier et al., 2024 (a recent review confirming cycle-dependent shifts in pitch and shimmer in some studies), among others (see §11 References for a detailed list). These studies, while not all in perfect agreement, collectively inform which vocal features are likely meaningful. For instance, a higher mean F0 and lower shimmer during high-fertility phases may signal ovulation, whereas increased jitter and added noise in the voice can accompany premenstrual days or hormone-related dysphonia. By documenting and analyzing these features in a rigorous way, Sage aims to provide women with insights into their cycle and health, grounded in peer-reviewed research. Section Summary: Voice acoustics can reflect underlying hormonal and physiological changes. Features like pitch (F0), pitch range, jitter (frequency instability), shimmer (amplitude instability), and HNR have been identified as relevant markers of hormonal status. For example, pitch tends to rise around ovulation and jitter tends to increase premenstrually in those with PMS. These findings justify our focus on specific voice features as biomarkers, and Section 3 details how we measure each. AI Guidance: When you (or an AI assistant) generate code or explanations, use Section 1 as scientific context. For instance, if writing a comment for a jitter analysis function, you might say: "Jitter is measured to capture voice roughness; it tends to increase premenstrually (see DATA_STANDARDS.md §1 for background)." Grounding technical choices in this section's research rationale will strengthen the clarity and legitimacy of the code.
2. Data Collection Protocol
This section describes how voice data is collected to ensure consistency and quality. All recording procedures in the mobile app must adhere to these standards. Developers working on the app (or AI generating related code) should reference Section 2 to enforce proper recording conditions and user guidance.
2.1 Recording Environment
To obtain high-quality audio for analysis, we enforce strict recording requirements:
Device: Use an Apple iOS device (iPhone). Recommended: iPhone 8 or newer for consistent audio hardware performance. (Rationale: Later models have improved microphones and ADCs, reducing hardware variability.)
Microphone: Use the built-in smartphone microphone (default). Avoid Bluetooth or low-quality external mics. Wireless earbuds (e.g., AirPods) often apply compression and limit frequency range, reducing analysis quality. If an external mic is absolutely necessary, it must meet or exceed the quality of the phone's mic (e.g., a high-fidelity external mic). The app should detect if a Bluetooth microphone is being used and warn the user (Bluetooth audio can noticeably degrade jitter/shimmer measures due to compression).
Distance: The speaker should hold the phone about ~6–10 cm from their mouth (approximately the width of two fingers) for optimal and consistent input volume. This standardized mouth-to-mic distance helps ensure similar input levels across sessions. The app can show a visual guide (illustration of phone distance) to assist users.
Sample Rate: Record at 48,000 Hz (48 kHz). This high sample rate captures the full spectrum of the human voice; lower rates (≤16 kHz) would lose important high-frequency details. (If a device only supports 44.1 kHz, our pipeline will automatically resample it to 48 kHz for analysis to maintain consistency.) All stored analysis files will thus be 48 kHz.
Bit Depth: Use 24-bit PCM (uncompressed WAV) for recording. A high bit depth preserves subtle amplitude variations, which is critical for jitter and shimmer analysis (these micro-perturbations in frequency/amplitude can be lost with lower resolution). If the app's API requires a compressed format (e.g., iOS might default to AAC in an .m4a container for efficiency), the audio must be converted to WAV (pulse-code modulated) before feature extraction. Lossless formats are strongly preferred. The conversion process should be verified to introduce no changes in the waveform or extracted features (see reference confirming M4A-to-WAV yields no significant difference in acoustic measures).
Channels: Record in mono (single channel). Multi-channel (stereo) voice recordings can have phase and level differences between channels; for voice analysis, a single channel is sufficient and avoids these complications. If a stereo recording occurs (due to device defaults), the pipeline will downmix it to mono.
File Format: Use a WAV container with PCM audio data. The app may initially save files in a compressed format like M4A/AAC for storage, but all analysis will be done on WAV files. We will convert uploaded audio to WAV on the server if needed. Any conversion steps must be validated to ensure they do not alter the audio quality (conversion should not change waveform shape or spectral content).
Environment: Record in a quiet, indoor setting. Users are instructed to find a silent room with ambient noise below ~40 dB (roughly the noise level of a quiet home or library) during recording. There should be no TV, music, or other people speaking in the background. Avoid large echoey spaces to minimize reverberation. The app can measure the ambient noise (through the microphone input level before or between tasks); if background noise exceeds acceptable levels (for example, if loud TV or traffic noise is present), the app will prompt the user to re-record in a quieter setting. We base the 40 dB threshold on studies showing that recordings in environments <40 dB are comparable to studio quality.
Headset Use: If a user must use a headset microphone, wired is preferable to Bluetooth. Bluetooth mics (e.g., AirPods) compress audio and reduce fidelity, especially for high-frequency content and in presence of background noise. If the app detects a Bluetooth audio input, it should warn the user of potential accuracy reduction (and ideally provide instructions to switch to the phone's built-in mic). For best results, the built-in phone mic or a high-quality external mic should be used, as these provide a flat frequency response and minimal compression.
AI Guidance: When writing code for audio capture or validating audio uploads, enforce these constraints. For example, if an uploaded file isn't 48 kHz mono WAV, the backend should convert or reject it, citing "See DATA_STANDARDS.md §2.1 for audio format requirements" in the log or code comment. In automated tests, include scenarios that check that audio with the wrong format or noisy background is handled appropriately (e.g., flagged or refused, per §3.4). Always include comments that reference §2.1 to justify why certain conditions (like sample rate or noise level) are enforced. Section Summary: All voice recordings must be collected under standardized conditions: high-quality audio (48 kHz, 24-bit, mono WAV) using the phone's built-in microphone at a consistent distance, in a quiet environment (<40 dB ambient noise). The app and backend should actively check and enforce these conditions. Adhering to these requirements is critical — it ensures that the acoustic features extracted are reliable and comparable across all users and sessions.
2.2 User Instructions
We employ multiple voice tasks to capture a range of acoustic features. The app provides on-screen instructions for each task to ensure consistency. All prompts and task designs are based on best practices in clinical voice assessment. Task Types:
Sustained Vowel: The user sustains a vowel sound (typically "ah") at a comfortable pitch and loudness for ~5 seconds. This task isolates vocal fold vibration properties and is ideal for measuring steady-state features like pitch stability, jitter, shimmer, and HNR. (Rationale: Sustained phonation yields more stable measurements and is a standard recommendation for voice analysis on smartphones, since it minimizes the influence of articulation.)
Reading Passage: The user reads a standard short passage aloud (e.g., the Rainbow Passage or another phonetically-balanced text) for roughly 30 seconds. This provides controlled content to measure prosody, articulation rate, and consistency. Using a fixed text (displayed on-screen) allows intra- and inter-user comparisons. The app will ensure the user reads the entire passage (highlighting words as they read and not ending the task until completion).
Spontaneous Speech: The user speaks freely for ~30–60 seconds about a given prompt. For example, the app might say: "Voice Journal: Describe how you feel today or any notable symptoms you're experiencing." The user then speaks spontaneously. This captures natural speech patterns, emotional tone, and speaking rate. It's useful for features related to mood or cognitive state (e.g., speech rate changes, intonation variability, pauses). The app will provide a countdown or timer and encourage the user to speak continuously without long pauses.
On-Screen Instructions: Consistent prompts are shown in the app for each task. These exact wording of instructions are part of the standard:
For sustained vowel:
"Take a deep breath and say 'ahhhhh' in a steady voice for 5 seconds."
(A visual timer bar is displayed counting down 5 seconds. The user is instructed to maintain a comfortable, constant pitch and volume throughout the duration.)
For reading:
"Please read the following passage aloud, speaking clearly and at a natural pace:"
(The full text of the passage appears on screen. The app highlights the text as the user reads. We ensure a minimum duration by requiring the passage be fully read – e.g., if the user finishes too quickly or skips, the app can detect it and prompt re-reading.)
For spontaneous speech:
"Describe how you're feeling today or any symptoms you're experiencing. Try to speak for about one minute."
(A countdown timer (e.g., 60 seconds) and a live waveform or volume meter is shown to reassure the user that audio is being recorded. The prompt encourages continuous speech and discourages long pauses. The user can tap "Done" if they finish speaking earlier, but we aim for at least 30 seconds of speech.)
Recording Workflow: The app will guide the user through these tasks one by one each session. Before the user begins recording, a calibration step may run – e.g., the app shows a volume meter and asks the user to say "test" to ensure the input level is not too low or peaking. If the input is too quiet or if clipping is detected at the start, the app advises the user to adjust (speak louder or move the phone further/closer). During recording, visual feedback (like the waveform or timer) is provided. After each recording, the user has the option to playback the audio and re-record if needed (for example, if there was a loud disturbance or they coughed). We encourage a re-record if any quality issues occurred. AI Guidance: When generating UI text or implementing the app's recording flow, use the exact instructions and task structures from §2.2. For example, an AI writing Swift code for the app should embed the above prompt text strings and possibly include a comment like // Prompt per DATA_STANDARDS.md §2.2: sustained vowel "ah" for 5 seconds. Ensure any changes to prompts or task timing are reflected here in the document. If writing tests or simulations (e.g., a test audio for the reading passage), use the specified durations and content to verify that analysis algorithms handle them. Always refer back to this section to guarantee the user experience and instructions remain consistent with the study design. Section Summary: We utilize three speaking tasks – a 5-second sustained vowel, a 30-second read passage, and ~1 minute of free speech – to capture a comprehensive set of voice features. Each task has a standardized prompt and procedure to ensure all users provide comparable input. Following these instructions exactly is crucial: it maximizes the reliability of extracted features (steady vowel for jitter/shimmer, fixed text for prosody, free speech for natural dynamics) and thus the validity of our biomarker analysis.
2.3 Metadata Collected
In each recording session, we collect structured metadata to contextualize the audio features. This metadata is as important as the audio itself for analysis and must be handled and stored with care. The following information is recorded (automatically or via user input) every session:
User Profile: Basic demographic and health info:
Age (in years).
Gender (self-described; our target demographic is predominantly female, but gender is recorded for completeness and inclusivity).
Pertinent health conditions (particularly those relevant to the study, e.g., diagnosis of PMDD, PCOS, endometriosis, or "none").
Storage: These are provided by the user with consent and stored in de-identified form. For example, age might be stored as an integer, gender as a coded value, and diagnoses as categorical codes. No personal identifiers (name, email, etc.) are included with the research data (see privacy in §6).
Device Info: Technical details of the recording device:
Device model (e.g., "iPhone 12").
OS version (e.g., iOS 16.4).
Microphone used: internal vs. external (if the platform can detect this).
This metadata allows us to track any device-related differences in audio. (For instance, if one phone model had systematically different noise levels, we could account for that.)
Cycle & Symptom Data: The app concurrently collects self-reported data on the user's menstrual cycle and symptoms:
Cycle phase or day: e.g., "Day 5 of cycle" or a phase label like follicular/luteal. (If the user logs the start of her last period, the app can infer the current cycle day; if the user knows her phase or uses ovulation predictor kits, that can be noted as well.)
Symptom self-reports: Each day, the user may rate or note symptoms such as mood (e.g., on a scale), stress level, pain level, fatigue, etc., and specific symptoms like bloating or cramps. These are collected via in-app questionnaires, typically right before or after the voice tasks.
Menstrual dates: The date of the last menstrual period (LMP) and the projected start of the next period (if the user is tracking this) can be recorded. This helps correlate voice changes with cycle stage (e.g., luteal vs follicular).
Session Timestamp: A timestamp is recorded for each session:
The date and time of the recording (in UTC, and/or local time). This provides chronological context.
Time of day is also captured (since vocal features can have diurnal variation; e.g., voices might be deeper in the morning). For analysis, we might compare morning vs evening recordings if needed.
The timestamp is stored in a standardized format (e.g., ISO 8601: 2025-01-24T15:30:00Z).
Environmental Context: We provide an option for the user (or automatic detection) to note anything unusual about their voice or environment at the time of recording:
For example, a user can tick a box or answer a question like "Do you have a sore throat or cold today?" or "Were you in a noisy location?".
They might also comment "I'm recovering from a cold" or "there was faint traffic noise".
This helps explain outlier feature values (e.g. if jitter is high because the user had laryngitis, we'd know from metadata).
All of the above metadata is stored alongside the audio features in our database and feature files. This enables stratified analysis — for instance, we can compare voice features on recordings from the follicular vs. luteal phase, or examine how jitter changes on days when the user reports high stress versus low stress. The metadata is linked by the session timestamp or an unique session ID so that each feature vector can be traced to the context in which it was recorded. AI Guidance: When designing database schemas or data pipelines, ensure every metadata field above is accounted for. For example, if writing an ORM model or a JSON schema for session data, include fields for device model, cycle_phase, symptoms, etc., referencing §2.3 in code comments. Any analysis script should utilize this metadata (e.g., grouping data by cycle phase as per the definitions here). If an AI is asked to generate code for data ingestion or analysis, it should cite this section to show where the expected fields come from. In tests, you should create dummy metadata (age, cycle day, etc.) to verify that the system correctly links it with audio features. Section Summary: Every voice recording session is accompanied by rich metadata: user demographics (age, gender, relevant diagnoses), device details, menstrual cycle stage, symptom ratings, timestamp, and notes on context. This metadata is crucial for interpretation — it allows us to control for factors like age or device, and to correlate voice changes with cycle phases and symptoms. All metadata must be stored in a de-identified, structured manner and used in analysis to stratify and make our findings more meaningful.
3. Feature Extraction Standards
Once audio data is collected (per Section 2), it is processed to extract quantitative voice features. This section defines the libraries, tools, and methods we use to compute features, the specific features extracted, the format of the output data, and how we validate the feature extraction process. Adhering to these standards ensures that the analysis is scientifically valid and consistent across all data.
3.1 Libraries & Tools
To ensure scientifically validated analysis, we rely on established acoustic processing libraries and tools rather than reinventing algorithms. All feature extraction code runs in our cloud environment (server-side) for consistency. The specific tools and their configurations are:
openSMILE v3.0: Open Speech and Music Interpretation by Large-space Extraction is our primary toolkit for comprehensive feature extraction. OpenSMILE provides standardized feature sets widely used in speech research. We configure it to use the Geneva Minimalistic Acoustic Parameter Set (eGeMAPS), version 02, which includes 88 low-level descriptors covering frequency, energy, and voice quality measures. This ensures our feature set aligns with peer-reviewed standards in voice analysis (eGeMAPS is specifically designed for emotion and clinical voice applications).
Configuration: We use openSMILE's default extended GeMAPS configuration: frame length 25 ms, frame hop length 10 ms, pre-emphasis 0.97, and an 8 kHz low-pass filter for spectral features (since most voice energy is below 8 kHz). These parameters come from the eGeMAPS specification. We integrate openSMILE via its Python API (audeering/opensmile-python), pinned to v3.0 to avoid changes over time.
Praat v6.3+: Praat (a tool for phonetic analysis) is used for precise calculation of classical voice features: fundamental frequency (F0), jitter, shimmer, and harmonic-to-noise ratio (HNR). Praat's algorithms for pitch tracking (autocorrelation method) and perturbation measures are well-validated in voice research. We invoke Praat either through a Python wrapper (e.g. parselmouth) or by calling Praat scripts on the server.
Configuration: We set Praat's pitch analysis range to 75–500 Hz (this is appropriate for female voices, covering abnormally low or high pitches as well). Jitter and shimmer are computed using Praat's default settings (e.g., local jitter % and local shimmer in dB, measured over typical 0.01–0.02 s intervals) to maintain comparability with literature and clinical norms. HNR is measured over the full voice bandwidth (0–~5000 Hz by Praat default). These parameters reflect typical settings in research and ensure our results can be directly compared with published findings.
Librosa v0.10: Librosa is a Python library for audio processing. We use it for any custom signal processing tasks outside the scope of openSMILE or Praat. For example, we might use librosa for implementing a voice activity detection (VAD) algorithm, or to compute an MFCC matrix for sanity-checking against openSMILE's output. Librosa is well-tested in the community, but we primarily use it for verification and utility rather than as the primary source of features. For critical acoustic features, we rely on openSMILE and Praat as the ground truth (to benefit from their domain-validated algorithms).
Other Tools: If needed for advanced analysis, we may incorporate:
Machine Learning frameworks: TensorFlow or PyTorch, for example if we develop classification models (e.g., to predict cycle phase from features or to detect voice pathology). These would be used in a research capacity and follow the features outlined here.
Noise reduction or filtering libraries: Only if pre-processing is absolutely required. By default, we do not apply noise reduction to recordings (to avoid altering the raw data), but if a particular analysis calls for it, any such step would be documented and standardized here.
Note: All analysis code (feature extraction, validation, etc.) is implemented in the cloud/back-end (Python) rather than on the mobile device. This is to ensure we can use these libraries (which may be too heavy for on-device), and to maintain consistent versions. Each tool's version is pinned (e.g., a specific Praat release, openSMILE 3.0.1, librosa 0.10.x) so that we don't get unintended differences if the libraries update. If we ever upgrade a library version, we will validate that results remain consistent or update the standards accordingly. AI Guidance: When writing feature extraction code, always use the above tools and configurations. For example, if generating code to compute jitter, call Praat via parselmouth rather than implementing a custom jitter algorithm, and mention # Using Praat per DATA_STANDARDS.md §3.1 in the code. If an AI suggests using a new library or method, it must be justified and likely would require an update to this document. In general, stick to openSMILE and Praat for feature calculations to ensure validity. Any deviation should raise a flag. Comments in code should clearly tie back to these tool choices (e.g., "Frame length 25 ms as specified in §3.1 for eGeMAPS features"). This way, any contributor or reviewer can check the code against this section and immediately see if it's compliant. Section Summary: We use openSMILE (for a wide array of acoustic features with the eGeMAPS set) and Praat (for gold-standard voice quality measures like pitch, jitter, shimmer, HNR) as our primary analysis tools, supplemented by Librosa for utility. These choices are deliberate: they ensure our features are comparable to those in literature and that our algorithms are trusted and standardized. All feature extraction code should call these libraries with the specified settings, rather than custom implementations, to maintain consistency and credibility.
3.2 Features Extracted
We extract a comprehensive set of acoustic features known to reflect vocal changes in health, affect, and physiological state. Many of these come from the eGeMAPS feature set (which provides a fixed vector of 88 features per recording), and we supplement with additional custom measures. Below we list the key features and their computation details. For each feature, we specify the method/tool used and any parameters or notes. Developers should implement or use these exactly as described.
3.2.1 Fundamental Frequency (F0) – Mean, Min, Max, SD
Tool/Method: Praat (autocorrelation pitch tracking).
What: The basic pitch of the voice (in Hz). We measure mean F0 (the average speaking pitch), minimum F0, maximum F0, and the standard deviation (SD) of F0 for each recording. These provide insight into pitch level and variability.
Parameters/Notes: We restrict pitch analysis to the range 75–500 Hz appropriate for adult female voices. This captures even abnormally low or high pitches without false doubling/halving. Mean F0 reflects the person's habitual pitch; min/max F0 indicate the pitch range used; and F0 SD (variability) measures intonational variability or pitch dynamism. For example, a high F0 SD in a reading passage might indicate expressive or stressed speech, whereas a low F0 SD might indicate monotone delivery.
3.2.2 Jitter (Frequency Variation)
Tool/Method: Praat (voice report, perturbation analysis).
What: Jitter quantifies the cycle-to-cycle variations in fundamental frequency (i.e., the minute fluctuations in pitch period). It is usually reported as a percentage or as a relative measure. We use Praat's "local jitter (%)" and/or the Relative Average Perturbation (RAP) measure of jitter.
Parameters/Notes: Jitter is calculated over sustained phonation segments by Praat using its default algorithm (local jitter is the average absolute difference between consecutive periods, divided by the average period, times 100%). Higher jitter indicates less stable pitch – perceptually this corresponds to a rough or harsh voice quality. In our context, jitter is a key measure of vocal stability; for instance, an increase in jitter may reflect vocal fatigue or hormonal influences (studies show jitter can rise premenstrually in some women, see §1). We closely monitor jitter in sustained vowels since that task best reveals micro-instabilities in vocal fold vibration. AI Guidance: When generating code for jitter calculation, use Praat's algorithm via a library like parselmouth. Include a comment like # Calculating jitter as per DATA_STANDARDS.md §3.2.2 (Praat local jitter %). Also consider adding a note in code comments about why jitter matters, e.g., "# Jitter reflects pitch stability; see §1, jitter tends to increase under certain hormonal conditions." This ties the implementation to both the technical spec and the scientific rationale.
3.2.3 Shimmer (Amplitude Variation)
Tool/Method: Praat (voice report, perturbation analysis).
What: Shimmer measures cycle-to-cycle variation in amplitude (loudness). We compute local shimmer in percentage and/or in decibels (dB) as provided by Praat's voice report.
Parameters/Notes: Higher shimmer indicates less stable amplitude, perceived as breathiness or hoarseness in the voice. We use Praat's default shimmer calculations (local shimmer = average absolute difference between amplitudes of successive periods, normalized by the average amplitude). Shimmer is particularly interesting in our study because some literature suggests shimmer decreases during high-fertility (mid-cycle) when voice stability improves. Conversely, shimmer may increase with vocal fatigue or any condition that makes the voice more irregular in amplitude. We will track shimmer changes over time as a potential biomarker (e.g., a spike in shimmer might indicate the user has a sore throat or is in a hormone phase with poorer vocal control).
3.2.4 Harmonic-to-Noise Ratio (HNR)
Tool/Method: Praat (voice report).
What: HNR is the ratio of periodic (harmonic) sound energy to noise energy in the voice, expressed in decibels (dB). It essentially indicates how "clean" or "breathy" the voice sounds.
Parameters/Notes: Praat computes HNR by comparing the amplitude of periodic components to aperiodic components across the voice frequency band (~0–5000 Hz). A higher HNR (dB) means the voice is more harmonic (clean, little noise), whereas lower HNR means more noise (breathiness or hoarseness). For example, a healthy sustained vowel might have HNR around 20 dB, whereas a very breathy or hoarse voice might drop toward 0–5 dB. In our context, HNR tends to drop during menstruation for some women (more noise in the voice). We use HNR as an overall voice quality metric; significant drops may indicate vocal roughness associated with hormonal changes or illness.
3.2.5 Formant Frequencies (F1–F4)
Tool/Method: Praat (Linear Predictive Coding) or openSMILE.
What: Formants are resonant frequencies of the vocal tract. We track the first four formants (F1, F2, F3, F4) in sustained vowels and spoken passages. These are measured in Hz.
Parameters/Notes: Formant positions relate to physiology (e.g., tongue height affects F1, tongue backness affects F2). We include formants to see if hormonal changes (like minor swelling or drying of vocal folds/tissues) have any subtle effect on articulation. Large formant shifts are not expected over the menstrual cycle, but we record them for completeness. For example, some studies have investigated whether vocal tract resonance changes across cycle (most found no major effect, but we have it covered). Formants are especially analyzed on the sustained vowel /a/ (which provides a clear formant pattern). We use Praat's LPC algorithm for consistency, but openSMILE can also provide formant estimates which we may use for cross-checking.
3.2.6 Mel-Frequency Cepstral Coefficients (MFCCs)
Tool/Method: openSMILE (eGeMAPS configuration).
What: MFCCs are a set of features that represent the short-term power spectrum of sound in a way that approximates human auditory perception. We extract the first 13 MFCCs (coefficients 1 through 13) for each frame, and if needed their delta (Δ) coefficients representing their change over time.
Parameters/Notes: In the eGeMAPS feature set, 14 specific MFCC-related features are included (likely MFCC1–MFCC4 and some delta or LLD statistics). However, to be thorough, we configure openSMILE to produce MFCC 1–13 per frame with a typical configuration: 20 ms Hamming window, 50% overlap (10 ms hop), 26 mel filterbanks up to 8 kHz. We may not use all MFCCs individually in analysis, but they feed into machine learning models or can be used to compute distances between voices. MFCCs capture the broad spectral shape of the voice and can reveal subtle changes that specific measures (like jitter/shimmer) might miss. They are especially useful if we build any machine learning classifier to detect, say, if a given voice is in pre-ovulation vs. post-ovulation phase, because the combination of MFCCs can encode complex spectral patterns.
3.2.7 Intensity (Loudness) – Mean & Variability
Tool/Method: openSMILE and/or Praat.
What: Intensity refers to the sound energy, corresponding to loudness. We measure the average intensity of the recording (in decibels) and the variability of intensity. If the device were calibrated, we could get absolute Sound Pressure Level (dB SPL), but typically we'll use relative dB.
Parameters/Notes: We compute intensity from the root-mean-square (RMS) amplitude of the signal. In practice, openSMILE provides an "Loudness" feature and Praat provides an intensity contour. We ensure the user speaks at a comfortable loudness in each session (the calibration step in §2.2 helps). Intensity features serve two purposes: (1) as a quality control – we check that the user's speaking volume is in a reasonable range (not whispering one day and shouting the next); and (2) as a feature – changes in average loudness could reflect fatigue or mood (e.g., a consistently quieter voice might indicate low energy or depression). Additionally, the variability (standard deviation) of intensity within a task indicates prosodic emphasis. For example, in expressive speech you expect more intensity variation (higher SD), whereas monotone speech has low variation.
3.2.8 Speaking Rate
Tool/Method: Custom Python analysis (using transcripts or silence detection).
What: Speaking rate is typically measured in words per minute (WPM) or syllables per second. We measure this for the reading passage and spontaneous speech tasks (it's not applicable to the sustained vowel).
Parameters/Notes: We can estimate speaking rate by automatically transcribing the speech (via an ASR tool) and counting words, or more simply by detecting pauses: e.g., count syllable-like segments or measure total voiced duration vs pauses in the recording. We define it as words per minute for readability. A pause threshold of ~300 ms of silence is used to segment phrases. Speaking rate can reflect cognitive and emotional state: for instance, some research suggests people speak more slowly during the luteal phase if they experience low energy, or speech may slow when someone is sad or fatigued. We will compare speaking rates across cycle phases and symptom reports. The code will likely implement a simple VAD (Voice Activity Detection) to exclude silences, then compute words or syllables per unit time. We ensure to document which method is used (transcript-based or energy-threshold-based). Our tests will include checking that, say, a 30s passage of 100 words yields ~200 WPM.
3.2.9 Voice Breaks & Unvoiced Frames
Tool/Method: Praat or openSMILE.
What: These measures quantify how often voicing is interrupted. A "voice break" is a brief period where the voice stops (e.g., glottal stop or drop-out) when it should be continuous, and unvoiced frames are analysis frames where no fundamental frequency is detected during speech.
Parameters/Notes: We calculate the percentage of frames that are unvoiced or the number of voice breaks in a sustained phonation. For sustained vowels, ideally there should be nearly 0 breaks. In running speech, unvoiced frames occur at silence or unvoiced consonants, so context matters. But an unusually high fraction of unvoiced frames in what should be voiced parts can indicate vocal issues. A higher rate of voice breaks (or "creakiness") can occur with dry vocal folds or fatigue, for example in premenstrual days some women experience more vocal fry or breakage. We particularly look at the sustained vowel task for voice breaks as a quality metric (e.g., if the user couldn't hold the "ah" steadily). The openSMILE eGeMAPS set includes features like "VoicedSegmentLength" etc., which relate to this.
3.2.10 Spectral Center of Gravity (CoG)
Tool/Method: openSMILE (eGeMAPS).
What: The spectral center of gravity is the frequency centroid of the sound spectrum – essentially the "balance point" of frequencies. A higher CoG means the spectrum has more high-frequency energy (brighter sound), and a lower CoG means more low-frequency energy (darker, fuller sound).
Parameters/Notes: We compute CoG for the voice signal, typically averaged over the voiced portion of the recording. Changes in spectral CoG can indicate timbre changes. For example, a "brighter" timbre (higher CoG) might occur if the voice has more high-frequency content (perhaps due to breathiness or stiffness), whereas a "darker" voice (lower CoG) might occur in low-energy states or certain hormonal phases. Anecdotally, some women report a darker, more mellow voice in the luteal phase – if true, we might see a slight drop in CoG on those days. We will analyze CoG trends as part of the spectral features.
3.2.11 Spectral Band Energy Distribution
Tool/Method: openSMILE.
What: Energy in specific frequency bands (low, mid, high) as a fraction of total energy. We particularly monitor high-frequency noise energy.
Parameters/Notes: We define bands such as low (0–500 Hz), mid (500–5000 Hz), and high (>5 kHz) and measure the energy in each band. This can capture, for example, if there's an unusual amount of high-frequency energy (which often means hiss or fricative noise). In our context, increased high-band energy might correlate with breathiness (since turbulent noise adds high-frequency components). Conversely, a very low high-frequency energy could mean a very "pressed" or low, smooth voice. We expect most energy in voice to be in the low-mid bands; a change in distribution could be a sign of voice changes (e.g., more high-frequency noise around menstruation as HNR drops). OpenSMILE can output band energies or we can compute via FFT filters.
3.2.12 Task-Specific Metrics
Finally, we capture a few metrics specific to certain tasks:
Maximum Phonation Time: In the sustained vowel task, we expect the user to sustain ~5 seconds. We note the actual duration of voiced sound. If it's markedly shorter (e.g., user could only do 3 seconds), it might indicate breath control issues or non-compliance. We don't enforce this heavily (since the app guides the time), but it's recorded for completeness.
Articulation Rate (Reading): For the reading passage, aside from overall speaking rate, we might compute articulation rate (syllables per second, excluding pauses). This is similar to speaking rate but focuses on when the user is actually speaking (not counting silence).
Spontaneous Speech NLP: While not an acoustic feature per se, we note that we may analyze the sentiment or emotional tone of the spontaneous speech via natural language processing. This is outside the acoustic scope, but if we do it, we'd document it here. (For instance, an NLP model could score the sentiment of what the user said, or detect certain words related to mood.) This would be considered exploratory and not part of the core acoustic feature set.
(All the features above form our research feature set. In practice, openSMILE's eGeMAPS implementation yields a fixed 88-dimensional feature vector (functionals of low-level descriptors) for each audio file, which covers many of these features automatically. We supplement that with custom features like speaking rate, which are not included in eGeMAPS. The combination gives us both standardized metrics and bespoke measures tailored to our study.) AI Guidance: When implementing the feature extraction pipeline, ensure each feature is computed exactly as specified in §3.2.1–§3.2.12. For example, use the same frame sizes and algorithms (don't swap in a different pitch tracker or change the jitter formula). In code, structure the output clearly (e.g., as columns "F0_mean, F0_min, … jitter_pct, shimmer_dB, …") matching our definitions. If an AI writes this code, it should include inline comments referencing these subsections, like # F0 range per §3.2.1 or # computing spectral centroid per §3.2.10. This will help any reviewer trace the code back to requirements. Also, use the context from Section 1 to justify in comments why a feature is included (e.g., "Shimmer (§3.2.3) included because it can decrease in high-fertility phases, see §1"). This cross-referencing ensures the scientific rationale remains tied to the implementation. Section Summary: We extract a rich set of features from each voice recording: traditional voice quality measures (pitch, jitter, shimmer, HNR, formants), comprehensive spectral features (MFCCs, spectral centroid, band energies), intensity and prosodic features (loudness, speaking rate), and any task-specific indicators. Each feature is defined with a specific calculation method and rationale. By adhering to these definitions, we ensure that our dataset captures the nuances of voice that are relevant to hormonal and health changes, in a way that is consistent and comparable to existing research. Every feature in code must trace back to these specs.
3.3 Output Format
After processing each audio recording, the system generates output files containing the extracted features. A consistent output format is critical for downstream analysis and for other researchers (or the participants, if we return data) to interpret results. The standards for output files are:
Raw Audio Files: We store the raw (or converted) audio for each session with a standardized filename convention:
{userID}_{task}_{timestamp}.wav```  
For example: `U1001_read_20250124T153000Z.wav` would be the file for user U1001's reading task on Jan 24, 2025 at 15:30 UTC. Filenames are lowercase, and timestamp is in ISO format (compact form, UTC). If the recording was originally done in another format (e.g., M4A), the **filename still uses `.wav`** since that's what we analyze. (We internally document the original format if needed, but the key is that the WAV used for analysis is saved with this name.) This naming scheme encodes who, what task, and when, without any personal info.

Feature Files: For each audio file, a corresponding feature data file is produced, either in CSV (comma-separated values) or JSON format. The filename mirrors the audio filename, with an added identifier, for example:
{userID}_{task}_{timestamp}_features.csv```  
e.g., `U1001_read_20250124T153000Z_features.csv`.  
We primarily use CSV for easy loading into analysis tools, but JSON can be used if hierarchical data needs to be stored. The file contains the extracted features from that recording.

Frame-level vs Summary features: We handle two types of feature outputs:
Frame-level time series: For certain low-level descriptors (like pitch over time, intensity contour), we output a time series. In the CSV, this would be one row per time frame (e.g., 100 frames per second for a 10 ms hop), with a timestamp or frame index column and then feature columns. The first row is a header. For example, a pitch track CSV might have columns time_sec, F0_Hz. This is mainly for research visualization or debugging, not for every analysis. If frame-level output is enabled, the time base is included (each frame row includes timestamp or frame number).
Summary features (functionals): For each recording, we typically compute a single set of statistical features (e.g., means, standard deviations, percentiles of the low-level features) – in eGeMAPS these are called functionals. In this case, we output a single-row CSV (plus header) per recording, where each column is a feature. That is the standard for our main dataset: one row of 80+ features representing that recording. This is easier for analysis across recordings.
In practice, eGeMAPS functionals yield one vector of 88 features per file. We use that as the basis of our summary feature file (and then append any custom ones like speaking rate). Thus, each _features.csv might be a single line (with header) if only summary features are included, or multiple lines if frame-level details are included. We make this clear by naming conventions or separate files.
Feature Naming Conventions: Column names in the feature files are human-readable and descriptive. We avoid cryptic abbreviations. For example:
Use F0_mean, F0_min, F0_max, F0_sd for fundamental frequency stats.
Use jitter_local_pct for jitter (%), shimmer_local_dB for shimmer in dB.
HNR_dB for harmonic-to-noise ratio.
MFCC1 ... MFCC13 for MFCC coefficients (or more descriptive if needed).
If using standardized names from literature or openSMILE, we can include those in a data dictionary.
We maintain a data dictionary in the repository at research/feature_extraction/feature_definitions.md listing each feature, its description, and references. This document should be kept in sync with the actual output.
Timestamps: If frame-level output is provided, the first column will typically be time in seconds (or milliseconds) from the start of the recording. E.g., 0.00, 0.01, 0.02, ... for a 10 ms hop. Summary outputs do not need a timestamp since they summarize the whole file.
Data Integration: Each feature file includes some identifying metadata in either the filename (as shown) and/or inside the file:
We include in each file (either as part of filename or as header fields) the userID, task, and session_time so that it's self-documenting. For example, the first few columns might be user_id, session_time, task, ... features .... This avoids any confusion if files get separated from their names or combined.
We also include a field for the pipeline version (see §5 Reproducibility & Versioning). For instance, the header or a comment in the CSV could indicate pipeline_version = v1.1. This way, anyone looking at the data can know which version of the extraction code produced it.
Example: A summary CSV for a sustained vowel recording might look like:
user_id,session_time,task,F0_mean,F0_sd,F0_min,F0_max,jitter_pct,shimmer_dB,HNR_dB,...  
U1001,2025-01-24T15:30:00Z,vowel,220.5,14.2,191.0,245.3,0.89,0.35,18.7,...  
(This example shows user U1001's vowel task on that date, with mean F0 ~220.5 Hz, F0 variability 14.2 Hz, min F0 191 Hz, max 245.3 Hz, jitter 0.89%, shimmer 0.35 dB, HNR 18.7 dB, etc. Actual files will include all 80+ features.)
user_id,session_time,task,F0_mean,F0_sd,F0_min,F0_max,jitter_pct,shimmer_dB,HNR_dB,...
U1001,2025-01-24T15:30:00Z,vowel,220.5,14.2,191.0,245.3,0.89,0.35,18.7,...
(Illustrative CSV content; actual feature set is broader.) AI Guidance: When writing or refactoring code for outputting features, follow this format strictly. For example, a Python script that saves CSV should use the naming convention and include a header row exactly as defined. Include a comment such as # Writing features CSV per DATA_STANDARDS.md §3.3 to indicate adherence. If altering the output format, you must update this document (and likely increment the pipeline version). All tests expecting output files should be updated accordingly. Any downstream code (e.g., data ingestion in analysis notebooks) should reference §3.3 to ensure it's reading the correct columns. In summary, never change the output format arbitrarily – it's a contract defined here. Section Summary: Feature data from each recording is saved in a clear, self-documented format: WAV files for audio, and CSV/JSON for features with descriptive column names. Filenames encode user, task, and timestamp, and feature files include metadata and version info. This consistency lets us easily merge and compare datasets and ensures that anyone (internal or external) can understand the content of the files. The output format should be treated as a stable schema – any change must be deliberate and reflected in this document and the code.
3.4 Validation (Automated Checks on Data Quality)
To maintain data integrity, each audio recording and its extracted features undergo a series of validation checks. These checks happen in the cloud processing pipeline automatically and flag or correct issues in the data. The goal is to catch problems early (at upload or analysis time) so that low-quality data does not skew our results. Automated Audio Checks: Upon audio upload (or prior to feature extraction), the system performs these checks:
Format Check: Verify the audio file meets our format specs (WAV, 48 kHz, 24-bit, mono, as per §2.1). If a file is not in the correct format, the pipeline will attempt to convert it (e.g., resample to 48kHz or downmix stereo to mono) and will flag it. If conversion is not possible or the file is too far from spec, the file is rejected. We log any such events (e.g., "Recording X was 44.1 kHz and was resampled to 48 kHz"). This ensures all analysis actually runs on standardized data.
Clipping Check: We scan the waveform to detect clipping (where the amplitude is at the maximum and flattens out). Specifically, if more than 0.1% of samples in the file are at 0 dBFS (the digital maximum), we consider the recording clipped. Clipping distorts the waveform and can invalidate jitter/shimmer measures (since the waveform shape is altered). If clipping is detected above the threshold, the system flags the recording as "poor quality – clipping." In the user-facing app, we may prompt the user to re-record at a lower volume if clipping occurred. In the data, we store a flag so analysts know that file had clipping (and we might exclude or treat it specially).
Noise Floor / SNR Check: We estimate the background noise level of the recording, typically by analyzing a segment of supposed silence (for example, before the user starts speaking, or using the lowest 5th percentile of the amplitude distribution). From this, we compute a signal-to-noise ratio (SNR). If the SNR is below a threshold (we use SNR < 20 dB as a guideline for too noisy), we flag the recording for high background noise. Likewise, if ambient noise level > ~40 dB (absolute) is detected, that violates our environment standard (§2.1). Such files might be excluded from analysis, or the user may be asked to redo the recording in a quieter setting. We aim for consistent quiet conditions, so this check is important for filtering out data where, say, a TV or street noise was present.
Duration Check: Ensure the recording meets minimum duration requirements for each task:
Sustained vowel: must have at least 3 seconds of voiced sound (out of the ~5 s expected). If the user stops too early (<3 s), it's often insufficient for reliable jitter/shimmer.
Reading task: must be > 20 seconds of speech (we expect ~30 s if done correctly). If someone stopped very early or didn't read fully, the data is incomplete.
Spontaneous speech: must be > 30 seconds (we encourage ~60 s).
If a recording is shorter than the threshold, the system flags it (and the app likely already enforced this by not accepting the recording if too short). The user can be prompted to retry if possible. These thresholds ensure we have enough data to extract meaningful features.
Channel Check: Ensure the audio is mono. If a stereo file is detected, we automatically downmix it to mono (taking an average of channels or left channel) and log that action. Stereo files are not left as-is because differences between channels can confuse analysis.
DC Offset Check: Compute the average amplitude of the signal. A significant DC offset (non-zero mean) can indicate a hardware or recording issue (or a poorly calibrated mic). Specifically, if the mean amplitude is more than ~1% of the max amplitude, we flag a DC offset issue. While this is rare with modern devices, it's included for completeness. A DC offset can be corrected by high-pass filtering if needed.
Automated Feature Checks: After feature extraction, we also validate the outputs:
Range Validation: For each feature, we define plausible physiological ranges and flag values outside them:
For example, if F0_mean for an adult female is detected as 20 Hz or 1000 Hz, that's likely an error (normal adult female F0 is ~75–300 Hz). So we would flag an F0_mean of 20 as "out-of-range" (maybe the pitch tracker failed or picked up a wrong octave). Our general cutoff might be ~75–500 Hz for female F0.
Jitter above, say, 5% or shimmer above a certain dB, might be extremely high (typically normal voices jitter < 1% in sustained vowel; >5% would be very pathological or an error).
HNR below 0 dB is essentially saying noise is as strong as signal; most normal phonations should have HNR well above 0 (e.g., 10-20 dB). If HNR comes out negative or near 0, either the person whispered or the measurement is off. We flag those cases.
These range checks catch cases where maybe the wrong units or a mis-detected fundamental frequency skewed things.
Consistency Check: We compare select features obtained via different methods as a sanity check. For example, Praat's computed F0 vs openSMILE's pitch output:
If Praat says mean F0 is 220 Hz but openSMILE's corresponding feature is 440 Hz, something's off. They should roughly agree (within a few Hz or a few percent). Large discrepancies might mean the openSMILE config wasn't aligned (e.g., wrong gender setting) or there was an analysis glitch. We investigate such cases.
Similarly, if we have two ways to get jitter (Praat vs. maybe an openSMILE LLD for jitter), they should correlate; if not, flag.
This redundancy helps ensure our pipeline is working as expected. If inconsistency is found, that recording is flagged for manual review (and it might indicate a need to adjust the algorithm).
Manual Review: Automated checks are great, but we also incorporate human oversight:
We schedule manual quality audits for a random sample of ~10% of recordings. A trained reviewer (could be a speech scientist or our team member) listens to the audio and looks at its features. They verify:
Does the audio quality match the metadata? (E.g., if the user said they were in a quiet room, do we indeed hear a quiet background?)
Do the measured features make sense perceptually? (E.g., if the system measured F0_mean = 180 Hz, does the voice actually sound like around 180 Hz? If jitter was flagged high, does the voice sound rough?)
Any anomalies like sudden microphone glitches or background events that the system might not fully capture can be noted.
These reviews are logged and used to improve the pipeline (for example, if we notice a pattern of false alarms in flags).
We also manually inspect any outlier data points that automated checks highlight. For instance, if one day a user's jitter jumps way higher than their other days, our pipeline flags it. The team can listen to that specific file to determine if it's a real vocal change (maybe they had a sore throat causing roughness) or an artifact (maybe there was background noise or the user bumped the mic). Based on that, we either accept the data or mark it as an anomaly to exclude.
All manual review findings feed back into potentially refining the automated checks or adding notes to data (e.g., "file X had a faint TV noise that passed the SNR check but reviewer heard it").
Pipeline Unit Tests: On the development side, we maintain a suite of unit tests for the feature extraction process (located in tests/feature_validation/, see §7 Directory Structure). These tests are run in continuous integration and are designed to catch errors in the analysis code:
For example, one test generates a pure tone (say 220 Hz sine wave) as an input WAV and runs it through the pipeline. We expect the output features to match the known properties: F0 ~220 Hz, jitter ≈ 0%, shimmer ≈ 0 dB, HNR very high (since a pure tone has almost no noise). The test will assert that the results are within a small tolerance. If a code change accidentally alters, say, the pitch algorithm, this test might start failing.
Another test might use a reference recording: we have a short audio file for which we previously measured features with Praat manually. Our pipeline processes it and we assert that our outputs match the known Praat values closely. For instance, if Praat said F0=200 Hz and jitter 1%, our pipeline should output ~200 Hz and ~1% for those features (within an acceptable difference, e.g., 0.5%).
We also test edge cases: silence (should yield undefined or default values that we handle), very short clip (should be rejected), etc.
These tests help ensure the implementation matches the standards described in this document. When adding a new feature or algorithm, corresponding tests should be added.
By enforcing these validation steps, we ensure the dataset remains clean, reliable, and scientifically credible. Data not meeting quality standards will either be automatically excluded or marked with flags, so that our analysis and conclusions are drawn only from high-quality data. AI Guidance: Any code written for data ingestion or preprocessing should incorporate these checks. For example, if you're coding the cloud function that handles uploads, include routines for each bullet above (format, clipping, noise) and reference §3.4 in comments:
if clipping_ratio > 0.001: 
    log("Flagging clipping per DATA_STANDARDS.md §3.4") 
Similarly, if writing unit tests (or AI generating test code), ensure tests cover the scenarios mentioned (pure tone test, reference file test, etc., as per §3.4). In continuous integration setup, include a step to run these tests on every commit. The assistant or developer should not bypass these validations; they are mandatory. If an AI proposes code that doesn't include them, it's non-compliant. Always check new code against §3.4 and §4 to verify quality control measures are in place. Section Summary: Every recording and its extracted features are put through rigorous quality checks – from ensuring proper format and quiet environment, to catching clipped or too-short recordings, to flagging implausible feature values. We also maintain unit tests and manual review procedures to verify that the feature extraction pipeline is working correctly. These validation measures safeguard the integrity of our dataset, so that any patterns we find (e.g., jitter changes across the cycle) are based on real, high-quality signals rather than artifacts or noise.
4. Validation & Quality Control (Pipeline-Level)
In addition to the per-recording checks in §3.4, we implement system-level validation and quality control to ensure the entire pipeline (from recording to feature output) is functioning correctly and consistently. Unit Tests for Feature Algorithms: We maintain an extensive suite of unit tests targeting our feature extraction code (see tests/feature_validation/ in the repository):
Pitch & Formants: We programmatically generate synthetic audio to validate our pitch and formant analysis. For example, we create a pure tone at 220 Hz (a sine wave, perhaps with a slight fade in/out). The test then runs our pipeline's pitch extraction and also runs Praat's pitch detection on the same audio. We assert that the difference between our pipeline's F0_mean and Praat's result is below a tiny tolerance (e.g., within 1 Hz or 0.5%). We do similarly for formants: generate a synthetic vowel sound with known formant frequencies (or use a vowel audio where we measured formants via Praat manually) and ensure our formant tracking produces those values. This guards against any drift in our configuration (for instance, if openSMILE config was wrong, this test would catch that formants are off).
Jitter & Shimmer: We test perturbation measures by either taking a known reference voice sample or creating a synthetic one. For instance, we might take a stable pure tone and artificially modulate its frequency slightly to introduce a known jitter percentage. Or simpler: use a real voice recording where we've run Praat's "Voice Report" manually. Our pipeline's jitter% and shimmer dB outputs are compared to Praat's ground truth. They should match closely (within a margin like ±0.1% for jitter, ±0.1 dB for shimmer, or a few percent relative error). This ensures that our integration of Praat (or any jitter calculation) is correct. If someone inadvertently changed a parameter, this test would likely fail.
OpenSMILE vs Alternative: For some features, we cross-validate against alternative calculations. For example, MFCCs – we can compute MFCCs with librosa on a test clip and compare to openSMILE's MFCC output on the same clip. They won't be identical (different implementations nuances), but we expect general consistency. Similarly, if openSMILE yields a feature like "spectral centroid", we could also compute it via our own small function and compare.
Benchmarking with Standard Datasets: Periodically, we run the pipeline on a known public dataset (if available) to compare with published values. For instance, the VOICE (Voice Disorder Evaluation) dataset or others have known jitter/shimmer values reported in literature. The eGeMAPS paper itself gives ranges for features on normal vs disordered voices. We compare our results on a sample of such data to ensure we align with expectations. If our computed means and SDs for normal voices fall wildly outside published ranges, it flags an issue.
Inter-Device Consistency: We conduct controlled tests recording the same person speaking the same script on different devices (different iPhone models, possibly an external mic if allowed). Then we run those through the pipeline to ensure that, ideally, the features come out similar. If we do find systemic biases (e.g., iPhone model A consistently yields slightly higher HNR than model B for identical input), we document it and consider calibration factors. This isn't a unit test in code, but rather a periodic QA activity. However, we might incorporate some automated check if metadata shows multiple devices for one user: compare their distributions.
Data Integrity Scripts: We have utility scripts under research/validation/ for dataset-level QC:
Check that for every audio file there is a corresponding feature file and vice versa (no missing data).
Check naming consistency (file names match the pattern and metadata).
Verify metadata ranges (e.g., ages are within expected bounds, no negative symptom ratings, etc.).
Detect duplicate recordings (perhaps by hashing audio content). If two different session IDs have identical audio (user accidentally uploaded same file twice), flag it.
These scripts are run before any major analysis or release of data.
Reproducibility Tests: We simulate full pipeline runs to ensure determinism. For example, we might take a single audio file and run the entire feature extraction twice (perhaps in two different environments or two different days) and confirm the outputs are bitwise identical (except for allowed floating-point rounding differences). We ensure any randomness (like if we ever add an ML model) is controlled by fixed random seeds. This way, given the same input and same pipeline version, the output will always be the same – a key aspect of scientific reproducibility.
Continuous Integration (CI): Every code commit triggers our CI system to run all unit tests and a quick end-to-end test on a sample file. For example, the CI might take a short audio stored in the repo, run the feature extraction script, and check that the output matches a reference output (that we have saved from a known good run). If any difference beyond tolerance is found, the CI fails. This prevents unverified code changes from being merged into the main branch, acting as a safety net. It also runs the basic checks (so if someone's change accidentally breaks the reading of audio or the output format, we catch it immediately).
All validation procedures and any changes to them are documented in our change logs. In particular, the RESEARCH_CHANGELOG.md (in the repo) records pipeline changes and updates to this standards document. If an anomaly is found and we adjust a threshold or add a new check, we log it for transparency. By enforcing these pipeline-level QC measures, we maintain scientific rigor, catching issues early and guaranteeing that the speech-derived metrics are trustworthy for research and eventual user feedback. It's not enough that our code runs; we require that it runs correctly and consistently over time. AI Guidance: When developing new features or modifying the pipeline, do so in a test-driven way. If you (or an AI assistant) add a new feature extraction step, also add a unit test for it (as described above) referencing §4 to see expected behavior. For instance, if adding a new "spectral flux" feature, create a known scenario and ensure the feature output matches expectation. In code review, any changes to the pipeline should be accompanied by updated tests and an update to this document's relevant section (and an entry in the changelog). Tools like AI can help generate tests as well, using the spec here (e.g., "Write a test that our jitter output equals Praat's output within 0.1% – see DATA_STANDARDS.md §4"). Always integrate such prompts in development to keep standards and implementation aligned. Section Summary: We don't just assume our pipeline works — we prove it through unit tests, cross-validation with established tools, and continuous integration. We regularly validate that pitch, formants, jitter, etc. are computed correctly (by comparing to Praat and known values), and we verify that results are consistent across devices and code versions. By building quality checks into the development process, we ensure that our data and findings are robust. In short, Section 4 ensures that "no news is good news" – if all tests pass, we have a high degree of confidence in our pipeline's accuracy and reliability.
5. Reproducibility & Versioning
To preserve scientific integrity, we treat the voice analysis pipeline (data processing and feature extraction code) as a versioned, controlled component of the project. This section describes how we manage changes over time so that results can be reproduced exactly and any updates are transparent.
Pipeline Versioning: We assign a pipeline version to the analysis code, and increment it with each significant change. For example, the initial release might be v1.0. If we later adjust how pitch is calculated (say we change a setting or algorithm) or add a new feature, we update to v1.1, v1.2, etc. The pipeline version is recorded as part of the feature output (e.g., in each feature CSV header or a metadata field). This allows us (and any external collaborator) to know exactly which version of the algorithm produced a given dataset. When we train models or generate results for a paper, we always note the pipeline version used. This practice ensures that if there are differences in results, we can trace if a pipeline change might be the cause.
Change Log: All modifications to this DATA_STANDARDS.md document or to the analysis pipeline code are logged in RESEARCH_CHANGELOG.md in the repository. Each entry includes the date, the pipeline version (if it changed), and a summary of what was modified. For example: "2025-03-15: v1.1 – Updated jitter algorithm to Praat's latest method; added formant features; adjusted noise floor threshold from 15 dB to 20 dB based on new validation data." If a change could affect previously obtained results (e.g., broadening the pitch range might slightly change F0 values for some recordings), the changelog note will mention that. We strive to re-run analyses on existing data when such changes occur or at least document the expected impact.
Code Version Control: The code (in research/ and functions/ directories) is under Git version control (hosted on our repository). We use Git tags or releases to mark commits corresponding to each pipeline version. For example, when we finalize v1.0 of the pipeline, we create a Git tag pipeline-v1.0 (and likely a release on GitHub). If we update to v1.1, we tag that commit as pipeline-v1.1. This way, anyone can check out the repository at that tag and get the exact code used for that pipeline version. The tags are referenced in publications or internal reports when specifying the pipeline.
Reproducible Environments: We pin specific versions of all dependencies in our environment configuration (such as requirements.txt for Python packages, or a Dockerfile with exact versions of Praat, openSMILE, etc.). This is crucial because an external library update could otherwise change our outputs. For instance, if a new version of Praat changed its pitch algorithm slightly, it could alter results. We either stick to the tested version or, if upgrading, we do a validation to ensure consistency (or document differences). Our Dockerfile (or Conda environment) ensures that someone in the future can set up the same environment as we used. We also often include a note like "Praat 6.3.0, openSMILE 3.0.1, librosa 0.10.0" in this document and the changelog when relevant.
Reference Data & Results: We maintain a set of reference inputs and outputs in the repository under research/reference_data/. For example, we include a few sample audio files (with user consent, anonymized) and the expected feature outputs (CSV files) for the current pipeline version. When the pipeline changes, we update these reference outputs accordingly (and bump the version). This acts as a built-in regression test and demonstration: at any time, one can run the pipeline on the reference audio and compare the output to the checked-in reference output. If it matches, the environment and code are set up correctly. If not, something is different (either a version mismatch or a bug). This also helps new contributors understand the expected format and scale of features.
Documentation in Code: Every significant function or module in the analysis code includes comments or docstrings that reference the relevant section of this standards document. For instance, the docstring for the pitch extraction function might read: "Implements pitch analysis as per DATA_STANDARDS.md §3.2.1 (Praat autocorrelation, 75–500 Hz range)". Similarly, code that handles audio input might have a comment "// See DATA_STANDARDS.md §2.1 for format requirements". This is a practice we enforce so that someone reading the code can cross-reference the standard immediately. It also helps code reviewers to verify that the code actually follows the documented standard (since the section number given should describe the expected behavior).
Data Export for Publication: If (and when) we publish research findings based on this data, we ensure the published dataset includes the necessary documentation. We will export the anonymized feature dataset (numbers only, no raw audio unless consented) and include documentation of the pipeline version that produced it, as well as this standards document. If we share raw audio for any reason, it will come with the code or pipeline so others can reproduce our feature extraction. Essentially, anyone reading our paper or report should be able to use our pipeline code to get the same results from the raw data. This openness is critical for scientific reproducibility.
In summary, any analysis performed by Sage's pipeline can be reproduced step-by-step given the versioned code and data. Strict version control and documentation ensure that as the project evolves, prior results remain valid (or are updated with clear justification). If a discrepancy is found, we can pinpoint whether it's due to data, code, or environment changes, because each is tracked. AI Guidance: Never assume changes are "too small" to document. If an AI assistant suggests an optimization or a tweak (say, changing a threshold or adding a feature), it should also suggest incrementing the version and updating the changelog (and this document). For instance, if an AI writes: "Optimized pitch tracking for speed", it must also note "Update pipeline version to 1.x due to algorithm change." Always produce code with a mindful eye on reproducibility: e.g., ensure random number seeds are fixed, outputs are deterministic, and logs or outputs mention pipeline version. When assisting with paper writing or reports, instruct that text like "we used pipeline version 1.2 (commit abcdef on GitHub)" is included. By maintaining this discipline, we uphold the credibility of our results. Section Summary: We treat our analysis pipeline like a published method: each update is versioned, logged, and tied to code commits. This allows exact reproduction of any result and clear communication of any changes. For developers and AI alike, the rule is traceability – every value in our dataset can be traced to a specific code version and documented procedure. This protects us from "it worked on my machine" issues and ensures long-term reliability of the project's findings.
Section 5.1 Documentation & Commenting Guideline
(Explicit Instruction Reminder)
All code comments and function docstrings should cite this standards document. For example:
In code: # Implements jitter extraction as per DATA_STANDARDS.md §3.2.2
In code: // See DATA_STANDARDS.md §2.1 for audio format requirements
This creates a strong link between implementation and specification. Developers and AI assistants must follow this practice. It will be part of the code review checklist (see §9 Compliance Checklist). The referencing format should include the exact section (and subsection if applicable) to be precise. This way, if someone questions why a piece of code is written a certain way, the answer is right there in the comment pointing to this document. (The above guideline is reiterated here to emphasize compliance as code is written or reviewed.)
6. Privacy & Compliance
Given the sensitive nature of health data and voice recordings, we enforce strong privacy measures and comply with relevant regulations. All contributors must consider privacy at every stage, from data collection to analysis and storage.
User Consent: Every user must provide informed consent within the app before any recording or data upload occurs. The consent process (approved by an Institutional Review Board or ethics committee if required) clearly explains:
What data is being collected: e.g., voice recordings, symptom journals, demographic info.
How the data will be used: e.g., for academic research on women's health and to provide personalized insights back to the user.
How the data will be stored and protected.
The voluntary nature of participation (the user can withdraw at any time).
Users explicitly agree to their audio and questionnaire data being analyzed for research purposes. We also inform them that they can opt out later and request deletion of their data. No recording happens until consent is given (the app's UI and backend enforce this).
Anonymization: We separate personal identifiers from research data. Each user is assigned a random unique identifier (e.g., a UUID or a short code like U1001 as seen in file names). This ID is used in filenames and database entries instead of any personally identifying information. The mapping between user IDs and personal info (name, email, etc.) is stored in a secure, access-restricted system (for example, the app's private database) and is never included in analysis exports or logs. Voice data itself is considered personally identifying (a voice can potentially be recognized or matched to a person), so we treat the voice recordings with the same caution as personal info. If we ever share audio with external researchers, we will consider techniques like voice distortion to "de-identify" the audio, unless sharing the actual voice is essential (and explicitly consented to). Usually, we prefer sharing extracted features (which are just numbers, not directly reconstructable to voice).
Data Encryption: All data transmissions and storage are encrypted. The app uses HTTPS for uploading recordings to the server. On the server/cloud, recordings and feature files are stored in encrypted form (e.g., in an encrypted S3 bucket or database). Access to the raw data is restricted – only authorized team members or services (like our analysis pipeline) have credentials to access it. Within the team, we follow the principle of least privilege: e.g., a developer working on the iOS app doesn't automatically get access to the raw dataset; they'd need approval and a valid reason. We keep audit logs of who accesses what data.
Minimal Retention: Raw audio data is considered high sensitivity. Our policy is to not retain raw audio longer than necessary. For instance, once a recording has been processed and features extracted, the raw .wav might be deleted from the analysis server after, say, 24 hours. We only need to keep the numeric features for research, which are less sensitive (though still treated carefully). If we decide to keep raw audio for QC purposes, we anonymize it and store it securely, but we aim to delete it as soon as it's no longer needed. Users are informed of this policy (e.g., "Your voice recordings are not kept on our servers long-term; we extract the features we need and remove the actual audio to protect your privacy."). This way, even if there were a breach, the most sensitive content (the actual voice) is not sitting around indefinitely.
User Access & Control: Through the app, users can review their submitted recordings and data (possibly by seeing summaries or listening to their own recordings). More importantly, they have the right to request deletion of all their data. We honor such requests promptly:
If a user deletes their account or requests data removal, our backend will delete all of that user's data (voice files, feature entries, metadata) from the production database and any analysis datasets. We'll also remove them from any backups or at least ensure backups beyond a certain point don't contain their data (GDPR's "right to be forgotten").
We design the system to make this feasible – e.g., data is partitioned by user ID, so it can be located and purged.
Regulatory Compliance: We adhere to relevant data protection regulations:
HIPAA: While our app may not strictly fall under HIPAA (it's a consumer research app, not a healthcare provider or insurer), we choose to treat health-related data with HIPAA-like safeguards as a best practice. That means we consider voice and symptom data as Protected Health Information. We do not share it with third parties except as allowed by the consent. If we ever partner with a clinician or do something that edges into healthcare, we'll ensure compliance fully.
GDPR: For users in the EU (or any users, since we apply high standards globally), we ensure compliance with GDPR:
We have a clear Privacy Policy that explains what data we collect and why.
We obtain unambiguous consent (users actively tap "I Agree" after reading the consent form).
We allow users to exercise their data rights: accessing their data (we could provide them a copy of their feature data on request), correcting it (though there's not much to correct in voice data except maybe their profile info), and deleting it (as mentioned).
We fulfill the "right to be forgotten" by actually erasing data on request and not retaining it.
We have a lawful basis for processing (consent for research, and arguably legitimate interest for improving women's health, but consent is primary).
App Store Guidelines: We ensure compliance with Apple's rules: we include a Privacy Policy in the app description, we display the little microphone indicator and the iOS permission dialog with a clear explanation ("This app records your voice to analyze health-related voice features. No recordings are made without your consent."). We do not record in the background or without the user explicitly starting a task. We don't share data with third-party advertisers or such. Essentially, we ensure the user is never surprised by data collection – it's all explicit and under their control.
Data Use and Sharing: The data collected is used only for the stated purposes: to advance women's health research and to provide insights to the users themselves. We do not sell the data or use it for unrelated purposes (like marketing). If we collaborate with academic researchers or other institutions, we will do so under strict Data Use Agreements (DUAs) that outline exactly what can be done with the data and prohibit any attempt to re-identify users or misuse the data. Typically, we would share only derived, anonymized data. If individual-level data (even without names) is shared for research, we will get IRB approval and, if needed, additional consent from users. In publications, we only present aggregate results or example snippets with permission.
Security Audits: We perform regular audits of our system's security. This includes:
Ensuring all public-facing endpoints (like the API that receives uploads) have proper authentication and cannot be used to fetch data without authorization. (E.g., users can only retrieve their own data, and that too with secure tokens).
Periodically reviewing access logs to ensure no unauthorized access occurred. We log access to sensitive data – for example, if a developer pulls some data for analysis, that access is recorded.
Using security best practices on the server (up-to-date encryption, rotating keys if needed, principle of least privilege on cloud services, etc.).
If we ever detect a security issue, we address it immediately and inform users if it's something that affected them (as per breach notification laws).
By embedding privacy into our design and procedures, we ensure users can trust Sage with their voice and health information. This is not only about legal compliance, but also about ethics and user confidence. A breach of trust could harm participants and jeopardize the study, so we treat data protection as paramount. AI Guidance: Any code that deals with user data must incorporate these privacy measures. For example, if writing a script to export data, ensure it excludes personal identifiers (and perhaps reference §6 in a comment to justify that filtering). If an AI is used to analyze data, it should not expose any raw user identifiers or sensitive content in outputs (unless specifically authorized in a secure context). AI assistants should refuse requests that violate these policies (for instance, if someone asked the AI to identify a user from their voice data, it should decline). In development discussions, always plan new features with privacy in mind (e.g., "we want to add location data – how does that impact privacy? need updated consent?"). We also require that any external code or library we integrate is compliant (for example, if using a cloud speech API, ensure it meets privacy standards or that we don't send raw audio to third parties). Always document data flows and include privacy-related comments, such as # Anonymize user ID as per DATA_STANDARDS.md §6. Section Summary: We implement strict privacy safeguards at every step: users give informed consent, data is anonymized and encrypted, raw audio is not kept longer than needed, and users can delete their data. We adhere to regulations like GDPR and treat health data with the utmost care. For developers, this means always building systems with privacy by design. Compliance isn't just a legal checkbox, but a core principle of the project to respect and protect our users. Any feature or code that touches user data must be evaluated through this lens.
7. Directory Structure
The project repository is organized to separate the mobile app, cloud functions, and research analysis code. Understanding this structure is important for knowing where to add new files or find existing ones. Key directories and files are as follows:
Sage/                        # Root of the repository (name of the project)
├── README.md                   # Main project README (high-level overview)
├── DATA_STANDARDS.md           # (This file) Detailed research and data standards
├── Sage/                       # iOS app source code (Swift/Objective-C)
│   ├── ...                     # (UI view controllers, models, etc.)
│   └── Resources/              # Resources (e.g., text of user prompts, consent forms)
├── functions/                  # Cloud Functions (serverless backend, Python)
│   ├── audio_upload.py         # Handles audio upload, triggers processing
│   └── analysis_trigger.py     # Initiates feature extraction pipeline after upload
├── research/                   # Research and analysis scripts (Python)
│   ├── feature_extraction/     # Scripts for extracting features from audio
│   │   ├── extract_features.py       # Main script that calls OpenSMILE, Praat, etc.
│   │   ├── opensmile_config/         # Config files for OpenSMILE (e.g., eGeMAPS config)
│   │   └── utils/                   # Utility functions (e.g., audio loading, filtering)
│   ├── validation/           # Scripts for data validation and QA (additional checks)
│   ├── analysis_notebooks/   # Jupyter notebooks for exploratory analysis, prototyping
│   └── reference_data/       # Sample audio and expected feature outputs (for testing)
├── tests/                      # Automated tests for the project
│   ├── test_feature_pipeline.py    # Unit tests for feature extraction correctness
│   └── feature_validation/         # Directory with reference outputs, etc. for tests
└── RESEARCH_CHANGELOG.md      # Log of changes to DATA_STANDARDS and pipeline versions
(The above structure omits some files for brevity, focusing on those relevant to data and analysis. The iOS app directory contains the UI and local logic, while data processing lives in the cloud functions and research scripts to maintain transparency and reproducibility.) A few notes on this structure:
The mobile app (iOS) code under Sage/ handles all user interaction: recording audio, getting consent, showing prompts, uploading data. It is kept lightweight – it doesn't do heavy analysis on the device. Instead, it sends data to the cloud for processing.
The cloud functions (under functions/) are our backend. For example, when the app uploads an audio file, audio_upload.py might handle the HTTP request, save the file, then call analysis_trigger.py (or directly call the feature extraction) to process that file. These functions run on a serverless environment (like AWS Lambda or Google Cloud Functions), which allows scaling and keeping the app simple.
The research directory is where most of the analysis logic resides. We chose to separate this from cloud functions for clarity and easier iteration. For example, research/feature_extraction/extract_features.py can be run in a research environment (like on a local machine or research server with the audio files) as well as invoked by the cloud function. The opensmile_config contains configuration files needed by openSMILE (like the XML or conf file describing which features to extract).
research/validation/ might include scripts that do dataset-wide checks or generate summary reports of data quality (these could be run periodically).
analysis_notebooks/ is a place for Jupyter notebooks, which are not part of production pipeline but for analysis and prototyping by data scientists. For example, after collecting data, we might have a notebook to visualize how pitch changes over the cycle.
reference_data/ contains some example audio clips and the expected output features for those (as discussed in §5). It's used for testing and demonstration.
The tests directory contains automated tests. test_feature_pipeline.py is a central test suite that likely calls the extract_features script on known inputs and verifies outputs (as described in §4). The feature_validation/ subdirectory can hold reference output files or additional test data needed for those tests.
RESEARCH_CHANGELOG.md is a human-readable log of changes (like an appendix to this document). It is updated whenever the data standards or pipeline code is changed, summarizing what changed and why (see §12 Changelog).
Cross-references: When reading or writing code, you'll see references to these directories. For instance:
The AI prompts in §8 often mention paths like research/feature_extraction/extract_features.py or tests/feature_validation/test_feature_pipeline.py. These correspond exactly to the structure above.
If you add a new analysis script (say to compute a new feature or run a model), it should go into a logical place in this structure (perhaps a new subfolder under research).
If adding new tests for that script, put them under tests/.
The directory layout ensures that analysis code and configuration (which researchers might want to inspect or run) is clearly separated from the app. This supports our transparency and reproducibility goals.
AI Guidance: When generating code or documentation, refer to the directory structure to place things correctly. For example, if asked to generate a new feature extraction function, the AI should output it as a file path research/feature_extraction/utils/new_feature.py (for instance) and ensure imports align with this structure. If writing a test, place it under tests/. In code comments, if relevant, mention where something resides: e.g., "See reference_data/ in repo for example inputs". This helps new developers (or any auditor) quickly find what they need. Also, do not propose storing data or code in ad-hoc locations – follow the structure. For instance, raw data from users is likely stored in a secure cloud storage, but processed data might be downloaded to research/reference_data/ for local analysis; we wouldn't put that in random places. Keep things organized as above. Section Summary: The repository is organized in a clear, logical way: mobile app code is separate from analysis code, and there are dedicated places for cloud functions, research scripts, and tests. This modular structure ensures different teams (app developers vs. data scientists) can work relatively independently and that the heavy data processing is done in a controlled, versioned environment (not on the end-user's device). Adhering to this structure (adding new files in the right place, maintaining naming conventions) is important for maintaining clarity. It also makes it easier for anyone (including an AI assistant) to navigate the project. In practice, always put new code and data in the appropriate directory as defined above, and update documentation if needed when the structure evolves.
8. AI/Developer Prompts
(This section is a unique inclusion: it provides structured prompts for using AI tools—like Cursor or GPT-4—to assist with development tasks. By referencing specific sections of this document within the prompts, we ensure any AI-generated output remains compliant with our standards.) The following are example prompts and guidelines for developers or integrated AI assistants to follow, in order to maintain consistency with the standards:
Feature Extraction Code Generation
Prompt (to AI):
"Generate a Python script in research/feature_extraction/ that extracts acoustic features as per DATA_STANDARDS.md §3.2. Include pitch, jitter, shimmer via Praat (through parselmouth) and MFCCs via openSMILE. Use the parameters specified (25 ms window, 10 ms hop, etc.) and output a CSV in the format described in §3.3."
Expected Outcome: The AI will produce code for extract_features.py that calls the Praat library for F0, jitter, shimmer (with correct settings from §3.2.1–3.2.3) and uses openSMILE for MFCCs, and writes a CSV with columns as defined. The prompt explicitly points the AI to §3.2 and §3.3, ensuring the code aligns with those details.
Unit Test for Pitch Accuracy
Prompt:
"Write a unit test in tests/feature_validation/test_feature_pipeline.py that uses Praat to extract pitch from a test WAV file and compares it to our pipeline's pitch output (see DATA_STANDARDS.md §3.4 for validation approach). Ensure the difference is within a small tolerance."
Expected Outcome: The AI will create a test function that perhaps synthesizes a tone or uses a small WAV from reference_data/, runs our extract_features.py (or the relevant function) to get F0_mean, and also runs parselmouth (Praat) on the same file to get an independent F0. It will then assert that the values differ by less than, say, 1%. Citing §3.4 guides it to the fact we do such comparisons as part of validation.
Data Validation Integration (Cloud Function)
Prompt:
"Modify the audio upload cloud function to perform validation checks described in DATA_STANDARDS.md §3.4. Specifically, add a step to measure ambient noise (e.g., during the first 0.5s of recording) and reject the file if estimated SNR < 20 dB, or if duration < required minimum."
Expected Outcome: The AI would produce an updated snippet for functions/audio_upload.py where after receiving the file it computes noise level (maybe using a simple RMS calc on a short segment), checks the duration metadata, and implements logic to either proceed or return an error to the app. It would include comments referencing §3.4 for each check (e.g., # Check SNR as per §3.4).
Documentation and Code Comments
Prompt:
"Add comments to the extract_features.py script explaining the purpose of each feature, referencing DATA_STANDARDS.md by section. For example, comment that jitter and shimmer calculations follow §3.2 standards and cite relevant research references from §1."
Expected Outcome: The AI would insert comments in the code like:
# Computing jitter (%): using Praat's method (per DATA_STANDARDS.md §3.2.2). Jitter reflects pitch stability; see §1 (Chae et al. 2001) for why this matters.
And similarly for shimmer, pitch, etc. This enriches the code with context and traceability.
Refactoring Output Format
Prompt:
"Refactor the analysis pipeline code to output feature files in the format specified in DATA_STANDARDS.md §3.3. Ensure the filename convention and CSV columns match the documentation. Update any downstream code (tests, data upload) to handle the new naming scheme."
Expected Outcome: The AI would adjust file naming in the code to {userID}_{task}_{timestamp}_features.csv, ensure the CSV writer includes the header with correct column names (F0_mean, etc. as listed in §3.3), and then find any code that assumed a different format and update it. For example, if previously the code named files differently, it would change that and then adjust tests expecting those names. By referencing §3.3, it knows exactly what schema to implement.
Reproducibility Check Script
Prompt:
"Given an audio sample and a set of features from a previous pipeline version, write a script to re-run the new pipeline on that sample and compare outputs. If differences exceed a threshold, log them. This script helps ensure changes conform to DATA_STANDARDS.md §5 (versioning policy)."
Expected Outcome: Perhaps a script in research/validation/ that takes an input audio and a reference feature CSV (from an older version), runs the current extract_features.py, then compares the feature values field by field. If any value differs more than, say, 1% (or any significant change), it logs something like "Feature X changed from Y to Z after pipeline update from v1.0 to v1.1". This prompt specifically links to §5, reminding the AI that this is about ensuring consistency across versions or noting when a version change alters outputs (which should be documented).
These prompts (and others like them) guide development such that any AI assistance remains grounded in the project's rules. We integrate them into our workflow—for instance, as comments in code or as part of pull request templates—to remind developers to follow the standard. AI Guidance: If using an AI coding assistant, always include section references in your requests, as shown. This not only ensures the assistant follows the spec, but also documents in the conversation or commit which part of the standard you are addressing. For example, a commit message might say "Implemented ambient noise check (per DATA_STANDARDS.md §3.4)". This practice creates a paper trail linking code changes to the standard. Section Summary: Section 8 provides a bridge between this standards document and practical usage of AI tools in development. By crafting prompts that explicitly reference sections of this document, we ensure that AI-generated outputs adhere to our requirements. It's like having this document "in the loop" whenever code is being written or reviewed by AI. Developers are encouraged to use and adapt these example prompts when interacting with AI coding assistants to maintain compliance and consistency. (Note: The "AI prompts" in this section are for internal development use and are not shown to end-users of the app. They serve as guidance to efficiently implement and verify the strict standards outlined in this document.)
9. Compliance Checklist
This checklist distills key requirements from the above sections into actionable items. Developers and reviewers (human or AI) should use this to verify that all contributions meet the standards. Before merging code or considering a feature complete, go through each relevant item:
 Recording Format & Environment: All audio recordings are 48 kHz, 24-bit mono WAV and made in a quiet environment (<40 dB ambient noise) as per §2.1. (If any audio does not meet this, the pipeline converts or rejects it and logs a warning.)
 User Instructions Compliance: The app's UI and flow enforce the voice task protocols (sustained vowel ~5 s, reading ~30 s, spontaneous ~1 min) exactly as described in §2.2. Prompt texts in the app match those in the document, and task durations are validated.
 Metadata Capturing: Each session's metadata includes age, gender, health info, device model, cycle day/phase, symptom ratings, timestamp, etc., according to §2.3. This metadata is stored in an analysis-accessible form, and no personally identifying info is present in analysis outputs (IDs only).
 Feature Set Completeness: All acoustic features listed in §3.2 are being extracted and saved. This includes pitch (mean/min/max/SD), jitter, shimmer, HNR, formants, MFCCs, intensity, speaking rate, voice breaks, spectral features, etc. No required feature is missing from the output.
 Feature Method Accuracy: Each feature is calculated using the specified tool/method and parameters (check code against §3.2 subsections):
Pitch via Praat autocorrelation (75–500 Hz range).
Jitter & Shimmer via Praat default perturbation (local % and dB).
HNR via Praat.
Formants via Praat LPC (appropriate settings).
MFCC via openSMILE (13 coeffs, 25ms frame, etc.).
Intensity via RMS (converted to dB).
Speaking rate via VAD or transcript analysis (pause threshold ~0.3 s).
etc.
If any custom code is used instead of the recommended tool, there must be documentation justifying it and it should produce equivalent results.
 Output Format: Feature output files follow the naming and schema in §3.3:
Filenames are {userID}_{task}_{timestamp}_features.csv (or .json if applicable).
CSV headers use descriptive names matching the standard (F0_mean, jitter_pct, etc.).
Each feature file includes userID, session timestamp, task, and pipeline version metadata (either in filename or inside).
Frame-level vs summary outputs are handled as specified (e.g., no unexpected mixing of frame and summary data without clear format).
Example outputs in testing match the format given in the documentation.
 Automated Data Validation: All checks from §3.4 are implemented:
Format check on audio (with conversion or rejection).
Clipping detection (>0.1% samples at max -> flag).
Noise/SNR check (SNR < 20 dB or noise > 40 dB -> flag).
Duration check (with specified min seconds per task -> flag or re-prompt).
Mono audio enforcement (downmix if needed).
DC offset check (flag significant offsets).
Feature range checks (e.g., F0 within plausible bounds, jitter% not outrageous unless real).
Consistency checks between redundant measures (Praat vs openSMILE outputs).
Logging or flagging mechanism in place for all above (and user feedback if needed, e.g., app tells user to retry in quieter setting).
Unit tests exist for critical validations (e.g., synthetic tone test for jitter=0, see §4).
 Quality Control Tests: The pipeline passes all unit and integration tests described in §4:
Synthetic audio tests (pure tone, synthetic vowels) produce expected feature outputs (within tolerances).
Pipeline results align with Praat/manual calculations for test cases (pitch, formants, jitter, shimmer).
Reference dataset comparisons show no unexplained divergences.
Cross-device tests (if automated or manual) show consistent performance (any known differences are documented).
CI pipeline is set up and running tests on each commit.
Any new feature or change is accompanied by new tests or updated reference outputs.
 Versioning: If any change has been made to the pipeline or this document:
The pipeline version number is incremented appropriately (§5).
The change is recorded in RESEARCH_CHANGELOG.md with date, author, description.
The code repository is tagged for the new version.
Dependencies are pinned if a new tool/version was introduced.
Reference outputs are updated if the change affects them.
 Code Documentation: Every function, module, or significant code block that implements a standard has a comment or docstring citing this document (§5.1):
E.g., functions computing features reference §3.2 subsections.
Data validation code references §3.4.
Cloud functions mention §2 or §6 where relevant (upload handling referencing privacy, etc.).
These references use the format DATA_STANDARDS.md §x.y as required. This item ensures maintainers can trace code to spec easily.
 Privacy Compliance: All data handling follows §6:
No personal identifiers in outputs or logs (userIDs used).
Raw audio deletion after processing is implemented (or ticketed in backlog if not immediate, with a clear plan).
Users can request deletion and there's a tested method to scrub their data.
Consent is verified in the app before recording.
Any data exports for collaborators strip or anonymize personal info and are under proper agreements.
Security measures (encryption, access control) are in place and documented.
If new data types were added (e.g., adding location or other sensors), consent and privacy policy have been updated accordingly (and likely an update to this doc).
 Directory Structure Adherence: All new files and code are placed in the appropriate directory as per §7:
No chaotic placement (e.g., a developer didn't put a analysis script in the app folder or vice versa).
Filenames and paths follow the conventions (e.g., tests in tests/, configs in opensmile_config/, etc.).
The README or relevant docs are updated if the structure changed.
Running the project (app, functions, scripts) works with the given structure (e.g., import paths correct).
The structure explanation in §7 remains accurate after changes (update it if, say, we added a new top-level directory).
 AI Prompts & Usage: If AI was used to generate any code or documentation, prompts referencing the standards were used (as in §8), and the output was verified for compliance.
No AI-generated code was accepted until it was checked against this checklist and corrected if needed.
Comments in AI-generated code also cite sections appropriately.
(This item is more for process than product, but it's a reminder that AI assistance should be guided by this doc.)
Every pull request or code review should go through this checklist. Automated tools might also enforce some items (for example, a linter could check for presence of section citations in new code, or a test could ensure pipeline version is set). AI Guidance: Even an AI system can use this checklist to self-audit generated code. For instance, after producing code, an AI can be prompted: "Check the code against the compliance checklist in §9 of DATA_STANDARDS.md and list any issues." This can catch omissions (like missing a comment reference or not handling a validation case).
10. Common Pitfalls and FAQs
Even with detailed standards, there are common pitfalls developers or AI assistants might encounter. Below we list frequent issues and questions, with guidance to avoid and address them:
10.1 Common Pitfalls
Pitfall: Forgetting to update pipeline version after making changes.
Consequence: Results may quietly change without clear documentation, making it hard to reproduce or compare experiments.
Solution: Always increment the version number in the code and update the changelog (see §5) when you modify the feature set, algorithms, or output format. For example, if you optimize the pitch algorithm or add a new feature, bump the version (v1.2 -> v1.3, etc.) and note it. This ensures everyone knows which version of the pipeline they are using and what's changed.
Pitfall: Not citing the standards document in code comments.
Consequence: Other developers (or automated reviewers) can't easily verify that the code follows the agreed standards. They might unintentionally introduce non-compliant changes in the future due to lack of context.
Solution: Always include references to this document in relevant code comments and docstrings. (As mandated in §5.1.) For instance, if you write a function to compute shimmer, start the docstring with "Implements shimmer as per DATA_STANDARDS.md §3.2.3". This practice was new to some developers, so occasionally people forget—make it a habit. We even have a linter rule to flag missing citations in new code.
Pitfall: Using a Bluetooth or low-quality mic during testing and overlooking its effects.
Consequence: If a developer tests the pipeline with, say, AirPods and finds jitter is weirdly high or audio low-pass filtered, they might think the algorithm is broken when it's actually the input quality. Similarly, forgetting that our instructions discourage Bluetooth could lead to inconsistent data if not enforced.
Solution: Follow §2.1 strictly: use the recommended devices for any official testing. The app should warn users (and we as developers should heed that too). If you must use a different mic for a quick test, expect differences and don't calibrate thresholds based on that. Always default to built-in mic audio for any pipeline tuning. And ensure the app's Bluetooth detection is working (common pitfall: not all Bluetooth devices are caught—update the check if needed).
Pitfall: Neglecting environment noise when recording test data.
Consequence: The pipeline might flag many files or produce outlier features, and a developer might misinterpret that as a bug in code rather than intended behavior.
Solution: When collecting sample data (even for internal tests), do it in a quiet setting or purposely test noisy input and expect it to be flagged. If a test file keeps failing SNR check, consider if the room was noisy rather than immediately suspecting the code. Use the app's prompts (they're there to help you as well as users). Many "bug reports" have been resolved by realizing the test was done in a noisy cafe!
Pitfall: Not running the full test suite after changes.
Consequence: You might think your change is fine (the app still runs, features come out), but you could unknowingly break a quality check or assumption, which would be caught by tests or CI. For example, adjusting a threshold without updating the test expected value.
Solution: Run pytest (or our test command) locally for tests/ before pushing changes. Pay attention to tests in tests/feature_pipeline.py especially—they are there to catch subtle mismatches with standards. If a test fails, do not ignore it; it usually points to a non-compliance (e.g., "expected jitter 0.00, got 0.5" indicates a possible calculation issue or test fixture needs update after pipeline change). Update tests only when you have confirmed the new behavior is correct and updated the standard/changelog accordingly.
Pitfall: Misinterpreting feature output (mixing up summary vs frame-level data).
Example: A developer saw a column "F0" in output and assumed it's a single value (mean F0), but in frame-level output it was actually multiple rows of F0 over time. This led to confusion in analysis code that averaged an already averaged value.
Solution: Pay attention to whether a feature file is frame-level or summary. In our pipeline, by default eGeMAPS outputs summary (functionals) for the whole file, except where we explicitly output tracks (like pitch track for research viz). We keep those separate or clearly indicated (file names or headers). If adding new outputs, label them clearly (e.g., "time_sec" column signals frame data). When in doubt, check §3.3 or the feature_definitions.md for what each column means. And please document any new column thoroughly to avoid future confusion.
Pitfall: Changing a feature's calculation without updating documentation/reference.
Consequence: The document and code diverge. For instance, if you switch to a new pitch tracker but don't update §3.2.1, someone might still think we use Praat autocorrelation and cite wrong info in a paper.
Solution: Synchronously update this DATA_STANDARDS.md whenever you make such changes. It's better to delay a code change until you have time to document it properly, than to have an undocumented change. The changelog should note it, and ideally mention if it's expected to have negligible effect or not. The whole team (and our AI assistants) rely on this doc being accurate.
Pitfall: Overlooking edge cases (e.g., extremely short recordings, silence, non-speech sounds).
Consequence: The pipeline might throw errors or produce meaningless features (like NaNs or zeros) if given silence or <1 sec audio. If not handled, this could crash an analysis or distort aggregate stats.
Solution: The standards set minimum durations and we enforce them (§3.4). Ensure code gracefully handles edge cases: if no voiced segment is found, features should be marked as NA or flagged, not just zeroed without note. Many edge cases are caught by our validation, but if you introduce new analysis (e.g., a new feature or some summary metric), consider what happens if input doesn't meet assumptions. For example, if computing "max phonation time" and the user stopped speaking early, that's actually just the recording length, but if that's <3s, we know it's invalid per criteria. So treat accordingly. Test on a silent audio and a very short audio to see that the pipeline doesn't crash and handles output properly.
Pitfall: Not aligning changes between app and backend.
Example: The app decides to add a new task (say a humming task for future research) but the backend doesn't know about "humming" task so it doesn't process or store it correctly. Or vice versa, backend expects a "reading" task but app calls it "read" in file naming.
Solution: Maintain consistent enums/names for tasks across app, cloud, and documentation (§2.2 lists tasks and we use those names). If new tasks or changes are made, update all places: the app UI text, the code that triggers analysis (maybe add a branch for the new task if needed), the output interpretation, and this doc (add a subsection in §2.2, and any feature considerations for it in §3.2, etc.). Cross-functional changes require coordination—don't do them in isolation.
Pitfall: Ignoring the Privacy Impact of Debugging/Logging.
Example: A developer leaves verbose logs on the server that include snippets of audio data or userIDs in plain text, or exports a subset of user recordings to test something and forgets to delete them.
Solution: Always consider privacy (see §6) when debugging. It's okay to log that "User U1234 failed SNR check" – U1234 is our anonymized ID, that's fine. But don't log actual user-entered text or audio content. If you absolutely need to debug audio content (say you suspect the audio is silence), use tools in a secure environment and remove the data after. Our policy is to not expose any more data than necessary in logs (which might be stored long-term). Before pushing code, double-check that debug print statements or logs don't violate this. It's easy to leave something in by accident – our code reviews include checking for stray print/log of sensitive data.
10.2 Frequently Asked Questions (FAQs)
Q: Why do we require 48 kHz sampling? Wouldn't 44.1 kHz (CD quality) suffice, especially since many phone mics may not have much response above ~20 kHz?
A: We choose 48 kHz for a couple of reasons. First, many professional and research audio tools default to 48 kHz, and it slightly extends the high-frequency range captured (up to 24 kHz) which can include subtle overtones or noise components. Some vocal features (like certain noise measures or formants) might benefit from the higher bandwidth. Also, having a uniform sample rate avoids resampling artifacts – since some devices record at 48 kHz natively, we up-sample others to match. The difference between 44.1 and 48 is minor, but standardization is key. Our pipeline will accept 44.1 if that's what the device gives (we won't throw away data), but it immediately resamples it to 48 kHz to maintain consistency in analysis. So essentially, 44.1 kHz would suffice in theory, but 48 kHz ensures we capture everything and simplifies processing (especially since many of our reference algorithms and filter settings assume 8 kHz low-pass etc., which align well with 48 kHz sampling). Q: The user's voice data is sensitive. How do we ensure an AI or developer doesn't accidentally access raw audio they shouldn't, especially if using AI assistance for coding?
A: We enforce strict access controls (see §6). Only specific team members or processes can access raw audio. When using AI tools, we never input raw audio data into them. We might share aggregated features or pseudonymized info if needed for debugging with AI (and even that carefully). The userID is anonymized, and no location or name is tied to it in analysis data. If an AI asks for more data (say code assistant wants example input), we provide either a dummy or a heavily anonymized snippet. All contributors are trained on privacy, and we have monitoring to detect any large exfiltration of audio. Also, by design, once features are extracted, we remove raw audio from the analysis environment, so there's less risk of accidental exposure. In short, human or AI, no one should have raw audio unless absolutely necessary for the task, and even then, with oversight. Q: Can we add a new acoustic feature that's not in the original list (for example, vocal tremor frequency or formant bandwidths)?
A: Yes, we can extend the feature set if a justified need arises (like a new research finding suggests a particular feature is valuable). However, any addition must go through the standards update process: propose the feature, update §3.2 with its definition and method, possibly update openSMILE config or code to extract it, and increment the pipeline version. Also, add unit tests for it, and ensure it doesn't break output format or overload the system (some features might drastically increase output size or processing time). We keep an eye on not over-complicating the feature set without reason – currently 80-100 features is quite comprehensive. If the feature is highly correlated with existing ones, we might choose not to add to avoid redundancy. But if it's novel info, we'll integrate it carefully. Always document it and inform the team (via changelog and maybe a team meeting) so everyone knows the new feature exists and how to interpret it. Q: What if a user has a very different voice (e.g., much lower pitch than expected, or they're not female as assumed)? Will our system handle it?
A: Our pitch range (75–500 Hz) is chosen to cover typical female voices and even many male voices (male conversational F0 can be ~60–180 Hz, though 60 is a bit below our range). If a user is outside the expected range – say a male with a very low voice – Praat might drop octave or mis-detect some pitches below 75 Hz. We would flag an F0_mean of, say, 65 Hz as out-of-range per §3.4 and possibly adjust if we get multiple such users. Similarly, our instructions and research focus on women's health, so we expect mostly female voices; however, if we include other demographics, we should widen ranges or make them configurable. Right now, if a male user were in the system, they might get more "out of range" flags and possibly slightly less accurate pitch tracking on the low end. The system won't crash – it'll just note it. We have left a note in §3.1 that 75–500 Hz is suitable for female voices. If we broaden our scope, we might raise that upper bound or remove the strict lower bound. Also, formant tracking and other features should still work (they might just measure different values, which is fine). In summary, the system can technically handle other voices, but interpretations of results are tuned for female physiology. If we expand use cases, we will update parameters accordingly. Q: The jitter/shimmer values seem higher on phone recordings than in some older studio datasets. Is that expected or an error?
A: Some increase might be expected. Smartphone recordings (even at high quality) can introduce slight artifacts or have a different noise floor than lab microphones, possibly affecting perturbation measures. However, studies (like Kim 2016, Manfredi 2017) found that iPhone recordings in a quiet room are comparable to studio recordings for jitter/shimmer/HNR. We have taken steps like using 24-bit and ensuring no compression to mitigate differences. If jitter values are higher, it could be due to subtle background noise or the user's technique (even handling noise can add tiny perturbations). Our validation (e.g., comparing to a reference device) hasn't shown a systematic bias, so significant differences might indicate an issue. Ensure the device microphone isn't faulty and that the user followed instructions (some might unintentionally add vibrato or have varying volume). Also, remember that jitter is best measured on sustained vowels; if you look at jitter from spontaneous speech directly it's not as meaningful (our pipeline, via Praat, likely computes it on voiced segments only, but results are more variable). So context is key. In short: small differences = possibly expected; large differences = investigate the cause (maybe a bug or environmental factor). That's why we included cross-device tests (§4) and references to known studies. Q: How do we handle updates to external tools? For example, if a new Praat version changes the default algorithm or if openSMILE releases a new feature set?
A: Cautiously. According to §5, we pin versions to avoid surprises. If Praat updates from v6.3 to v6.4, we will first test that the results don't change for our data. Often, minor Praat updates fix UI or edge cases, not the core algorithm, but we can't assume. We either stick to 6.3 or, if we move to 6.4, run our validation tests to see if any differences arise (e.g., maybe they improved pitch tracking in noisy conditions). If differences are negligible, we can update the requirement and note it in the changelog (pipeline version may not need bump if outputs same). If differences are significant, that's essentially a pipeline change – we might treat it like any algorithm change: bump version, document, possibly re-extract features for existing data if needed. Similarly for openSMILE: if a new version or a new standard feature set comes (say eGeMAPS v03), we would evaluate if it provides benefits. Perhaps we'd consider adding that as an option or for future pipeline v2.0. But we wouldn't suddenly switch without planning and updating the documentation and version. The changelog and version tags will capture any such upgrade. All in all, we freeze our tool versions for each pipeline version and only upgrade deliberately. Q: If a contributor has a question or is unsure about something in the standards, what should they do?
A: We encourage opening a discussion (e.g., on our project's issue tracker or Slack channel) referencing this document section. For instance, "I see in §3.2.5 we include formants though we don't expect changes – do we actually use them in analysis, or could we drop them to save compute?" Such questions are welcome – the document is living and can be clarified. If there's ambiguity or if a decision isn't documented, let's fix that. Also, sometimes real-world data might reveal a need to tweak a standard (say we find the 40 dB noise threshold is too strict or not strict enough). In that case, propose a change, and we'll update the doc and pipeline accordingly if agreed. Finally, the changelog (§12) at the end always lists modifications; reading that can help if you suspect something changed recently that isn't fully reflected elsewhere. These FAQs and pitfalls will grow as we encounter new ones. Always check here if something is puzzling – the answer might save you time. And feel free to add entries when you resolve a non-obvious issue, so others can learn from it.
11. References
(Below is the list of key references that informed our standards and methods. These provide background and validation for our choices.)
openSMILE Documentation. AudEERING (2020). openSMILE official docs – Description of standard feature sets (eGeMAPS, ComParE) and configuration options. Online
Use in this project: We based our feature extraction on the eGeMAPS set recommended in these docs.
Praat Manual. Boersma, P. & Weenink, D. (2023). Praat: Doing Phonetics by Computer – Official manual detailing algorithms for pitch, jitter, shimmer, HNR, etc.. Online
Use in this project: Informs our usage of Praat's acoustic analysis methods and parameter settings.
Kim et al., 2016. J. Clinical Otolaryngology Head & Neck Surgery, 27(2): Recording Quality of Smartphone for Acoustic Analysis – Found iPhone recordings in quiet room (<40 dB noise) are comparable to studio recordings.
Implication: Validates using smartphone audio for jitter, shimmer, etc., if recorded in a controlled environment (justifying our 40 dB noise criterion).
Manfredi et al., 2017. Biomed. Signal Process. Control, 34: Smartphones vs Professional Mic – Showed strong correlation between smartphone-recorded voice features and studio mic (for jitter, shimmer, HNR).
Implication: Supports that our pipeline can rely on phone audio without significant loss of clinical information, provided technical settings are correct.
Uloza et al., 2015. European Archives of Oto-Rhino-Laryngology, 272(11): – Demonstrated that smartphones can reliably capture acoustic voice parameters for pathology screening. Recommended sustained vowels for consistency.
Implication: We included a sustained vowel task largely because of such recommendations, ensuring stable measurements.
Chae et al., 2001. Journal of Voice, 15(2): Premenstrual Voice Change – Identified a significant increase in jitter in women with PMS pre-menstrually.
Implication: Provides scientific rationale for tracking jitter across the cycle (we expect to see perturbation changes in late luteal phase for PMS/PMDD individuals).
Fischer et al., 2011. PLoS ONE, 6(9): Daily Voice and Hormones – Found higher pitch and variability before ovulation, and increased noise (lower HNR) during menstruation.
Implication: Underpins our focus on F0 and HNR changes as potential ovulation and menstrual phase markers.
Lobmaier et al., 2024. Frontiers in Psychology, 15: Study on Menstrual Cycle & Voice – Confirmed subtle cycle effects in pitch and formants in social contexts. Notably, shimmer was lower and pitch higher during high-fertility phases in some studies. Also discussed inconsistencies and need for multi-parameter analysis.
Implication: We monitor multiple features (pitch, shimmer, formants) together, as no single measure universally changes for all women. Also justifies including formants even if changes are subtle.
Gugatschka et al., 2013. Journal of Voice, 27(5): Voice in PCOS – Found no significant difference in objective voice parameters between PCOS patients and controls (only a non-significant trend of lower mean F0 in PCOS).
Implication: We may not expect large differences in baseline voice for PCOS, but still include PCOS as a group to see if any subtle trends or fatigue effects emerge. Confirms that dramatic voice changes in PCOS are not evidenced, aligning expectations.
Turetta et al., 2024. Gynecologic and Obstetric Investigation, 89(2): Systematic review & meta-analysis on PCOS and voice – Concluded evidence of vocal changes in PCOS is limited and inconsistent, aligning with Gugatschka's findings.
Implication: Reinforces that our primary focus should be cycle-related changes rather than PCOS vs control differences, though we still track PCOS participants for completeness.
Stogowska et al., 2022. Endocrine Connections, 11(12): Voice changes in endocrine disorders (review) – Summarized how hormonal fluctuations (menstrual cycle, pregnancy, menopause) and disorders can affect voice. Notes "premenstrual dysphonia" phenomenon and that exogenous androgens (as in some endometriosis treatments) can masculinize voice.
Implication: Informs us to consider and ask users about any hormonal treatments (since that could affect voice) and underscores that changes can be subtle but real.
Jannetts et al., 2019. Journal of Voice, 33(3): Cross-Device Voice Analysis Reliability – Reported that common smartphones (iPhone/Android) provide reliable voice recordings for acoustic analysis when recorded in controlled conditions. Supports pooling data from different phone models with calibration.
Implication: Justifies our inter-device tests (§4) and gives confidence that we can combine data from various iPhone models as long as we enforce our environment and possibly check for any slight biases.
Barnes & Latman, 2011. Journal of Voice, 25(5): No Significant Cycle-Related Changes – In a small sample, found no significant vocal changes across the menstrual cycle. Highlights the importance of robust data and possibly personalized analysis (some individuals might not follow population trends).
Implication: We should be prepared that not every user will show the textbook changes. This is why we collect a variety of features and large sample size – to detect subtle effects at the group level and understand individual variance. Also, our app will ultimately aim to give individualized feedback, which is sensible given such findings.
(Above references include DOI or URLs where available. The source links refer to lines from connected peer-reviewed articles or documentation that informed our standards. They provide evidence and justification for the choices made in this document.)
12. Changelog
All major updates to these standards and the associated analysis pipeline are recorded in the project's RESEARCH_CHANGELOG.md. Below is a summary of key changes:
2025-01-10: Initial version (v1.0) of DATA_STANDARDS.md released. Established baseline: voice tasks (5s vowel, 30s reading, 1min spontaneous), audio specs (48kHz 24-bit WAV, quiet room), feature set (pitch, jitter, shimmer, HNR, MFCCs, intensity, etc. per eGeMAPS), validation procedures (clipping, noise floor, duration checks, unit tests with Praat references).
2025-03-15: Updated to v1.1 – Added formant features (F1–F4) and voice break metrics after literature review suggested their relevance (Lobmaier 2024, Stogowska 2022). Updated openSMILE to v3.0.1. Improved noise level check (40 dB ambient threshold) based on Kim 2016 study (was 50 dB, made stricter to 40 dB). All changes logged and minor effect on existing data (a slight increase in features dimensionality; v1.0 and v1.1 data are comparable except new columns and slightly more flagged noisy files).
2025-06-01: v1.2 – Refined jitter algorithm to use Praat's newest perturbation settings (no effect on typical values, just more robust for low amplitude voices). Incorporated maximum phonation time and articulation rate as task-specific metrics in output (§3.2.12) after observing some users not sustaining full 5s. Directory structure updated to include tests/feature_validation/ reference outputs. No existing feature definitions changed (no re-extraction needed for older data; version bump for transparency).
(Ongoing entries for future changes will be added here, each with date, new version, and summary of modifications and their rationale.)
All contributors must read and follow this document. For any questions or clarifications, please open an issue in the repository or contact the project maintainer. Compliance with these standards is mandatory to ensure we deliver a trustworthy, research-grade application and dataset. By adhering to this guide, we ensure that every piece of code and data contributes meaningfully and reliably to our collective goal: understanding the voice as a biomarker for women's health.
Citations
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf

file://file-1Sz5LwgWnCKRrdarCmYx13
DATA_STANDARDS.md.pdf