# Code Quality Patterns & Best Practices

## 📋 Table of Contents
- [Overview](#-overview)
- [Method Length & Complexity Guidelines](#-method-length--complexity-guidelines)
- [Helper Method Extraction Patterns](#-helper-method-extraction-patterns)
- [UI Content Centralization](#-ui-content-centralization)
- [Test Data Factory Patterns](#-test-data-factory-patterns)
- [State Management Patterns](#-state-management-patterns)
- [Analytics Patterns](#-analytics-patterns)
- [Concurrency & Threading](#-concurrency--threading)
- [Tooling & Automation](#-tooling--automation)
- [MVP vs Post-MVP Considerations](#-mvp-vs-post-mvp-considerations)
- [Code Review Checklist](#-code-review-checklist)
- [Implementation Strategy](#-implementation-strategy)

## 🎯 Overview

This document outlines the code quality patterns and best practices we've identified through our debugging sessions and codebase analysis. These patterns should be applied to all future development work to improve maintainability, readability, and reduce debugging time.

**Scope**: Applies to all production Swift code in ViewModels, Coordinators, Services, and Unit Tests.

## 📏 Method Length & Complexity Guidelines

### Rule: Keep Methods Under 20 Lines

**Why**: Long methods are harder to test, debug, and maintain. They often handle multiple responsibilities.

**Examples from our codebase**:

```swift
// ❌ BAD: OnboardingJourneyViewModel has 500+ lines with long methods
func startVocalTest() {
    // 30+ lines handling permission checking, recording setup, error handling
    switch microphonePermissionStatus {
    case .granted:
        beginRecording()
    case .denied:
        Logger.error("[OnboardingJourneyViewModel] Microphone permission denied")
        errorMessage = "Microphone access is required. Enable it in Settings to continue."
    case .unknown:
        microphonePermissionManager.checkPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.microphonePermissionStatus = .granted
                self.beginRecording()
            } else {
                self.microphonePermissionStatus = .denied
                Logger.error("[OnboardingJourneyViewModel] Microphone permission denied during request")
                self.errorMessage = "Microphone access is required. Enable it in Settings to continue."
            }
        }
    }
}

// ✅ GOOD: Break down into focused methods
func startVocalTest() {
    switch microphonePermissionStatus {
    case .granted:
        beginRecording()
    case .denied:
        handlePermissionDenied()
    case .unknown:
        requestPermissionAndRecord()
    }
}

private func handlePermissionDenied() {
    Logger.error("[OnboardingJourneyViewModel] Microphone permission denied")
    errorMessage = "Microphone access is required. Enable it in Settings to continue."
}

private func requestPermissionAndRecord() {
    microphonePermissionManager.checkPermission { [weak self] granted in
        guard let self = self else { return }
        if granted {
            self.microphonePermissionStatus = .granted
            self.beginRecording()
        } else {
            self.microphonePermissionStatus = .denied
            self.handlePermissionDenied()
        }
    }
}
```

### Rule: Single Responsibility Principle

**Why**: Methods should do one thing well. Multiple responsibilities make testing and debugging harder.

```swift
// ❌ BAD: Multiple responsibilities in one method
func processUserSignup() {
    // Validation
    guard isEmailValid, isPasswordValid else {
        errorMessage = "Invalid input"
        return
    }
    
    // Profile creation
    let profile = UserProfile(...)
    
    // Analytics
    analyticsService.track("signup", properties: [...])
    
    // Navigation
    currentStep = .next
}

// ✅ GOOD: Separate methods for each responsibility
func processUserSignup() {
    guard validateSignupData() else { return }
    createUserProfile()
    trackSignupAnalytics()
    navigateToNextStep()
}

private func validateSignupData() -> Bool { /* 5 lines */ }
private func createUserProfile() { /* 10 lines */ }
private func trackSignupAnalytics() { /* 8 lines */ }
private func navigateToNextStep() { /* 3 lines */ }
```

## 🔧 Helper Method Extraction Patterns

### Avoiding Repetition in Analytics

**Problem**: Analytics tracking methods repeat the same pattern.

```swift
// ❌ BAD: Repeated pattern
private func trackSignupMethodSelected(method: String) {
    guard let userId = userProfile?.id else {
        Logger.error("[ViewModel] Missing user ID during signup method analytics")
        return
    }
    analyticsService.track("onboarding_signup_method_selected", properties: ["method": method, "userID": userId], origin: "ViewModel")
}

private func trackOnboardingStarted() {
    guard let userId = userProfile?.id else {
        Logger.error("[ViewModel] Missing user ID during onboarding started analytics")
        return
    }
    analyticsService.track("onboarding_started", properties: ["userID": userId, "signup_method": selectedSignupMethod?.rawValue ?? "unknown"], origin: "ViewModel")
}

// ✅ GOOD: Extracted helper method
private func trackAnalyticsEvent(_ eventName: String, properties: [String: Any]) {
    guard let userId = userProfile?.id else {
        Logger.error("[ViewModel] Missing user ID during \(eventName) analytics")
        return
    }
    var eventProperties = properties
    eventProperties["userID"] = userId
    analyticsService.track(eventName, properties: eventProperties, origin: "ViewModel")
}

// Usage:
private func trackSignupMethodSelected(method: String) {
    trackAnalyticsEvent("onboarding_signup_method_selected", properties: ["method": method])
}

private func trackOnboardingStarted() {
    trackAnalyticsEvent("onboarding_started", properties: [
        "signup_method": selectedSignupMethod?.rawValue ?? "unknown"
    ])
}
```

### Centralizing Validation Logic

**Problem**: Validation logic is scattered across multiple methods.

```swift
// ❌ BAD: Validation scattered
func selectAnonymous() {
    guard userProfile == nil else {
        errorMessage = "Profile already exists"
        return
    }
    // ... rest of method
}

func selectEmail() {
    guard userProfile == nil else {
        errorMessage = "Profile already exists"
        return
    }
    // ... rest of method
}

// ✅ GOOD: Centralized validation
private func validateNoExistingProfile() -> Bool {
    guard userProfile == nil else {
        errorMessage = "Profile already exists"
        return false
    }
    return true
}

func selectAnonymous() {
    guard validateNoExistingProfile() else { return }
    // ... rest of method
}

func selectEmail() {
    guard validateNoExistingProfile() else { return }
    // ... rest of method
}
```

### Standardizing Error Handling

**Problem**: Error handling is inconsistent across the codebase.

```swift
// ❌ BAD: Inconsistent error handling
func method1() {
    do {
        try someOperation()
    } catch {
        errorMessage = "Operation failed"
        Logger.error("Error: \(error)")
    }
}

func method2() {
    do {
        try anotherOperation()
    } catch {
        fatalError("Critical error: \(error)")
    }
}

// ✅ GOOD: Centralized error handling
enum ViewModelError: Error {
    case operationFailed(Error)
    case criticalError(Error)
    
    var userMessage: String {
        switch self {
        case .operationFailed:
            return "Operation failed. Please try again."
        case .criticalError:
            return "A critical error occurred. Please restart the app."
        }
    }
}

private func handleError(_ error: Error, isCritical: Bool = false) {
    let viewModelError: ViewModelError = isCritical ? .criticalError(error) : .operationFailed(error)
    errorMessage = viewModelError.userMessage
    Logger.error("[ViewModel] \(viewModelError): \(error.localizedDescription)")
}

func method1() {
    do {
        try someOperation()
    } catch {
        handleError(error)
    }
}

func method2() {
    do {
        try anotherOperation()
    } catch {
        handleError(error, isCritical: true)
    }
}
```

## 📝 UI Content Centralization

### Pattern: Centralize UI Strings

**Problem**: UI strings are hardcoded throughout the codebase.

```swift
// ❌ BAD: Hardcoded strings
var explainerHeadline: String {
    return "Let's run some quick tests"
}

var explainerSubtext: String {
    return "This helps us understand the unique physiology of your vocal tract."
}

var vocalTestInstruction: String {
    return "This test measures the rate and stability of vocal cord vibrations."
}

// ✅ GOOD: Centralized strings
struct OnboardingStrings {
    static let explainerHeadline = "Let's run some quick tests"
    static let explainerSubtext = "This helps us understand the unique physiology of your vocal tract."
    static let vocalTestInstruction = "This test measures the rate and stability of vocal cord vibrations."
    static let beginButtonTitle = "Begin"
    static let nextButtonTitle = "Next"
    static let finishButtonTitle = "Finish"
}

// Usage in ViewModel:
var explainerHeadline: String {
    return OnboardingStrings.explainerHeadline
}

var explainerSubtext: String {
    return OnboardingStrings.explainerSubtext
}
```

## 🧪 Test Data Factory Patterns

### Validating Test Setup Inputs

**Problem**: Factory methods crash with invalid inputs.

```swift
// ❌ BAD: No input validation
static func createCompleteUserProfile(
    age: Int = 25,
    gender: String = "female"
) -> UserProfile {
    return UserProfileValidator.createCompleteProfile(
        from: UserProfileData(age: age, gender: gender),
        userId: UUID().uuidString,
        deviceModel: UIDevice.current.model,
        osVersion: UIDevice.current.systemVersion,
        dateProvider: SystemDateProvider()
    )
}

// ✅ GOOD: Input validation
static func createCompleteUserProfile(
    age: Int = 25,
    gender: String = "female"
) -> UserProfile {
    // Validate inputs to prevent test crashes
    guard age > 0 else {
        fatalError("Test setup error: age must be > 0 for complete profile")
    }
    guard !gender.isEmpty else {
        fatalError("Test setup error: gender cannot be empty for complete profile")
    }
    
    return UserProfileValidator.createCompleteProfile(
        from: UserProfileData(age: age, gender: gender),
        userId: UUID().uuidString,
        deviceModel: UIDevice.current.model,
        osVersion: UIDevice.current.systemVersion,
        dateProvider: SystemDateProvider()
    )
}
```

## 🔄 State Management Patterns

### Pattern: Direct State Setting

**Problem**: Tests set mock properties instead of ViewModel state.

```swift
// ❌ BAD: Setting mock properties
harness.mockMicrophonePermissionManager.permissionGranted = true
viewModel.startVocalTest() // Expects ViewModel to read from mock

// ✅ GOOD: Setting ViewModel state directly
viewModel.microphonePermissionStatus = .granted
viewModel.startVocalTest() // ViewModel uses its own state
```

### Pattern: State Validation

**Problem**: Tests don't validate that state is properly set up.

```swift
// ❌ BAD: No state validation
func testVocalTestRecording() {
    viewModel.startVocalTest()
    XCTAssertTrue(viewModel.isRecording)
}

// ✅ GOOD: Validate state setup
func testVocalTestRecording() {
    // Given: Microphone permission is granted
    viewModel.microphonePermissionStatus = .granted
    XCTAssertEqual(viewModel.microphonePermissionStatus, .granted)
    
    // When: User starts vocal test
    viewModel.startVocalTest()
    
    // Then: Recording should be active
    XCTAssertTrue(viewModel.isRecording)
}
```

## 📊 Analytics Patterns

### Pattern: Consistent Analytics Tracking

**Problem**: Analytics tracking is inconsistent and error-prone.

```swift
// ❌ BAD: Inconsistent analytics
private func trackSignupMethodSelected(method: String) {
    analyticsService.track("signup_method", properties: ["method": method])
}

private func trackOnboardingStarted() {
    analyticsService.track("onboarding_started", properties: [
        "signup_method": selectedSignupMethod?.rawValue ?? "unknown"
    ])
}

// ✅ GOOD: Consistent analytics with helper
private func trackAnalyticsEvent(_ eventName: String, properties: [String: Any]) {
    guard let userId = userProfile?.id else {
        Logger.error("[ViewModel] Missing user ID during \(eventName) analytics")
        return
    }
    
    var eventProperties = properties
    eventProperties["userID"] = userId
    eventProperties["timestamp"] = Date().timeIntervalSince1970
    
    analyticsService.track(eventName, properties: eventProperties, origin: "ViewModel")
}

// Usage:
private func trackSignupMethodSelected(method: String) {
    trackAnalyticsEvent("onboarding_signup_method_selected", properties: ["method": method])
}

private func trackOnboardingStarted() {
    trackAnalyticsEvent("onboarding_started", properties: [
        "signup_method": selectedSignupMethod?.rawValue ?? "unknown"
    ])
}
```

## 🔄 Concurrency & Threading

### Rule: Use @MainActor for UI-Bound Logic

**Why**: UI-bound logic in ViewModels should be `@MainActor` to avoid race conditions or thread violations.

```swift
// ✅ GOOD: @MainActor for UI-bound ViewModels
@MainActor
final class OnboardingJourneyViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .signupMethod
    @Published var errorMessage: String?
    
    func selectGetStarted() {
        // UI updates are safe on main thread
        currentStep = .explainer
    }
}

// ✅ GOOD: @MainActor for test classes that interact with ViewModels
@MainActor
class OnboardingFlowTests: XCTestCase {
    func testUserSelectsGetStarted() {
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
}
```

## 🛠️ Tooling & Automation

### Recommended Tools

**SwiftLint for Method Length**
```yaml
# .swiftlint.yml
function_body_length:
  warning: 20
  error: 30
```

**Sourcery for Boilerplate**
```swift
// Generate mock protocols automatically
// Generate equatable conformance
// Generate test helpers
```

**SwiftFormat for Code Style**
```bash
# Format code automatically
swiftformat --indent 4 --trimwhitespace always .
```

**XCTFail Helpers for Error Assertions**
```swift
// Custom assertion helpers for better error messages
func XCTAssertAnalyticsTracked(_ event: String, in mock: MockAnalyticsService) {
    XCTAssertTrue(mock.trackedEvents.contains(event), 
                  "Expected analytics event '\(event)' to be tracked")
}

func XCTAssertUserProfileCreated(in viewModel: OnboardingJourneyViewModel) {
    XCTAssertNotNil(viewModel.userProfile, 
                   "Expected user profile to be created")
}
```

## 🎯 MVP vs Post-MVP Considerations

### Essential for MVP (Implement Now)
- [x] **Method Length**: Keep methods under 20 lines
- [x] **Single Responsibility**: One responsibility per method
- [x] **@MainActor**: Use for UI-bound ViewModels
- [x] **Basic Error Handling**: Consistent error messages
- [x] **Test Data Validation**: Validate factory method inputs

### Post-MVP Enhancements (Phase In Later)
- [ ] **Analytics Consistency**: Centralized analytics helpers
- [ ] **UI Content Centralization**: String constants for all UI text
- [ ] **Advanced Tooling**: SwiftLint, Sourcery, SwiftFormat
- [ ] **Comprehensive Error Handling**: Custom error types and recovery
- [ ] **Performance Optimization**: Lazy loading, caching strategies

## 📋 Code Review Checklist

When reviewing code, check for:

### ✅ Do's
- [ ] **[Length]** Methods under 20 lines?
- [ ] **[SRP]** One responsibility per method?
- [ ] **[Reuse]** Common code extracted to helpers?
- [ ] **[Error]** Consistent error handling?
- [ ] **[UI]** Strings centralized or hardcoded?
- [ ] **[State]** State set directly on ViewModels?
- [ ] **[Analytics]** Analytics tracking consistent?
- [ ] **[Test Data]** Factory methods validate inputs?
- [ ] **[Documentation]** Complex methods documented?
- [ ] **[MainActor]** UI-bound ViewModels use @MainActor?

### ❌ Don'ts
- [ ] **[Anti-Pattern]** Methods over 50 lines?
- [ ] **[Anti-Pattern]** Multiple responsibilities in one method?
- [ ] **[Anti-Pattern]** Repeated code patterns?
- [ ] **[Anti-Pattern]** Inconsistent error handling?
- [ ] **[Anti-Pattern]** Hardcoded UI strings?
- [ ] **[Anti-Pattern]** Setting mock properties instead of ViewModel state?
- [ ] **[Anti-Pattern]** Inconsistent analytics tracking?
- [ ] **[Anti-Pattern]** Factory methods without input validation?
- [ ] **[Anti-Pattern]** Missing @MainActor on UI-bound ViewModels?

## 🚀 Implementation Strategy

### Phase 1: Identify Long Methods
1. Scan codebase for methods over 20 lines
2. Identify methods with multiple responsibilities
3. Document current patterns and issues

### Phase 2: Extract Helpers
1. Identify repeated patterns
2. Create helper methods for common operations
3. Update existing code to use helpers

### Phase 3: Centralize Content
1. Create string constants for UI content
2. Centralize error handling patterns
3. Standardize analytics tracking

### Phase 4: Validate & Test
1. Ensure all tests still pass
2. Validate that refactoring improves maintainability
3. Document new patterns for future development

## 🎯 Benefits of Following These Patterns

### Immediate Benefits:
- **Easier Testing**: Smaller methods are easier to test in isolation
- **Better Debugging**: Focused methods make it easier to identify issues
- **Improved Readability**: Code is more self-documenting
- **Reduced Duplication**: Helper methods eliminate repeated code

### Long-term Benefits:
- **Faster Development**: Less time spent debugging and refactoring
- **Easier Onboarding**: New developers can understand code faster
- **Better Maintainability**: Changes are localized to specific methods
- **Reduced Technical Debt**: Cleaner codebase with less complexity

---

**Last Updated**: December 2024
**Maintained By**: Development Team
**Review Cycle**: Monthly 