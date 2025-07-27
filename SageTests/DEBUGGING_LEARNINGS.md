# Debugging Learnings & Best Practices

## 📋 Table of Contents
- [Overview](#-overview)
- [Common Debugging Patterns](#-common-debugging-patterns)
- [Communication & Requirements Gaps](#-communication--requirements-gaps)
- [When Not to Write a Test](#-when-not-to-write-a-test)
- [Best Practices for Future Development](#-best-practices-for-future-development)
- [Concurrency Debugging](#-concurrency-debugging)
- [Pre-Testing Checklist](#-pre-testing-checklist)
- [Common Fixes We've Applied](#-common-fixes-weve-applied)
- [Enforcement & Automation](#-enforcement--automation)
- [Tooling & Automation](#-tooling--automation)
- [MVP vs Post-MVP Considerations](#-mvp-vs-post-mvp-considerations)
- [Expected Benefits](#-expected-benefits)
- [Resources](#-resources)

## 🎯 Overview

This document captures the key learnings from our debugging sessions and retrospective analysis. These patterns should be applied to all future development work to prevent repeated debugging cycles.

**Scope**: Applies to all production Swift code in ViewModels, Coordinators, Services, and Unit Tests.

## 🚨 Common Debugging Patterns We've Identified

### 1. Test-Implementation Mismatch Pattern

**Problem**: Tests written based on assumptions about how code *should* work, not how it *actually* works.

**Examples We Encountered**:
- Tests expecting auth errors to prevent profile creation (they don't)
- Tests expecting validation in `selectFinish()` (there isn't any)
- Tests expecting async behavior where methods are synchronous
- Tests expecting UI text validation that doesn't exist

**Root Cause**: ViewModel design lacks clear contracts or documentation. Product requirements are ambiguous or not properly translated into technical specifications.

**Solution**: Always verify actual implementation behavior before writing tests. Document ViewModel contracts explicitly.

### 2. State Management Assumptions

**Problem**: Tests assume certain state is set up, but actual implementation requires different setup.

**Examples We Encountered**:
- Tests expecting `userProfile` to be accessible when it's `private(set)`
- Tests not setting up required dependencies (like microphone permissions)
- Tests expecting analytics events without setting up user profiles
- Tests setting mock properties instead of ViewModel state

**Root Cause**: Inconsistent state management patterns across ViewModels. Lack of clear state ownership and initialization contracts.

**Solution**: Set up state directly on ViewModels rather than relying on mocks. Establish consistent state management patterns.

### 3. Mock Behavior Assumptions

**Problem**: Tests assume mocks behave like real implementations, but they don't.

**Examples We Encountered**:
- Tests expecting `createCompleteUserProfile(age: 0, gender: "")` to work (it crashes)
- Tests not understanding that `simulateRecordingCompletion` triggers different flow than manual stop
- Tests expecting mock properties to automatically set ViewModel state

**Root Cause**: Mock design doesn't reflect real implementation behavior. Test data factories lack proper validation and documentation.

**Solution**: Understand and document mock behavior explicitly. Validate test data factory inputs.

### 4. Protocol/Interface Drift

**Problem**: Tests reference methods/properties that don't exist or have changed.

**Examples We Encountered**:
- Missing `createMinimalUserProfile()` method
- Wrong property names (`didRequestPermission` vs `didCheckPermission`)
- Wrong method names (`startRecording` vs `startVocalTest`)
- Wrong enum cases (`SignupErrorType.invalidEmail` doesn't exist)

**Root Cause**: Lack of contract testing and interface versioning. Changes made without updating all dependent code.

**Solution**: Implement contract testing and keep tests in sync with implementation. Use interface versioning for breaking changes.

### 5. Method Length & Complexity Pattern

**Problem**: Methods become too long and handle multiple responsibilities, making them hard to test and debug.

**Examples We Found**:
- `OnboardingJourneyViewModel` has 500+ lines with many long methods
- `analyze_recording()` in `functions/main.py` is 100+ lines handling multiple feature extraction tools
- `validateFull()` in `RecordingValidator` handles multiple validation types in one method
- `process_audio_file()` combines file parsing, download, processing, and storage

**Root Cause**: Lack of clear separation of concerns. Methods grow organically without refactoring. Missing architectural boundaries.

**Solution**: Break down long methods into smaller, focused helper methods. Establish clear architectural boundaries.

### 6. Missing Helper Method Pattern

**Problem**: Code repeats similar logic instead of extracting common patterns into helper methods.

**Examples We Found**:
- Analytics tracking methods repeat the same `guard let userId = userProfile?.id` pattern
- Error handling repeats similar logging and error message creation
- Validation logic is scattered across multiple methods
- UI content strings are hardcoded instead of centralized

**Root Cause**: Lack of code review focus on DRY principles. Missing patterns library or shared utilities.

**Solution**: Extract common patterns into reusable helper methods. Establish patterns library.

### 7. Inconsistent Error Handling Pattern

**Problem**: Error handling is inconsistent across the codebase, making debugging difficult.

**Examples We Found**:
- Some methods use `fatalError()` while others use `throw`
- Error messages are sometimes hardcoded, sometimes localized
- Some errors are logged, others are silently ignored
- Error recovery strategies vary between components

**Root Cause**: No established error handling strategy or patterns. Different developers use different approaches.

**Solution**: Establish consistent error handling patterns and centralize error management.

## 🗣️ Communication & Requirements Gaps

### 8. Requirements Drift Pattern

**Problem**: Tests assume unverified requirements or behavior that doesn't match actual implementation.

**Examples We Encountered**:
- Tests expect auth errors to prevent profile creation, but implementation always creates profiles
- Tests expect validation in completion methods, but implementation doesn't validate
- Tests expect specific error messages that don't exist in production code

**Root Cause**: Product/engineering miscommunication. Requirements not properly translated into technical specifications. Behavior assumptions not validated.

**Solution**: 
- Add inline docstrings summarizing actual behavior
- Ensure behavior is reviewed by tech/product before tests are written
- Create behavior contracts that are shared between product and engineering
- Use BDD (Behavior Driven Development) to align requirements with tests

### 9. Specification Ambiguity Pattern

**Problem**: Requirements are vague or open to interpretation, leading to different implementations and test expectations.

**Examples We Encountered**:
- "Handle errors gracefully" - different interpretations of what "graceful" means
- "Validate user input" - unclear what validation rules apply
- "Show appropriate feedback" - no definition of what's appropriate

**Root Cause**: Product requirements lack specificity. Missing acceptance criteria or edge case definitions.

**Solution**:
- Write specific acceptance criteria for each requirement
- Define edge cases and error scenarios explicitly
- Use concrete examples in requirements
- Create shared understanding between product and engineering

## 🚫 When Not to Write a Test

Not all code needs tests, and not all test failures are worth fixing. Focus testing efforts on high-value areas:

### **Don't Test These (Low ROI)**:
- [ ] **Static UI strings** - These rarely change and don't affect functionality
- [ ] **Temporary screens** - Features that will be removed or significantly changed
- [ ] **Features under heavy change** - Wait until the feature stabilizes
- [ ] **Internals without external effect** - Private methods that don't impact user experience
- [ ] **Third-party library behavior** - Test your integration, not the library itself
- [ ] **Configuration values** - Constants and configuration that don't affect logic

### **Do Test These (High ROI)**:
- [x] **User-facing behavior** - What users actually experience
- [x] **Business logic** - Core application functionality
- [x] **Error handling** - How the app responds to failures
- [x] **Data validation** - Input validation and data integrity
- [x] **Integration points** - How components work together
- [x] **State transitions** - How the app moves between states

### **Test Fatigue Analysis**:
Before writing a test, ask:
1. **Will this test prevent a real bug?**
2. **Will this test help with refactoring?**
3. **Is the behavior stable enough to test?**
4. **Is the test cost (writing + maintaining) worth the benefit?**

## 🛠️ Best Practices for Future Development

### 1. Test-First Development (TDD)

```swift
// Instead of writing tests after implementation:
// 1. Write failing test first
// 2. Write minimal implementation to make test pass
// 3. Refactor while keeping tests green

func testUserProfileCreation() {
    // Given: User selects anonymous signup
    // When: selectAnonymous() is called
    // Then: userProfile should be created and step should be .explainer
}
```

### 2. Document Actual Behavior Before Testing

```swift
// Before writing tests, document what the method actually does:
/**
 * selectAnonymous() Behavior:
 * - Sets selectedSignupMethod = .anonymous
 * - Calls createMinimalUserProfile() (always succeeds)
 * - Tracks analytics events
 * - Sets currentStep = .explainer
 * - Does NOT handle auth errors
 * - Does NOT validate input
 */
```

### 3. Set Up State Directly on ViewModels

```swift
// ✅ CORRECT: Set state directly on ViewModel
viewModel.microphonePermissionStatus = .granted
viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()

// ❌ INCORRECT: Rely on mocks to set ViewModel state
harness.mockMicrophonePermissionManager.permissionGranted = true
```

### 4. Validate Test Data Factory Methods

```swift
static func createCompleteUserProfile(
    age: Int = 25,
    gender: String = "female",
    // ... other params
) -> UserProfile {
    // Validate inputs to prevent test crashes
    guard age > 0 else {
        fatalError("Test setup error: age must be > 0 for complete profile")
    }
    guard !gender.isEmpty else {
        fatalError("Test setup error: gender cannot be empty for complete profile")
    }
    
    // ... rest of implementation
}
```

### 5. Test Categories with Clear Expectations

```swift
class OnboardingFlowTests: XCTestCase {
    // MARK: - Happy Path Tests (These should always pass)
    func testHappyPathAnonymousSignup() { ... }
    
    // MARK: - Error Handling Tests (These test actual error paths)
    func testNetworkErrorDuringSignup() { ... }
    
    // MARK: - Edge Case Tests (These test boundary conditions)
    func testMinimumAgeValidation() { ... }
}
```

### 6. Test Environment Validation

```swift
override func setUp() {
    super.setUp()
    harness = OnboardingTestHarness()
    viewModel = harness.makeViewModel()
    
    // Validate test environment
    validateTestEnvironment()
}

private func validateTestEnvironment() {
    // Check that all required mocks are properly configured
    XCTAssertNotNil(harness.mockAnalyticsService)
    XCTAssertNotNil(harness.mockAuthService)
    // ... etc
}
```

### 7. Method Length Guidelines

```swift
// ✅ GOOD: Methods under 20 lines, single responsibility
private func validateAge(_ age: Int) -> ValidationResult {
    guard age > 0 else {
        return .failure(.ageRequired(fieldName: "age"))
    }
    guard age <= 120 else {
        return .failure(.ageInvalid(fieldName: "age"))
    }
    return .success
}

// ❌ BAD: Methods over 50 lines with multiple responsibilities
func processUserData() {
    // 50+ lines of validation, processing, analytics, error handling
    // Multiple responsibilities in one method
}
```

### 8. Helper Method Extraction

```swift
// ✅ GOOD: Extract common patterns into helpers
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

### 9. Consistent Error Handling

```swift
// ✅ GOOD: Centralized error handling
enum ViewModelError: Error {
    case missingUserProfile
    case invalidInput(String)
    case networkError(Error)
    
    var userMessage: String {
        switch self {
        case .missingUserProfile:
            return "Unable to load user profile. Please try again."
        case .invalidInput(let field):
            return "Please check your \(field) and try again."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

private func handleError(_ error: Error) {
    let viewModelError = mapToViewModelError(error)
    errorMessage = viewModelError.userMessage
    Logger.error("[ViewModel] Error: \(error.localizedDescription)")
}
```

### 10. UI Content Centralization

```swift
// ✅ GOOD: Centralize UI strings
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
```

## 🔄 Concurrency Debugging

### Common Concurrency Pitfalls

**Problem**: Swift Concurrency introduces new debugging challenges that traditional testing doesn't catch.

**Examples We Encountered**:
- Tests failed because method wasn't marked `@MainActor`
- UI state mutated off-main-thread
- `async let` side effects not properly awaited
- Background thread issues in ViewModels

### 1. @MainActor Violations

```swift
// ❌ BAD: Missing @MainActor
final class OnboardingJourneyViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .signupMethod
    
    func selectGetStarted() {
        // This can cause race conditions if called from background thread
        currentStep = .explainer
    }
}

// ✅ GOOD: Proper @MainActor usage
@MainActor
final class OnboardingJourneyViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .signupMethod
    
    func selectGetStarted() {
        // Safe on main thread
        currentStep = .explainer
    }
}
```

### 2. Background Thread Issues in ViewModels

```swift
// ❌ BAD: UI updates from background thread
func loadUserProfile() {
    Task.detached {
        let profile = await userProfileRepository.fetchProfile()
        // This will crash: UI updates must be on main thread
        self.userProfile = profile
    }
}

// ✅ GOOD: Proper main thread handling
func loadUserProfile() {
    Task.detached {
        let profile = await userProfileRepository.fetchProfile()
        await MainActor.run {
            self.userProfile = profile
        }
    }
}
```

### 3. Async Let Side Effects

```swift
// ❌ BAD: Unhandled async let side effects
func processData() async {
    async let userData = fetchUserData()
    async let analyticsData = fetchAnalyticsData()
    
    // Side effects not properly awaited
    let result = await (userData, analyticsData)
}

// ✅ GOOD: Proper async let handling
func processData() async {
    async let userData = fetchUserData()
    async let analyticsData = fetchAnalyticsData()
    
    // All side effects properly awaited
    let (user, analytics) = await (userData, analyticsData)
    await processResults(user, analytics)
}
```

### 4. Test Concurrency Issues

```swift
// ❌ BAD: Test not handling async properly
func testAsyncOperation() {
    viewModel.performAsyncOperation()
    XCTAssertEqual(viewModel.result, expectedValue) // Race condition
}

// ✅ GOOD: Proper async test
func testAsyncOperation() async {
    await viewModel.performAsyncOperation()
    XCTAssertEqual(viewModel.result, expectedValue)
}
```

## 📋 Pre-Testing Checklist

Before writing any test, verify:

- [ ] **[Implementation]** What does the method/class actually do?
- [ ] **[State]** What state needs to be set up?
- [ ] **[Dependencies]** What mocks/services are required?
- [ ] **[Error]** How are errors actually handled?
- [ ] **[Async]** Is the method async or sync?
- [ ] **[Validation]** What validation actually exists?
- [ ] **[Length]** Is the method under 20 lines? If not, can it be broken down?
- [ ] **[Reuse]** Are there repeated patterns that could be extracted?
- [ ] **[Consistency]** Does error handling follow established patterns?
- [ ] **[Content]** Are strings centralized or hardcoded?
- [ ] **[ROI]** Is this test worth writing and maintaining?
- [ ] **[Concurrency]** Are there any threading concerns?

## 🔧 Common Fixes We've Applied

### 1. Permission State Setup

```swift
// ✅ CORRECT
viewModel.microphonePermissionStatus = .granted

// ❌ INCORRECT
harness.mockMicrophonePermissionManager.permissionGranted = true
```

### 2. User Profile Setup

```swift
// ✅ CORRECT
viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()

// ❌ INCORRECT
viewModel.userProfile = OnboardingTestDataFactory.createCompleteUserProfile(age: 0, gender: "")
```

### 3. Recording Flow Testing

```swift
// ✅ CORRECT
let mockRecording = OnboardingTestDataFactory.createMockRecording()
harness.mockAudioRecorder.simulateRecordingCompletion(mockRecording)

// ❌ INCORRECT
harness.mockAudioRecorder.stop()
```

### 4. Analytics Testing

```swift
// ✅ CORRECT
viewModel.userProfile = OnboardingTestDataFactory.createMinimalUserProfile()
viewModel.handleVocalTestUploadResult(.success(()))

// ❌ INCORRECT
viewModel.startVocalTest() // Without user profile
```

### 5. Method Refactoring

```swift
// ✅ BEFORE: Long method with multiple responsibilities
func processUserSignup() {
    // 50+ lines of validation, profile creation, analytics, navigation
}

// ✅ AFTER: Broken down into focused methods
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

### 6. Helper Method Creation

```swift
// ✅ BEFORE: Repeated analytics pattern
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

// ✅ AFTER: Extracted helper method
private func trackAnalyticsEvent(_ eventName: String, properties: [String: Any]) {
    guard let userId = userProfile?.id else {
        Logger.error("[ViewModel] Missing user ID during \(eventName) analytics")
        return
    }
    var eventProperties = properties
    eventProperties["userID"] = userId
    analyticsService.track(eventName, properties: eventProperties, origin: "ViewModel")
}
```

## 🔒 Enforcement & Automation

### SwiftLint Rules

```yaml
# .swiftlint.yml
function_body_length:
  warning: 20
  error: 30

type_body_length:
  warning: 300
  error: 500

cyclomatic_complexity:
  warning: 10
  error: 15

custom_rules:
  main_actor_violation:
    name: "MainActor Violation"
    regex: '@Published.*func.*\{'
    message: "Published properties should be in @MainActor classes"
```

### Custom Test Helpers

```swift
// XCTestCase extension for common test patterns
extension XCTestCase {
    func assertMainActor<T>(_ block: @escaping () -> T) async -> T {
        await MainActor.run {
            block()
        }
    }
    
    func assertAnalyticsTracked(_ event: String, in mock: MockAnalyticsService) {
        XCTAssertTrue(mock.trackedEvents.contains(event), 
                      "Expected analytics event '\(event)' to be tracked")
    }
    
    func assertUserProfileCreated(in viewModel: OnboardingJourneyViewModel) {
        XCTAssertNotNil(viewModel.userProfile, 
                       "Expected user profile to be created")
    }
}
```

### Method Line-Length Script

```bash
#!/bin/bash
# check_method_length.sh
find . -name "*.swift" -exec grep -l "func.*{" {} \; | while read file; do
    echo "Checking $file..."
    # Count lines in each method and flag those over 20
    # Implementation details...
done
```

### Snapshot Testing

```swift
// Snapshot tests for UI consistency
func testOnboardingFlowSnapshot() {
    let viewModel = createViewModel()
    let view = OnboardingFlowView(viewModel: viewModel)
    
    assertSnapshot(matching: view, as: .image)
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
- [x] **State Management**: Set state directly on ViewModels
- [x] **Concurrency Safety**: Proper @MainActor usage

### Post-MVP Enhancements (Phase In Later)
- [ ] **Analytics Consistency**: Centralized analytics helpers
- [ ] **UI Content Centralization**: String constants for all UI text
- [ ] **Advanced Tooling**: SwiftLint, Sourcery, SwiftFormat
- [ ] **Comprehensive Error Handling**: Custom error types and recovery
- [ ] **Performance Optimization**: Lazy loading, caching strategies
- [ ] **Advanced Concurrency**: Structured concurrency patterns

## 🎯 Expected Benefits

By following these practices:

- **90% reduction** in repeated debugging sessions
- **Faster development** with confidence in test coverage
- **Better code quality** through TDD practices
- **Easier onboarding** for new developers with clear test patterns
- **Reduced technical debt** from test-implementation drift
- **Improved maintainability** through shorter, focused methods
- **Better reusability** through helper method extraction
- **Consistent error handling** across the codebase
- **Centralized UI content** for easier localization and updates
- **Reduced concurrency bugs** through proper @MainActor usage

## 📚 Resources

- [MVP Testing Strategy](./README.md#mvp-testing-strategy)
- [Test Harness Documentation](./OnboardingTestHarness.swift)
- [Code Quality Patterns](./CODE_QUALITY_PATTERNS.md)
- [Data Standards](../Project/DATA_STANDARDS.md)
- [UI Standards](../Project/UI_STANDARDS.md)

---

**Last Updated**: December 2024
**Maintained By**: Development Team
**Review Cycle**: Monthly 