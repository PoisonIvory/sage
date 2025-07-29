# Sage Tests - TDD Best Practices Implementation

This directory contains the organized test suite for the Sage app, following Test-Driven Development (TDD) best practices.

## File Structure

```
SageTests/
 Mocks/
    AuthMocks.swift          // Mock Firebase Auth objects
    OnboardingMocks.swift    // Mock coordinator objects
 Authentication/
    AuthViewModelTests.swift     // Unit tests for AuthViewModel
    AuthErrorHandlingTests.swift // Error handling tests
    AuthFlowTests.swift          // Integration tests
 Onboarding/
    OnboardingFlowViewModelTests.swift // Onboarding flow tests
 Recording/
    RecordingValidationTests.swift     // Audio validation tests
 SageTests.swift              // Main reference file
 README.md                    // This file
```

## Test Categories

### 1. Unit Tests
Test individual components in isolation:
- **AuthViewModelTests.swift**: Tests for authentication logic (no format-only validation; Firebase handles this)
- **OnboardingFlowViewModelTests.swift**: Tests for onboarding flow
- **RecordingValidationTests.swift**: Tests for audio validation

### 2. Integration Tests
Test how components work together:
- **AuthFlowTests.swift**: Tests authentication flow between components

### 3. Error Handling Tests
Test failure scenarios:
- **AuthErrorHandlingTests.swift**: Tests error handling and user-friendly messages (no format-only validation)

### 4. Mock Objects
Fake external dependencies:
- **AuthMocks.swift**: Mock Firebase Auth objects
- **OnboardingMocks.swift**: Mock coordinator objects

## TDD Cycle

### RED  GREEN  REFACTOR

1. **RED**: Write failing tests that describe desired behavior
2. **GREEN**: Implement minimum code to make tests pass
3. **REFACTOR**: Improve code while keeping tests green

## GWT Format

Each test follows the Given-When-Then structure:

```swift
@Test func loginWithValidEmailAndPasswordAuthenticatesUser() async throws {
    // Given: AuthViewModel with valid email and password
    let viewModel = AuthViewModel()
    viewModel.email = "user@example.com"
    viewModel.password = "password123"
    
    // When: User logs in with email
    viewModel.loginWithEmail()
    
    // Then: The user is authenticated
    #expect(viewModel.isAuthenticated == true)
    #expect(viewModel.errorMessage == nil)
}
```

## Benefits

- **Easy to find specific tests** when something breaks
- **Clear separation of concerns** with organized file structure
- **Maintainable** as codebase grows
- **Living documentation** of expected behavior
- **Confidence in refactoring** with comprehensive test coverage

## Running Tests

To run all tests:
```bash
# In Xcode: Cmd+U
# Or from terminal:
xcodebuild test -project Sage.xcodeproj -scheme Sage
```

To run specific test categories:
```bash
# Run only authentication tests
xcodebuild test -project Sage.xcodeproj -scheme Sage -only-testing:SageTests/AuthViewModelTests

# Run only error handling tests
xcodebuild test -project Sage.xcodeproj -scheme Sage -only-testing:SageTests/AuthErrorHandlingTests
```

## Adding New Tests

##  Important: Debugging Learnings & Code Quality

Before writing new tests or code, please review our documentation:

### [Debugging Learnings & Best Practices](./DEBUGGING_LEARNINGS.md)
Contains:
- Common debugging patterns we've identified
- Best practices for test development
- Pre-testing checklist
- Common fixes we've applied
- Expected benefits of following these practices

### [Code Quality Patterns & Best Practices](./CODE_QUALITY_PATTERNS.md)
Contains:
- Method length and complexity guidelines
- Helper method extraction patterns
- UI content centralization strategies
- State management best practices
- Analytics tracking consistency
- Code review checklist

**Key Takeaways**:
- Always verify actual implementation behavior before writing tests
- Set up state directly on ViewModels rather than relying on mocks
- Keep methods under 20 lines with single responsibility
- Extract common patterns into helper methods
- Centralize UI strings and error handling

When adding new functionality:

1. **Create new test file** in appropriate category
2. **Follow GWT format** for test structure
3. **Use existing mocks** or create new ones in Mocks/ directory
4. **Update this README** if adding new test categories

## Best Practices

- **One test file per component/feature**
- **Descriptive test names** that explain the behavior
- **Mock external dependencies** to isolate unit tests
- **Reset mock state** between tests
- **Document complex test scenarios** with comments
- **Keep tests focused** on single responsibility 