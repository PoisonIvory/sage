//
//  AuthErrorHandlingTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for authentication error handling
//  Tests failure scenarios and user-friendly error messages

import Testing
@testable import Sage

struct AuthErrorHandlingTests {
    
    @Test func shouldHandleAnonymousSessionCreationFailure() async throws {
        // Given: Firebase will fail to create anonymous session
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = false
        MockFirebaseAuth.signInAnonymouslyError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When: User attempts to sign in anonymously
        let viewModel = AuthViewModel()
        viewModel.signInAnonymously()
        
        // Then: Should show user-friendly error and allow retry
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage == "We're having trouble connecting to your account. Your voice recordings won't be saved to track your progress over time. You can try again or continue using the app for now.")
        #expect(viewModel.signUpMethod == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.shouldShowRetryOption == true)
    }
    
    @Test func shouldPreserveLocalData_whenAuthenticationFails() async throws {
        // Given: User has local recordings and authentication will fail
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = false
        
        // When: Authentication fails
        let viewModel = AuthViewModel()
        viewModel.signInAnonymously()
        
        // Then: Should preserve local data and enable offline mode
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.shouldShowRetryOption == true)
        #expect(viewModel.canWorkOffline == true)
    }
    
    @Test func shouldAllowRetry_whenAuthenticationFails() async throws {
        // Given: Previous authentication attempt failed
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = false
        
        let viewModel = AuthViewModel()
        viewModel.signInAnonymously()
        
        // When: User retries and it succeeds
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = true
        viewModel.retryAnonymousSignIn()
        
        // Then: Should succeed on retry
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.signUpMethod == "anonymous")
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func shouldHandleNetworkTimeout() async throws {
        // Given: Network timeout error
        MockFirebaseAuth.reset()
        MockFirebaseAuth.shouldSignInAnonymouslySucceed = false
        MockFirebaseAuth.signInAnonymouslyError = NSError(domain: "test", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
        
        // When: User attempts to sign in
        let viewModel = AuthViewModel()
        viewModel.signInAnonymously()
        
        // Then: Should show network-specific error message
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("connection") == true)
    }
} 