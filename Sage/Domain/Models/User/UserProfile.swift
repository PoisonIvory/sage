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
    
    /// Formats a date using the shared ISO8601 formatter
    public static func formatDate(_ date: Date) -> String {
        return DateFormatting.formatDate(date)
    }
    
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
            self.createdAt = Self.formatDate(Date())
        }
    }
    
    // MARK: - Voice Analysis Properties
    
    /// Demographic category for voice analysis
    public var voiceDemographic: VoiceDemographic {
        return Self.demographicCategory(for: age, genderIdentity: genderIdentity)
    }
}

// MARK: - Custom Codable Implementation

extension UserProfile {
    /// Custom encoding to optimize for backend compatibility
    /// - Omits empty suspectedConditions array to reduce payload size
    /// - Maintains all validation during encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(age, forKey: .age)
        try container.encode(genderIdentity, forKey: .genderIdentity)
        try container.encode(sexAssignedAtBirth, forKey: .sexAssignedAtBirth)
        try container.encode(voiceConditions, forKey: .voiceConditions)
        try container.encode(diagnosedConditions, forKey: .diagnosedConditions)
        
        // Only encode suspectedConditions if not empty
        if !suspectedConditions.isEmpty {
            try container.encode(suspectedConditions, forKey: .suspectedConditions)
        }
        
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    /// Custom decoding to handle optional suspectedConditions
    /// - Provides empty array as default for missing suspectedConditions
    /// - Maintains all validation during decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(String.self, forKey: .id)
        let age = try container.decode(Age.self, forKey: .age)
        let genderIdentity = try container.decode(GenderIdentity.self, forKey: .genderIdentity)
        let sexAssignedAtBirth = try container.decode(SexAssignedAtBirth.self, forKey: .sexAssignedAtBirth)
        let voiceConditions = try container.decode([String].self, forKey: .voiceConditions)
        let diagnosedConditions = try container.decode([String].self, forKey: .diagnosedConditions)
        
        // Decode suspectedConditions with empty array as default
        let suspectedConditions = try container.decodeIfPresent([String].self, forKey: .suspectedConditions) ?? []
        
        let deviceModel = try container.decode(String.self, forKey: .deviceModel)
        let osVersion = try container.decode(String.self, forKey: .osVersion)
        let createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Validate required conditions are not empty
        guard !voiceConditions.isEmpty else {
            throw UserProfileError.invalidVoiceConditions("At least one voice condition must be selected")
        }
        
        guard !diagnosedConditions.isEmpty else {
            throw UserProfileError.invalidMedicalConditions("At least one diagnosed condition must be selected")
        }
        
        self.id = id
        self.age = age
        self.genderIdentity = genderIdentity
        self.sexAssignedAtBirth = sexAssignedAtBirth
        self.voiceConditions = voiceConditions
        self.diagnosedConditions = diagnosedConditions
        self.suspectedConditions = suspectedConditions
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.createdAt = createdAt
    }
    
    /// Coding keys for custom Codable implementation
    private enum CodingKeys: String, CodingKey {
        case id, age, genderIdentity, sexAssignedAtBirth, voiceConditions, diagnosedConditions, suspectedConditions, deviceModel, osVersion, createdAt
    }
}

// MARK: - Demographic Mapping Extension

extension UserProfile {
    /// Maps age and gender identity to voice demographic category
    /// - Parameter age: User's age (validated Age value object)
    /// - Parameter genderIdentity: User's gender identity
    /// - Returns: Appropriate VoiceDemographic category for voice analysis
    public static func demographicCategory(for age: Age, genderIdentity: GenderIdentity) -> VoiceDemographic {
        return demographicCategory(for: age.value, genderIdentity: genderIdentity)
    }
    
    /// Maps age and gender identity to voice demographic category
    /// - Parameter age: User's age value (Int)
    /// - Parameter genderIdentity: User's gender identity
    /// - Returns: Appropriate VoiceDemographic category for voice analysis
    public static func demographicCategory(for age: Int, genderIdentity: GenderIdentity) -> VoiceDemographic {
        switch (age, genderIdentity) {
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