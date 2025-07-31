import Foundation

/// Simple validator for UserProfile creation and validation
public struct UserProfileValidator {
    
    // MARK: - Profile Creation
    
    /// Creates a minimal user profile for onboarding
    public static func createMinimalProfile(
        userId: String,
        deviceModel: String,
        osVersion: String,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> UserProfile {
        do {
            return try UserProfile.createMinimal(
                userId: userId,
                deviceModel: deviceModel,
                osVersion: osVersion
            )
        } catch {
            fatalError("Failed to create minimal profile: \(error)")
        }
    }
    
    /// Creates complete profile from form data with validation
    public static func createCompleteProfile(
        from data: UserProfileData,
        userId: String,     
        deviceModel: String,
        osVersion: String,
        dateProvider: DateProvider = SystemDateProvider() 
    ) throws -> UserProfile {
        return try UserProfile(
            id: userId,
            age: data.age,
            genderIdentity: data.genderIdentity,
            sexAssignedAtBirth: data.sexAssignedAtBirth,
            voiceConditions: data.voiceConditions,
            diagnosedConditions: data.diagnosedConditions,
            suspectedConditions: [],
            deviceModel: deviceModel,
            osVersion: osVersion
        )
    }
    
    // MARK: - Validation
    
    /// Validates user profile data - throws ValidationError on first failure
    public static func validateProfileData(_ data: UserProfileData) throws {
        // Age validation
        if data.age <= 0 {
            throw ValidationError.ageRequired()
        } else if data.age < 13 || data.age > 120 {
            throw ValidationError.ageInvalid()
        }
        
        // Voice conditions validation
        if data.voiceConditions.isEmpty {
            throw ValidationError.ageRequired(fieldName: "voiceConditions")
        }
        
        // Diagnosed conditions validation
        if data.diagnosedConditions.isEmpty {
            throw ValidationError.ageRequired(fieldName: "diagnosedConditions")
        }
    }
    
    /// Validates user profile data - returns all errors at once
    public static func validate(_ data: UserProfileData) -> UserProfileValidationResult {
        var errors: [ValidationError] = []
        
        // Age validation
        if data.age <= 0 {
            errors.append(.ageRequired())
        } else if data.age < 13 || data.age > 120 {
            errors.append(.ageInvalid())
        }
        
        // Voice conditions validation
        if data.voiceConditions.isEmpty {
            errors.append(.ageRequired(fieldName: "voiceConditions"))
        }
        
        // Diagnosed conditions validation
        if data.diagnosedConditions.isEmpty {
            errors.append(.ageRequired(fieldName: "diagnosedConditions"))
        }
        
        return UserProfileValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    

}

// UserProfileValidationResult is now defined in OnboardingTypes.swift 