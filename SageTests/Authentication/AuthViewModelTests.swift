//
//  AuthViewModelTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for AuthViewModel
//  Tests session detection and session creation functionality

import Testing
@testable import Sage

struct AuthViewModelTests {
    
    // MARK: - Session Detection Tests
    
    // MARK: - Test 1: Detect Existing Anonymous Session
    @Test func shouldDetectExistingAnonymousSession() async throws {
        // Given: Existing anonymous session
        MockFirebaseAuth.currentUser = MockUser(uid: "anonymous-123", isAnonymous: true)
        
        // When: AuthViewModel is initialized
        let viewModel = AuthViewModel()
        
        // Then: Should detect and authenticate existing session
        #expect(viewModel.hasExistingAnonymousUser() == true)
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.signUpMethod == "anonymous")
    }
    
    // MARK: - Test 2: Detect Existing Email Session
    @Test func shouldDetectExistingEmailSession() async throws {
        // Given: Existing email session
        MockFirebaseAuth.currentUser = MockUser(uid: "email-123", isAnonymous: false)
        
        // When: AuthViewModel is initialized
        let viewModel = AuthViewModel()
        
        // Then: Should detect and authenticate existing session
        #expect(viewModel.hasExistingEmailUser() == true)
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.signUpMethod == "email")
    }
    
    // MARK: - Test 3: No Existing User Session
    @Test func shouldNotDetectSession_whenNoUser() async throws {
        // Given: No existing session
        MockFirebaseAuth.currentUser = nil
        
        // When: AuthViewModel is initialized
        let viewModel = AuthViewModel()
        
        // Then: Does not detect any existing session
        #expect(viewModel.hasExistingAnonymousUser() == false)
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.signUpMethod == nil)
    }
    
    // MARK: - Session Creation Tests
    
    // MARK: - Test 1: Create Anonymous Session
    @Test func shouldCreateAnonymousSessionSuccessfully() async throws {
        // Given: No existing session and Firebase will succeed
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = true
        
        // When: User selects anonymous sign in method
        let viewModel = AuthViewModel()
        viewModel.signInAnonymously()
        
        // Then: Should create and authenticate new session
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.signUpMethod == "anonymous")
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Test 2: Create Email Session
    @Test func shouldCreateEmailSessionSuccessfully() async throws {
        // Given: Valid email and password
        let viewModel = AuthViewModel()
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email sign up method
        viewModel.signUpWithEmail()
        
        // Then: Create and authenticate new session
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.signUpMethod == "email")
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Test 3: Login with Email Method
    @Test func shouldLoginWithEmailSuccessfully() async throws {
        // Given: Valid email and password
        let viewModel = AuthViewModel()
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User logs in with email
        viewModel.loginWithEmail()
        
        // Then: Should be authenticated
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.errorMessage == nil)
    }

    
    // MARK: - Validation Tests
    // (Removed: format-only validation tests, as Firebase handles this)
} 