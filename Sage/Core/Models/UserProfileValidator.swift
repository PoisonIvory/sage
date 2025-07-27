import Foundation

/// Validates and creates user profiles with proper data
/// - Prevents creation of profiles with invalid/incomplete data
/// - Provides validation logic for user profile data
/// - Ensures data integrity before profile creation
struct UserProfileValidator {
    
    /// Validates user profile data for completeness
    /// - Parameter data: User profile data to validate
    /// - Returns: Validation result with errors if any
    static func validate(_ data: UserProfileData) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Age validation
        if data.age <= 0 {
            errors.append(.ageRequired())
        } else if data.age < 13 || data.age > 120 {
            errors.append(.ageInvalid())
        }
        
        // Gender validation (optional but if provided, should be valid)
        if !data.gender.isEmpty {
            let validGenders = ["male", "female", "other", "prefer not to say"]
            if !validGenders.contains(data.gender.lowercased()) {
                errors.append(.genderInvalid())
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Creates a minimal user profile for onboarding
    /// - Parameters:
    ///   - userId: User identifier
    ///   - deviceModel: Device model string
    ///   - osVersion: Operating system version
    ///   - dateProvider: Date provider for consistent testing
    /// - Returns: UserProfile with minimal valid data
    static func createMinimalProfile(
        userId: String,
        deviceModel: String,
        osVersion: String,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> UserProfile {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return UserProfile(
            id: userId,
            age: 0, // Will be updated when user provides age
            gender: "", // Will be updated when user provides gender
            deviceModel: deviceModel,
            osVersion: osVersion,
            createdAt: formatter.string(from: dateProvider.currentDate)
        )
    }
    
    /// Creates a complete user profile from validated data
    /// - Parameters:
    ///   - data: Validated user profile data
    ///   - userId: User identifier
    ///   - deviceModel: Device model string
    ///   - osVersion: Operating system version
    ///   - dateProvider: Date provider for consistent testing
    /// - Returns: Complete UserProfile
    /// - Throws: ValidationError if data is invalid
    static func createCompleteProfile(
        from data: UserProfileData,
        userId: String,
        deviceModel: String,
        osVersion: String,
        dateProvider: DateProvider = SystemDateProvider()
    ) throws -> UserProfile {
        let validation = validate(data)
        
        guard validation.isValid else {
            throw validation.errors.first ?? ValidationError.ageRequired()
        }
        
        return data.toUserProfile(
            id: userId,
            deviceModel: deviceModel,
            osVersion: osVersion,
            dateProvider: dateProvider
        )
    }
}

/// Result of user profile validation
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
} 