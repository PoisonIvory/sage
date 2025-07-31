import Foundation

// MARK: - Domain Errors

/// Errors that can occur when creating domain value objects
public enum DomainValueError: LocalizedError, Equatable {
    case ageInvalid(Int)
    case deviceModelEmpty
    case deviceModelTooLong(Int)
    case osVersionEmpty
    case osVersionInvalid(String)
    
    public var errorDescription: String? {
        switch self {
        case .ageInvalid(let age):
            return "Age \(age) is invalid. Must be between 13 and 120."
        case .deviceModelEmpty:
            return "Device model cannot be empty."
        case .deviceModelTooLong(let length):
            return "Device model is too long (\(length) characters). Maximum is 100."
        case .osVersionEmpty:
            return "OS version cannot be empty."
        case .osVersionInvalid(let version):
            return "OS version '\(version)' is invalid."
        }
    }
}

// MARK: - Age Value Object (moved to OnboardingTypes.swift)
// Age is now defined in OnboardingTypes.swift to avoid duplication

// MARK: - DeviceModel Value Object

/// Represents a device model with validation
/// - Ensures device model is not empty and within reasonable length
/// - Provides type safety for device identification
public struct DeviceModel: Codable, Equatable, Hashable {
    public let value: String
    
    /// Creates a DeviceModel value object
    /// - Parameter value: The device model string to validate
    /// - Throws: DomainValueError if device model is invalid
    public init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw DomainValueError.deviceModelEmpty
        }
        
        guard trimmed.count <= 100 else {
            throw DomainValueError.deviceModelTooLong(trimmed.count)
        }
        
        self.value = trimmed
    }
    
    /// Creates a DeviceModel from a string, returning nil if invalid
    /// - Parameter value: The device model string to validate
    /// - Returns: DeviceModel instance or nil if invalid
    public static func from(_ value: String) -> DeviceModel? {
        try? DeviceModel(value)
    }
    
    /// Returns true if this is an iPhone device
    public var isIPhone: Bool {
        value.lowercased().contains("iphone")
    }
    
    /// Returns true if this is an iPad device
    public var isIPad: Bool {
        value.lowercased().contains("ipad")
    }
    
    /// Returns true if this is a Mac device
    public var isMac: Bool {
        value.lowercased().contains("mac")
    }
    
    /// Returns the device family for analytics
    public var deviceFamily: String {
        if isIPhone { return "iPhone" }
        if isIPad { return "iPad" }
        if isMac { return "Mac" }
        return "Unknown"
    }
}

// MARK: - OSVersion Value Object

/// Represents an operating system version with validation
/// - Ensures OS version follows expected format
/// - Provides type safety for OS version tracking
public struct OSVersion: Codable, Equatable, Hashable {
    public let value: String
    
    /// Creates an OSVersion value object
    /// - Parameter value: The OS version string to validate
    /// - Throws: DomainValueError if OS version is invalid
    public init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw DomainValueError.osVersionEmpty
        }
        
        // Basic validation for iOS version format (e.g., "17.0", "17.0.1")
        let versionPattern = #"^\d+(\.\d+)*$"#
        let regex = try NSRegularExpression(pattern: versionPattern)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        guard regex.firstMatch(in: trimmed, options: [], range: range) != nil else {
            throw DomainValueError.osVersionInvalid(trimmed)
        }
        
        self.value = trimmed
    }
    
    /// Creates an OSVersion from a string, returning nil if invalid
    /// - Parameter value: The OS version string to validate
    /// - Returns: OSVersion instance or nil if invalid
    public static func from(_ value: String) -> OSVersion? {
        try? OSVersion(value)
    }
    
    /// Returns the major version number
    public var majorVersion: Int? {
        value.components(separatedBy: ".").first.flatMap(Int.init)
    }
    
    /// Returns true if this is iOS 17 or later
    public var isModernIOS: Bool {
        guard let major = majorVersion else { return false }
        return major >= 17
    }
    
    /// Returns the version components as an array of integers
    public var components: [Int] {
        value.components(separatedBy: ".").compactMap(Int.init)
    }
}

// MARK: - CreatedAt Value Object

/// Represents a creation timestamp with domain meaning
/// - Provides type safety for temporal data
/// - Includes domain-specific queries for age calculations
public struct CreatedAt: Codable, Equatable, Hashable {
    public let value: Date
    
    /// Creates a CreatedAt value object
    /// - Parameter value: The date to wrap
    public init(_ value: Date) {
        self.value = value
    }
    
    /// Creates a CreatedAt for the current moment
    public static func now() -> CreatedAt {
        CreatedAt(Date())
    }
    
    /// Returns the age of this timestamp in days
    public var ageInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: value, to: Date())
        return components.day ?? 0
    }
    
    /// Returns the age of this timestamp in months
    public var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: value, to: Date())
        return components.month ?? 0
    }
    
    /// Returns true if this timestamp is within the last 24 hours
    public var isRecent: Bool {
        Date().timeIntervalSince(value) < 24 * 60 * 60
    }
    
    /// Returns true if this timestamp is older than 30 days
    public var isStale: Bool {
        ageInDays > 30
    }
    
    /// Returns a formatted string for display
    public var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }
}

// MARK: - Extensions for Convenience

// Age extension is in OnboardingTypes.swift

extension DeviceModel: CustomStringConvertible {
    public var description: String {
        value
    }
}

extension OSVersion: CustomStringConvertible {
    public var description: String {
        "iOS \(value)"
    }
}

extension CreatedAt: CustomStringConvertible {
    public var description: String {
        displayString
    }
}