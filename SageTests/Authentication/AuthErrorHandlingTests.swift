//
//  AuthErrorHandlingTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for authentication error handling
//  Tests error scenarios and user feedback

import XCTest
@testable import Sage

class AuthErrorHandlingTests: XCTestCase {
    var authViewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthViewModel(disableAutoAuth: true)
    }
    
    override func tearDown() {
        authViewModel = nil
        super.tearDown()
    }
    
    func testInvalidEmailShowsErrorMessage() {
        // Given: Invalid email (malformed)
        authViewModel.email = "invalid-email"
        authViewModel.password = "password123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid email")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidEmail.message, "Should show exact invalid email error")
        XCTAssertFalse(authViewModel.isEmailValid, "Email should be invalid")
    }
    
    func testEmptyEmailShowsErrorMessage() {
        // Given: Empty email
        authViewModel.email = ""
        authViewModel.password = "password123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for empty email")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidEmail.message, "Should show exact invalid email error")
        XCTAssertFalse(authViewModel.isEmailValid, "Empty email should be invalid")
    }
    
    func testInvalidPasswordShowsErrorMessage() {
        // Given: Invalid password (too short)
        authViewModel.email = "test@example.com"
        authViewModel.password = "123"
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid password")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidPassword.message, "Should show exact invalid password error")
        XCTAssertFalse(authViewModel.isPasswordValid, "Password should be invalid")
    }
    
    func testEmptyPasswordShowsErrorMessage() {
        // Given: Empty password
        authViewModel.email = "test@example.com"
        authViewModel.password = ""
        
        // When: Sign up is attempted
        authViewModel.signUpWithEmail()
        
        // Then: Sign up fails and error message is shown
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for empty password")
        XCTAssertEqual(authViewModel.errorMessage, AuthError.invalidPassword.message, "Should show exact invalid password error")
        XCTAssertFalse(authViewModel.isPasswordValid, "Empty password should be invalid")
    }
    
    func testFormValidationPreventsSubmission() {
        // Given: Invalid form data
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
        
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
    
    func testErrorStateIsClearedOnValidInput() {
        // Given: Error state
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
        authViewModel.signUpWithEmail() // This sets an error
        XCTAssertNotNil(authViewModel.errorMessage, "Error should be set initially")
        
        // When: Valid input is provided
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
        
        // Then: Form should be valid (error message persists until next submission)
        XCTAssertTrue(authViewModel.isFormValid, "Form should be valid with correct input")
        XCTAssertTrue(authViewModel.isEmailValid, "Email should be valid")
        XCTAssertTrue(authViewModel.isPasswordValid, "Password should be valid")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message persists until next submission attempt")
    }
    
    func testResetClearsErrorState() {
        // Given: Error state
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
        authViewModel.signUpWithEmail() // This sets an error
        XCTAssertNotNil(authViewModel.errorMessage)
        
        // When: Reset is called
        authViewModel.reset()
        
        // Then: Error should be cleared
        XCTAssertNil(authViewModel.errorMessage, "Error message should be cleared on reset")
        XCTAssertEqual(authViewModel.email, "", "Email should be cleared on reset")
        XCTAssertEqual(authViewModel.password, "", "Password should be cleared on reset")
    }
    
    func testErrorMessageClearedOnSuccessfulSubmission() {
        // Given: Error state
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
        authViewModel.signUpWithEmail() // This sets an error
        XCTAssertNotNil(authViewModel.errorMessage, "Error should be set initially")
        
        // When: Valid credentials are provided and sign up is attempted
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
        authViewModel.signUpWithEmail()
        
        // Then: Error message should be cleared (since validation passes)
        XCTAssertNil(authViewModel.errorMessage, "Error message should be cleared when validation passes")
        XCTAssertTrue(authViewModel.isLoading, "Should start loading when validation passes")
    }
} 