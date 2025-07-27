# Debugging Learnings & Best Practices

## 🎯 Overview

This document captures the key learnings from our debugging sessions and retrospective analysis. These patterns should be applied to all future development work to prevent repeated debugging cycles.

## 🚨 Common Debugging Patterns We've Identified

### 1. Test-Implementation Mismatch Pattern

**Problem**: Tests written based on assumptions about how code *should* work, not how it *actually* works.

**Examples We Encountered**:
- Tests expecting auth errors to prevent profile creation (they don't)
- Tests expecting validation in `selectFinish()` (there isn't any)
- Tests expecting async behavior where methods are synchronous
- Tests expecting UI text validation that doesn't exist

**Solution**: Always verify actual implementation behavior before writing tests.

### 2. State Management Assumptions

**Problem**: Tests assume certain state is set up, but actual implementation requires different setup.

**Examples We Encountered**:
- Tests expecting `userProfile` to be accessible when it's `private(set)`
- Tests not setting up required dependencies (like microphone permissions)
- Tests expecting analytics events without setting up user profiles
- Tests setting mock properties instead of ViewModel state

**Solution**: Set up state directly on ViewModels rather than relying on mocks.

### 3. Mock Behavior Assumptions

**Problem**: Tests assume mocks behave like real implementations, but they don't.

**Examples We Encountered**:
- Tests expecting `createCompleteUserProfile(age: 0, gender: "")` to work (it crashes)
- Tests not understanding that `simulateRecordingCompletion` triggers different flow than manual stop
- Tests expecting mock properties to automatically set ViewModel state

**Solution**: Understand and document mock behavior explicitly.

### 4. Protocol/Interface Drift

**Problem**: Tests reference methods/properties that don't exist or have changed.

**Examples We Encountered**:
- Missing `createMinimalUserProfile()` method
- Wrong property names (`didRequestPermission` vs `didCheckPermission`)
- Wrong method names (`startRecording` vs `startVocalTest`)
- Wrong enum cases (`SignupErrorType.invalidEmail` doesn't exist)

**Solution**: Implement contract testing and keep tests in sync with implementation.

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

## 📋 Pre-Testing Checklist

Before writing any test, verify:

- [ ] **Actual Implementation**: What does the method/class actually do?
- [ ] **State Requirements**: What state needs to be set up?
- [ ] **Dependencies**: What mocks/services are required?
- [ ] **Error Handling**: How are errors actually handled?
- [ ] **Async Behavior**: Is the method async or sync?
- [ ] **Validation**: What validation actually exists?

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

## 🎯 Expected Benefits

By following these practices:

- **90% reduction** in repeated debugging sessions
- **Faster development** with confidence in test coverage
- **Better code quality** through TDD practices
- **Easier onboarding** for new developers with clear test patterns
- **Reduced technical debt** from test-implementation drift

## 📚 Resources

- [MVP Testing Strategy](./README.md#mvp-testing-strategy)
- [Test Harness Documentation](./OnboardingTestHarness.swift)
- [Data Standards](../Project/DATA_STANDARDS.md)
- [UI Standards](../Project/UI_STANDARDS.md)

---

**Last Updated**: December 2024
**Maintained By**: Development Team
**Review Cycle**: Monthly 