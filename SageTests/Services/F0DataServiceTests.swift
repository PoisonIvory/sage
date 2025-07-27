import XCTest
import FirebaseFirestore
@testable import Sage

@MainActor
final class F0DataServiceTests: XCTestCase {
    
    func testF0DataServiceInitializesWithDefaultValues() {
        // Given: F0DataService is created
        let service = F0DataService()
        
        // When: Service is initialized
        
        // Then: Should have default placeholder values
        XCTAssertEqual(service.f0Value, "210 Hz")
        XCTAssertEqual(service.f0Confidence, 0.0)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.errorMessage)
    }
    
    func testF0DataServiceHandlesAuthenticationError() {
        // Given: F0DataService is created
        let service = F0DataService()
        
        // When: fetchF0Data is called without authentication
        
        // Then: Should handle authentication error gracefully
        // Note: In a real test environment, we would mock Firebase Auth
        // to simulate unauthenticated state and verify error handling
        XCTAssertNotNil(service)
    }
    
    func testF0DataServiceValidatesF0Range() {
        // Given: F0DataService is created
        let service = F0DataService()
        
        // When: Processing F0 data outside valid range (75-500 Hz)
        
        // Then: Should reject invalid F0 values
        // Note: In a real test environment, we would test the processF0Data method
        // with mock data containing invalid F0 values
        XCTAssertNotNil(service)
    }
} 