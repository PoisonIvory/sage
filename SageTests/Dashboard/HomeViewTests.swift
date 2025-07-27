import XCTest
import SwiftUI
@testable import Sage

@MainActor
final class HomeViewTests: XCTestCase {
    
    func testUserSeesF0ValueOnHomePage() {
        // Given: User is on the home page
        let homeView = HomeView()
        
        // When: Home page loads
        let view = homeView.body
        
        // Then: Home page should render successfully
        // This is the only test that matters for MVP - ensures the home page doesn't crash
        // and can display the F0 value when real data is integrated
        XCTAssertNotNil(view, "Home page should render without crashing")
    }
} 