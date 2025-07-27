//
//  AuthViewModelTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for AuthViewModel
//  Tests individual methods and properties

import XCTest
@testable import Sage

@MainActor
class AuthViewModelTests: XCTestCase {
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
    
    func testInitialState() {
        // Given: AuthViewModel is created
        // When: Initial state is checked
        // Then: Should have default values
        XCTAssertEqual(authViewModel.email, "")
        XCTAssertEqual(authViewModel.password, "")
        XCTAssertFalse(authViewModel.isLoading)
        XCTAssertNil(authViewModel.errorMessage)
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.signUpMethod)
        XCTAssertFalse(authViewModel.shouldShowRetryOption)
        XCTAssertFalse(authViewModel.canWorkOffline)
    }
    

    
    func testResetFunctionality() {
        // Given: AuthViewModel with some data
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
        authViewModel.isAuthenticated = true
        authViewModel.signUpMethod = "email"
        authViewModel.errorMessage = "Some error"
        authViewModel.isLoading = true
        authViewModel.shouldShowRetryOption = true
        authViewModel.canWorkOffline = true
        
        // When: Reset is called
        authViewModel.reset()
        
        // Then: Should return to initial state
        XCTAssertEqual(authViewModel.email, "")
        XCTAssertEqual(authViewModel.password, "")
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.signUpMethod)
        XCTAssertNil(authViewModel.errorMessage)
        XCTAssertFalse(authViewModel.isLoading)
        XCTAssertFalse(authViewModel.shouldShowRetryOption)
        XCTAssertFalse(authViewModel.canWorkOffline)
    }
    
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
        setInvalidCredentials()
        
        // When: Sign up is attempted with invalid credentials
        authViewModel.signUpWithEmail()
        
        // Then: Should not set loading state due to validation failure
        XCTAssertFalse(authViewModel.isLoading, "Loading should not start when validation fails")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be shown for invalid credentials")
    }
} 