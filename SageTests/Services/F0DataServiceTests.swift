import XCTest
import FirebaseFirestore
@testable import Sage

/// MVP Tests for F0DataService
/// - Focuses on crash prevention, numeric parsing, and user-visible formatting
@MainActor
final class F0DataServiceTests: XCTestCase {
    
    var f0DataService: F0DataService!
    
    override func setUp() {
        super.setUp()
        f0DataService = F0DataService()
    }
    
    override func tearDown() {
        f0DataService = nil
        super.tearDown()
    }
    
    // MARK: - Test Numeric Conversion (Crash Prevention)
    
    func testF0ConfidenceRemainsDouble() async {
        // Given: F0 data with confidence as Double
        let testData: [String: Any] = [
            "f0_mean": 220.5,
            "f0_confidence": 95.7,  // Double value
            "status": "completed"
        ]
        
        // When: Processing F0 data
        f0DataService.processF0Data(documentID: "test_doc", data: testData)
        
        // Then: Confidence should remain as Double, not converted to Int
        if case .success(_, let confidence) = f0DataService.state {
            XCTAssertEqual(confidence, 95.7, accuracy: 0.01)
            XCTAssertTrue(type(of: confidence) == Double.self)
        } else {
            XCTFail("Expected success state")
        }
    }
    
    // MARK: - Test User-Visible Formatting
    
    func testF0DisplayFormatMatchesBackendRounding() async {
        // Given: F0 data with decimal precision
        let testData: [String: Any] = [
            "f0_mean": 220.567,  // Should round to 220.6
            "f0_confidence": 95.0,
            "status": "completed"
        ]
        
        // When: Processing F0 data
        f0DataService.processF0Data(documentID: "test_doc", data: testData)
        
        // Then: Display should show 1 decimal place to match backend rounding
        if case .success(let value, _) = f0DataService.state {
            XCTAssertEqual(value, "220.6 Hz")
        } else {
            XCTFail("Expected success state")
        }
    }
    
    // MARK: - Test Error Handling (Crash Prevention)
    
    func testErrorMessageNotResetOnFailedParsing() async {
        // Given: Service with existing error state
        f0DataService.state = .error("Previous error")
        
        // Given: Invalid F0 data
        let testData: [String: Any] = [
            "f0_mean": "invalid",  // Wrong type
            "f0_confidence": 95.0,
            "status": "completed"
        ]
        
        // When: Processing F0 data fails
        f0DataService.processF0Data(documentID: "test_doc", data: testData)
        
        // Then: Should have new error message
        if case .error(let message) = f0DataService.state {
            XCTAssertEqual(message, "Invalid F0 data format")
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testF0ValueOutOfRange() async {
        // Given: F0 data with value outside valid range
        let testData: [String: Any] = [
            "f0_mean": 35.0,  // Below minimum of 75 Hz
            "f0_confidence": 95.0,
            "status": "completed"
        ]
        
        // When: Processing F0 data
        f0DataService.processF0Data(documentID: "out_of_range", data: testData)
        
        // Then: Should be in error state with appropriate message
        if case .error(let message) = f0DataService.state {
            XCTAssertEqual(message, "F0 value outside valid range (75-500 Hz)")
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - Test Edge Cases (Crash Prevention)
    
    func testMissingConfidenceHandling() async {
        // Given: F0 data without confidence
        let testData: [String: Any] = [
            "f0_mean": 220.5,
            "status": "completed"
        ]
        
        // When: Processing F0 data
        f0DataService.processF0Data(documentID: "test_doc", data: testData)
        
        // Then: Confidence should default to 0.0
        if case .success(let value, let confidence) = f0DataService.state {
            XCTAssertEqual(confidence, 0.0)
            XCTAssertEqual(value, "220.5 Hz")
        } else {
            XCTFail("Expected success state")
        }
    }
    
    func testInvalidConfidenceType() async {
        // Given: F0 data with invalid confidence type
        let testData: [String: Any] = [
            "f0_mean": 220.5,
            "f0_confidence": "invalid",  // String instead of Double
            "status": "completed"
        ]
        
        // When: Processing F0 data
        f0DataService.processF0Data(documentID: "test_doc", data: testData)
        
        // Then: Confidence should default to 0.0
        if case .success(let value, let confidence) = f0DataService.state {
            XCTAssertEqual(confidence, 0.0)
            XCTAssertEqual(value, "220.5 Hz")
        } else {
            XCTFail("Expected success state")
        }
    }
} 