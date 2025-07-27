//
//  AuthValidationTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for authentication validation
//  Tests form input validation and error handling
//
//  Improvements:
//  - Consolidated redundant error message tests
//  - Merged validation tests for better maintainability
//  - Removed overzealous state checks
//  - Focused on essential validation scenarios

import XCTest
@testable import Sage

class AuthValidationTests: XCTestCase {
    var authViewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthViewModel(disableAutoAuth: true)
    }
    
    override func tearDown() {
        authViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func setValidCredentials() {
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
    }
    
    private func setInvalidCredentials() {
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
    }
    
    // MARK: - Email Validation Tests
    func testEmailValidation() {
        // Given: Valid email
        authViewModel.email = "test@example.com"
        
        // When: Email validation is checked
        // Then: Should be valid
        XCTAssertTrue(authViewModel.isEmailValid, "Valid email should pass validation")
        
        // Given: Invalid email
        authViewModel.email = "invalid-email"
        
        // When: Email validation is checked
        // Then: Should be invalid
        XCTAssertFalse(authViewModel.isEmailValid, "Invalid email should fail validation")
    }
    
    func testPasswordValidation() {
        // Given: Valid password (6+ characters)
        authViewModel.password = "password123"
        
        // When: Password validation is checked
        // Then: Should be valid
        XCTAssertTrue(authViewModel.isPasswordValid, "Valid password should pass validation")
        
        // Given: Invalid password (too short)
        authViewModel.password = "123"
        
        // When: Password validation is checked
        // Then: Should be invalid
        XCTAssertFalse(authViewModel.isPasswordValid, "Short password should fail validation")
        
        // Given: Empty password
        authViewModel.password = ""
        
        // When: Password validation is checked
        // Then: Should be invalid
        XCTAssertFalse(authViewModel.isPasswordValid, "Empty password should fail validation")
    }
    
    func testFormValidation() {
        // Given: Valid credentials
        setValidCredentials()
        
        // When: Form validation is checked
        // Then: Should be valid
        XCTAssertTrue(authViewModel.isFormValid, "Valid credentials should pass form validation")
        
        // Given: Invalid credentials
        setInvalidCredentials()
        
        // When: Form validation is checked
        // Then: Should be invalid
        XCTAssertFalse(authViewModel.isFormValid, "Invalid credentials should fail form validation")
    }
    
    // MARK: - Error Message Tests
    func testInvalidCredentialsShowAppropriateErrors() {
        // Given: Invalid email (malformed)
        authViewModel.email = "invalid-email"
        authViewModel.password = "password123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid email")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidEmail.message, "Should show exact invalid email error")
        XCTAssertFalse(authViewModel.isEmailValid, "Email should be invalid")
        
        // Given: Empty email
        authViewModel.email = ""
        authViewModel.password = "password123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for empty email")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidEmail.message, "Should show exact invalid email error")
        XCTAssertFalse(authViewModel.isEmailValid, "Empty email should be invalid")
        
        // Given: Invalid password (too short)
        authViewModel.email = "test@example.com"
        authViewModel.password = "123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid password")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidPassword.message, "Should show exact invalid password error")
        XCTAssertFalse(authViewModel.isPasswordValid, "Password should be invalid")
        
        // Given: Empty password
        authViewModel.email = "test@example.com"
        authViewModel.password = ""
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for empty password")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidPassword.message, "Should show exact invalid password error")
        XCTAssertFalse(authViewModel.isPasswordValid, "Password should be invalid")
    }
    
    func testFormValidationPreventsSubmission() {
        // Given: Invalid form data
        setInvalidCredentials()
        
        // When: Form validation is checked and sign up is attempted
        let isFormValid = authViewModel.isFormValid
        authViewModel.signUpWithEmail()
        
        // Then: Should be invalid and prevent submission
        XCTAssertFalse(isFormValid, "Form should be invalid")
        XCTAssertFalse(authViewModel.isEmailValid, "Email should be invalid")
        XCTAssertFalse(authViewModel.isPasswordValid, "Password should be invalid")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown")
        XCTAssertFalse(authViewModel.isLoading, "Should not start loading when validation fails")
    }
    
    func testResetClearsErrorState() {
        // Given: Error state
        setInvalidCredentials()
        authViewModel.signUpWithEmail() // This sets an error
        XCTAssertNotNil(authViewModel.errorMessage)
        
        // When: Reset is called
        authViewModel.reset()
        
        // Then: Error should be cleared
        XCTAssertNil(authViewModel.errorMessage, "Error message should be cleared on reset")
        XCTAssertEqual(authViewModel.email, "", "Email should be cleared on reset")
        XCTAssertEqual(authViewModel.password, "", "Password should be cleared on reset")
    }
} 