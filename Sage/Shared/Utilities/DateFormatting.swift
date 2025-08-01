import Foundation

/// DateFormatting utility for consistent date formatting across the app
/// - Provides centralized date formatting logic for better testability
/// - Uses ISO8601 format for consistency with backend services
public struct DateFormatting {
    
    /// Shared ISO8601 formatter for consistent date formatting
    /// - Configured with internet datetime and fractional seconds
    /// - Thread-safe singleton for performance
    public static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Formats a date using the shared ISO8601 formatter
    /// - Parameter date: The date to format
    /// - Returns: ISO8601 formatted string
    public static func formatDate(_ date: Date) -> String {
        return isoFormatter.string(from: date)
    }
    
    /// Formats the current date using the shared ISO8601 formatter
    /// - Returns: ISO8601 formatted string of current date
    public static func formatCurrentDate() -> String {
        return formatDate(Date())
    }
    
    /// Parses an ISO8601 formatted string back to a Date
    /// - Parameter dateString: The ISO8601 formatted string
    /// - Returns: Parsed Date or nil if invalid
    public static func parseDate(_ dateString: String) -> Date? {
        return isoFormatter.date(from: dateString)
    }
} 