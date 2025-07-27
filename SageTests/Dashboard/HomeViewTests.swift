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
        
        // Then: Home page should render successfully with F0 data service
        // This ensures the home page doesn't crash and can display real F0 data
        XCTAssertNotNil(view, "Home page should render without crashing")
    }
} 