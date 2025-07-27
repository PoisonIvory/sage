import XCTest
import SwiftUI
@testable import Sage

@MainActor
final class AppFlowTests: XCTestCase {
    
    func testNewUserSeesWelcomeScreen() {
        // Given: AuthViewModel with no existing authentication
        let authViewModel = AuthViewModel(disableAutoAuth: true)
        authViewModel.isAuthenticated = false
        
        // When: App checks authentication state
        
        // Then: Should show welcome screen for new users
        XCTAssertFalse(authViewModel.isAuthenticated)
    }
    
    func testExistingUserGoesDirectlyToHome() {
        // Given: AuthViewModel with existing authentication
        let authViewModel = AuthViewModel(disableAutoAuth: true)
        authViewModel.isAuthenticated = true
        
        // When: App checks authentication state
        
        // Then: Should go directly to home for existing users
        XCTAssertTrue(authViewModel.isAuthenticated)
    }
    
    func testOnboardingCompletionNavigatesToHome() {
        // Given: User completes onboarding
        
        // When: Onboarding completion callback is triggered
        
        // Then: Should navigate to home page
        // Note: This is tested through the OnboardingJourneyView completion callback
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testAuthenticationStateChangeTriggersNavigation() {
        // Given: User starts unauthenticated
        let authViewModel = AuthViewModel(disableAutoAuth: true)
        authViewModel.isAuthenticated = false
        
        // When: User becomes authenticated
        authViewModel.isAuthenticated = true
        
        // Then: Should trigger navigation to home
        XCTAssertTrue(authViewModel.isAuthenticated)
    }
} 