import XCTest
@testable import Sage

/// Tests for DateFormatting utility
/// - Tests ISO8601 date formatting and parsing functionality
/// - Follows GWT structure for clear test organization
final class DateFormattingTests: XCTestCase {
    
    // MARK: - Date Formatting Tests
    
    func testFormatDate() {
        // Given: A specific date for consistent testing
        let date = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        
        // When: Date is formatted using DateFormatting utility
        let formattedDate = DateFormatting.formatDate(date)
        
        // Then: Should return ISO8601 formatted string
        XCTAssertTrue(formattedDate.contains("2022-01-01"))
        XCTAssertTrue(formattedDate.contains("T"))
        XCTAssertTrue(formattedDate.contains("Z") || formattedDate.contains("+"))
    }
    
    func testFormatCurrentDate() {
        // Given: Current date is requested
        let beforeFormat = Date()
        
        // When: Current date is formatted
        let formattedDate = DateFormatting.formatCurrentDate()
        
        // Then: Should return valid ISO8601 string
        XCTAssertTrue(formattedDate.contains("T"))
        XCTAssertTrue(formattedDate.contains("Z") || formattedDate.contains("+"))
        
        // And: Should be close to current time
        let afterFormat = Date()
        let parsedDate = DateFormatting.parseDate(formattedDate)
        XCTAssertNotNil(parsedDate)
        
        if let parsed = parsedDate {
            XCTAssertGreaterThanOrEqual(parsed, beforeFormat)
            XCTAssertLessThanOrEqual(parsed, afterFormat)
        }
    }
    
    // MARK: - Date Parsing Tests
    
    func testParseDate() {
        // Given: A valid ISO8601 formatted string
        let dateString = "2022-01-01T00:00:00.000Z"
        
        // When: String is parsed using DateFormatting utility
        let parsedDate = DateFormatting.parseDate(dateString)
        
        // Then: Should return valid Date object
        XCTAssertNotNil(parsedDate)
        
        if let date = parsedDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2022)
            XCTAssertEqual(components.month, 1)
            XCTAssertEqual(components.day, 1)
        }
    }
    
    func testParseDateWithInvalidString() {
        // Given: An invalid date string
        let invalidDateString = "invalid-date-string"
        
        // When: Invalid string is parsed
        let parsedDate = DateFormatting.parseDate(invalidDateString)
        
        // Then: Should return nil
        XCTAssertNil(parsedDate)
    }
    
    func testParseDateWithEmptyString() {
        // Given: An empty string
        let emptyString = ""
        
        // When: Empty string is parsed
        let parsedDate = DateFormatting.parseDate(emptyString)
        
        // Then: Should return nil
        XCTAssertNil(parsedDate)
    }
    
    // MARK: - Round Trip Tests
    
    func testFormatAndParseRoundTrip() {
        // Given: A specific date
        let originalDate = Date(timeIntervalSince1970: 1640995200)
        
        // When: Date is formatted and then parsed back
        let formattedString = DateFormatting.formatDate(originalDate)
        let parsedDate = DateFormatting.parseDate(formattedString)
        
        // Then: Should return the same date (within reasonable precision)
        XCTAssertNotNil(parsedDate)
        
        if let parsed = parsedDate {
            let timeDifference = abs(originalDate.timeIntervalSince1970 - parsed.timeIntervalSince1970)
            XCTAssertLessThan(timeDifference, 1.0) // Within 1 second
        }
    }
    
    // MARK: - Formatter Configuration Tests
    
    func testFormatterHasCorrectConfiguration() {
        // Given: The shared ISO formatter
        let formatter = DateFormatting.isoFormatter
        
        // When: Formatter configuration is checked
        let hasInternetDateTime = formatter.formatOptions.contains(.withInternetDateTime)
        let hasFractionalSeconds = formatter.formatOptions.contains(.withFractionalSeconds)
        
        // Then: Should have correct format options
        XCTAssertTrue(hasInternetDateTime)
        XCTAssertTrue(hasFractionalSeconds)
    }
} 