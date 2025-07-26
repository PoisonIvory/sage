//
//  AuthFlowTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Integration tests for authentication flow
//  Tests how components work together

import Testing
@testable import Sage

struct AuthFlowTests {
    
    @Test func shouldNavigateToHome_whenUserIsAuthenticated() async throws {
        // Given: User is already authenticated
        MockFirebaseAuth.currentUser = MockUser(uid: "anonymous-123", isAnonymous: true)
        
        // When: App starts and checks authentication
        let authViewModel = AuthViewModel()
        
        // Then: App should determine user should go to home
        #expect(authViewModel.isAuthenticated == true)
        // Note: Actual navigation would be tested in UI tests
    }
    
    @Test func shouldAuthenticateNewUser_whenAnonymousSignup() async throws {
        // Given: New user with no recordings
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = true
        
        // When: User signs in for the first time
        let authViewModel = AuthViewModel()
        authViewModel.signInAnonymously()
        
        // Then: Should authenticate successfully
        #expect(authViewModel.isAuthenticated == true)
        #expect(authViewModel.signUpMethod == "anonymous")
    }
    
    @Test func shouldAuthenticateReturningUser_whenSessionExists() async throws {
        // Given: Returning user with existing recordings
        MockFirebaseAuth.currentUser = MockUser(uid: "returning-123", isAnonymous: true)
        
        // When: App starts and checks authentication
        let authViewModel = AuthViewModel()
        
        // Then: Should authenticate existing session
        #expect(authViewModel.isAuthenticated == true)
        #expect(authViewModel.signUpMethod == "anonymous")
    }
    
    @Test func shouldHandleTransitionFromAnonymousToEmail() async throws {
        // Given: User was previously anonymous
        MockFirebaseAuth.currentUser = MockUser(uid: "anonymous-123", isAnonymous: true)
        
        // When: User signs in with email
        let authViewModel = AuthViewModel()
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
        authViewModel.loginWithEmail()
        
        // Then: Should transition to email authentication
        #expect(authViewModel.isAuthenticated == true)
        #expect(authViewModel.signUpMethod == "email")
    }
} 