//
//  AuthFlowTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Integration tests for authentication flow
//  Tests async loading states and authentication success/failure

import XCTest
@testable import Sage

class AuthFlowTests: XCTestCase {
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
    
    // MARK: - Initialization Tests
    func testAuthViewModelInitialization() {
        // Given: AuthViewModel is created
        // When: Initial state is checked
        // Then: Should have default values
        XCTAssertFalse(authViewModel.isAuthenticated, "Should start unauthenticated")
        XCTAssertNil(authViewModel.signUpMethod, "Should have no sign up method initially")
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(authViewModel.errorMessage, "Should have no error message initially")
    }
    
    // MARK: - Loading State Tests
    func testLoadingStateTransitions() {
        // Given: Valid credentials
        setValidCredentials()
        
        // When: Sign up is initiated
        authViewModel.signUpWithEmail()
        
        // Then: Should set loading state initially
        XCTAssertTrue(authViewModel.isLoading, "Loading should be true when sign up starts")
        
        // And: Should return to false after async completion
        let expectation = self.expectation(description: "Wait for sign up completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(self.authViewModel.isLoading, "Loading should be false after sign up completes")
            XCTAssertTrue(self.authViewModel.isAuthenticated, "Should be authenticated after successful sign up")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testLoadingStateNotSetWithInvalidCredentials() {
        // Given: Invalid credentials
        authViewModel.email = "invalid-email"
        authViewModel.password = "123"
        
        // When: Sign up is attempted with invalid credentials
        authViewModel.signUpWithEmail()
        
        // Then: Should not set loading state due to validation failure
        XCTAssertFalse(authViewModel.isLoading, "Loading should not start when validation fails")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid credentials")
    }
    
    // MARK: - Reset Functionality
    func testResetFunctionality() {
        // Given: AuthViewModel with some data
        setValidCredentials()
        authViewModel.isAuthenticated = true
        authViewModel.signUpMethod = "email"
        authViewModel.errorMessage = "Some error"
        authViewModel.isLoading = true
        
        // When: Reset is called
        authViewModel.reset()
        
        // Then: Should return to initial state
        XCTAssertEqual(authViewModel.email, "", "Email should be cleared on reset")
        XCTAssertEqual(authViewModel.password, "", "Password should be cleared on reset")
        XCTAssertFalse(authViewModel.isAuthenticated, "Should be unauthenticated after reset")
        XCTAssertNil(authViewModel.signUpMethod, "Sign up method should be cleared on reset")
        XCTAssertNil(authViewModel.errorMessage, "Error message should be cleared on reset")
        XCTAssertFalse(authViewModel.isLoading, "Loading should be false after reset")
    }
} 