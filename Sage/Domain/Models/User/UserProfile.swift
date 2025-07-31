// UserProfile.swift
// User profile data model matching User_Metadata_Schema.csv requirements
// Simple, focused implementation without over-engineering

import Foundation

/// UserProfile represents a user profile for Sage voice analysis
/// Uses value objects for domain safety and intent expression
public struct UserProfile: Codable, Identifiable, Equatable {
    
    // MARK: - Core Properties
    
    /// Anonymized unique user identifier
    public let id: String
    
    /// User's age (13-120) - validated by Age value object
    public let age: Age
    
    /// User's gender identity
    public let genderIdentity: GenderIdentity
    
    /// User's sex assigned at birth for hormonal context
    public let sexAssignedAtBirth: SexAssignedAtBirth
    
    /// Voice conditions that may impact analysis
    public let voiceConditions: [String]
    
    /// Diagnosed medical conditions
    public let diagnosedConditions: [String]
    
    /// Suspected medical conditions (optional)
    public let suspectedConditions: [String]
    
    /// Device information
    public let deviceModel: String
    public let osVersion: String
    
    /// Profile creation timestamp (ISO 8601)
    public let createdAt: String
    
    // MARK: - Static Formatter
    
    /// Shared ISO8601 formatter for consistent date formatting
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - Initialization
    
    public init(
        id: String,
        age: Int,
        genderIdentity: GenderIdentity,
        sexAssignedAtBirth: SexAssignedAtBirth,     
        voiceConditions: [String],
        diagnosedConditions: [String],
        suspectedConditions: [String] = [],
        deviceModel: String,
        osVersion: String,
        createdAt: String? = nil
    ) throws {
        // Validate age using the Age value object from OnboardingTypes
        let validatedAge = try Age(age)
        
        // Validate required conditions are not empty
        guard !voiceConditions.isEmpty else {
            throw UserProfileError.invalidVoiceConditions("At least one voice condition must be selected")
        }
        
        guard !diagnosedConditions.isEmpty else {
            throw UserProfileError.invalidMedicalConditions("At least one diagnosed condition must be selected")
        }
        
        self.id = id
        self.age = validatedAge
        self.genderIdentity = genderIdentity
        self.sexAssignedAtBirth = sexAssignedAtBirth
        self.voiceConditions = voiceConditions
        self.diagnosedConditions = diagnosedConditions
        self.suspectedConditions = suspectedConditions
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        
        if let createdAt = createdAt {
            self.createdAt = createdAt
        } else {
            self.createdAt = Self.isoFormatter.string(from: Date())
        }
    }
    
    // MARK: - Voice Analysis Properties
    
    /// Demographic category for voice analysis
    public var voiceDemographic: VoiceDemographic {
        switch (age.value, genderIdentity) {
        case (13...17, _):
            return .adolescent
        case (18...64, .woman):
            return .adultFemale
        case (18...64, .man):
            return .adultMale
        case (18...64, _):
            return .adultOther
        case (65..., .woman):
            return .seniorFemale
        case (65..., .man):
            return .seniorMale
        case (65..., _):
            return .seniorOther
        default:
            return .adultOther
        }
    }
}

// MARK: - Simple Enums

/// Gender Identity options from schema
public enum GenderIdentity: String, CaseIterable, Codable {
    case woman = "Woman"
    case man = "Man" 
    case nonbinary = "Nonbinary"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}

/// Sex Assigned at Birth options from schema  
public enum SexAssignedAtBirth: String, CaseIterable, Codable {
    case female = "Female"
    case male = "Male"
    case intersex = "Intersex"
    case preferNotToSay = "Prefer not to say"
}

// MARK: - Validation Helpers

/// Creates minimal profile for onboarding
/// Used for temporary or transitional state during user registration
extension UserProfile {
    public static func createMinimal(
        userId: String,
        deviceModel: String,
        osVersion: String
    ) throws -> UserProfile {
        return try UserProfile(
            id: userId,
            age: 25, // Default age (will be validated by Age value object)
            genderIdentity: .preferNotToSay,
            sexAssignedAtBirth: .preferNotToSay,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            deviceModel: deviceModel,
            osVersion: osVersion
        )
    }
}

// MARK: - Errors

public enum UserProfileError: Error, LocalizedError {
    case invalidAge(String)
    case invalidVoiceConditions(String)
    case invalidMedicalConditions(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAge(let message):
            return "Invalid age: \(message)"
        case .invalidVoiceConditions(let message):
            return "Invalid voice conditions: \(message)"
        case .invalidMedicalConditions(let message):
            return "Invalid medical conditions: \(message)"
        }
    }
} 