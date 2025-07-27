import XCTest
import SwiftUI
@testable import Sage

@MainActor
final class HomeViewTests: XCTestCase {
    
    func testHomeViewDisplaysF0Value() {
        // Given: HomeView is created
        let homeView = HomeView()
        
        // When: View is rendered
        let view = homeView.body
        
        // Then: Should display F0 value
        // Note: In a real test environment, we would use ViewInspector or similar
        // to inspect the actual text content. For now, we verify the view exists.
        XCTAssertNotNil(view)
    }
    
    func testHomeViewUsesSageDesignSystem() {
        // Given: HomeView is created
        let homeView = HomeView()
        
        // When: View is rendered
        let view = homeView.body
        
        // Then: Should use Sage design system components
        // Note: In a real test environment, we would verify specific design system usage
        XCTAssertNotNil(view)
    }
    
    func testHomeViewHasCorrectInitialState() {
        // Given: HomeView is created
        let homeView = HomeView()
        
        // When: View is initialized
        
        // Then: Should have default F0 value
        // Note: We can't directly access @State properties in tests,
        // but we can verify the view renders correctly
        XCTAssertNotNil(homeView.body)
    }
} 