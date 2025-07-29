Certainly! Here is a **comprehensive, AI-optimized Engineering Design Document** for the enhanced onboarding and hormonal correlation pipeline, incorporating all your requirements, forward-compatibility, and explicit data/validation logic. This version is structured for clarity, modularity, and future extensibilityideal for training an AI or onboarding new engineers.

---

# Engineering Design Document: Sage Onboarding & Hormonal Correlation Data Pipeline

## 1. Purpose

This document defines the architecture, data models, validation rules, and extensibility points for Sages onboarding flow and its integration with a future hormonal phase inference engine. It is designed for maintainability, testability, and AI-readability.

---

## 2. Scope

- **Phase 1:** Expand onboarding to collect rich, structured personal and health data.
- **Phase 2:** Prepare for future menstrual cycle logging and hormonal insights.
- **Out of Scope:** Daily symptom tracking and cycle logs (placeholders only).

---

## 3. Data Model

### 3.1. EnhancedUserProfileData

```swift
struct EnhancedUserProfileData: Equatable {
    var name: String = ""
    var age: Int = 0
    var birthYear: Int? = nil
    var genderIdentity: GenderIdentity? = nil
    var sexAssignedAtBirth: SexAssignedAtBirth? = nil
    var voiceConditions: Set<VoiceCondition> = []
    var diagnosedConditions: Set<DiagnosedCondition> = []
    var cycleStartDates: [Date]? = nil // Placeholder for future menstrual cycle logs
}
```

#### 3.1.1. Enum Definitions

```swift
enum GenderIdentity: String, CaseIterable, Codable {
    case woman, man, nonBinary, transWoman, transMan, agender, preferNotToSay, other
}
enum SexAssignedAtBirth: String, CaseIterable, Codable {
    case female, male, intersex, preferNotToSay
}
enum VoiceCondition: String, CaseIterable, Codable {
    case none, voiceLoss, pitchInstability, stuttering, spasmodicDysphonia, vocalNodules, other
}
enum DiagnosedCondition: String, CaseIterable, Codable {
    case none, pmdd, pcos, adhd, autism, endometriosis, hypothyroidism, hyperthyroidism, menopause, perimenopause, hrt, other, preferNotToShare
}
```

#### 3.1.2. Forward Compatibility

- `cycleStartDates` is included as a **placeholder** for future menstrual cycle logging. It is not used in the MVP UI but ensures the data model is ready for cycle-aware features.

---

## 4. Validation Logic

### 4.1. Personal Info Validation

```swift
func validatePersonalInfo(_ data: EnhancedUserProfileData) -> [ValidationError] {
    var errors: [ValidationError] = []
    let currentYear = Calendar.current.component(.year, from: Date())

    // If both age and birthYear are present, check for consistency
    if let birthYear = data.birthYear, data.age > 0 {
        let calculatedAge = currentYear - birthYear
        if abs(calculatedAge - data.age) > 1 {
            errors.append(.ageBirthYearMismatch())
        }
    } else if data.age > 0 {
        if data.age < 13 || data.age > 99 {
            errors.append(.ageInvalid())
        }
    } else if let birthYear = data.birthYear {
        if birthYear < 1920 || birthYear > currentYear {
            errors.append(.birthYearInvalid())
        }
    } else {
        errors.append(.ageRequired())
    }
    // ...other validations...
    return errors
}
```
- **Rule:** If both `age` and `birthYear` are present, validate consistency. If only one is present, validate that one. If neither, error.
- **Mutually exclusive errors** are handled by prioritizing consistency checks, then individual field validation.

---

## 5. Onboarding Flow & State Management

### 5.1. Onboarding Steps

```swift
enum OnboardingStep: String, Equatable {
    case signupMethod, explainer, personalInfo, healthInfo, sustainedVowelTest, readingPrompt, finalStep, completed
}
```

### 5.2. ViewModel State

```swift
enum ProfileSyncStatus {
    case idle, saving, success, error(String)
}

@MainActor
final class OnboardingJourneyViewModel: ObservableObject {
    @Published var enhancedUserProfile: EnhancedUserProfileData = EnhancedUserProfileData()
    @Published var personalInfoValidationErrors: [String: String] = [:]
    @Published var healthInfoValidationErrors: [String: String] = [:]
    @Published var profileSyncStatus: ProfileSyncStatus = .idle
    // ...other onboarding state...
}
```
- `profileSyncStatus` enables robust UI feedback and error handling during network operations.

---

## 6. Interoperability with Hormonal Phase Engine

### 6.1. Data Flow

- **birthYear/age:** Used to adjust hormonal phase predictions for age-related changes (e.g., perimenopause, menopause).
- **sexAssignedAtBirth:** Ensures correct application of hormonal models (e.g., excludes non-female-at-birth users from certain inferences).
- **diagnosedConditions:** Flags users with conditions (e.g., PCOS, PMDD, menopause) that may alter cycle regularity or hormone profiles, allowing the inference engine to adjust or annotate insights accordingly.
- **cycleStartDates:** (Future) Direct input for cycle phase calculation, trend analysis, and personalized insight delivery.

### 6.2. Example Usage

```swift
func inferHormonalPhase(profile: EnhancedUserProfileData, today: Date) -> HormonalPhase? {
    guard let sex = profile.sexAssignedAtBirth, sex == .female else { return nil }
    // Use cycleStartDates if available, else fallback to age/birthYear and diagnosedConditions
    // Adjust inference for menopause, PCOS, etc.
    // ...
}
```

---

## 7. Privacy & Compliance

- All health and demographic data is encrypted at rest and in transit.
- User consent is required for each data category.
- Users can update or delete their data at any time.
- No PII (e.g., name, email) is stored with research data.

---

## 8. Testing & TDD/BDD

- All validation logic is covered by unit tests, including edge cases (e.g., age/birthYear mismatch).
- Onboarding flow is tested for all user-visible behaviors and error states.
- Profile sync status is tested for all network conditions (idle, saving, error).

---

## 9. Extensibility

- Adding new fields (e.g., cycle logs, symptoms) requires only updating the data model and validation logic.
- The `cycleStartDates` placeholder ensures future cycle-aware features can be added with minimal migration.
- The onboarding flow is modular, with each step and validation isolated for easy modification.

---

## 10. Summary

- **Rich, structured onboarding data** enables future hormonal insights.
- **Validation logic** is explicit, robust, and edge-case aware.
- **Profile sync status** improves UI resilience.
- **Forward compatibility** is ensured by including placeholders and documenting data flow to the hormonal inference engine.

---

## 11. Example of Good TDD, BDD, DDD
Always follow test driven design, behavior driven design, and domain driven design. 
func testOnboardingWithValidAndInvalidData() {
    // Given: User is on personal info step
    let viewModel = OnboardingJourneyViewModel()
    viewModel.currentStep = .personalInfo

    // When: User enters invalid age and taps continue
    viewModel.enhancedUserProfile.age = 8
    viewModel.completePersonalInfo()
    // Then: Should not advance, should show error
    XCTAssertEqual(viewModel.currentStep, .personalInfo)
    XCTAssertTrue(viewModel.personalInfoValidationErrors.values.contains(where: { $0.contains("age") }))

    // When: User corrects age and taps continue
    viewModel.enhancedUserProfile.age = 25
    viewModel.completePersonalInfo()
    // Then: Should advance to health info
    XCTAssertEqual(viewModel.currentStep, .healthInfo)
}