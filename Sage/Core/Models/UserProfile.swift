// UserProfile.swift
// Implements user profile data model per DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3
// All fields must be defined in DATA_DICTIONARY.md and comply with scientific/data standards.
import Foundation

/// UserProfile represents a de-identified user profile for Sage, compliant with DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3.
struct UserProfile: Codable, Identifiable {
    /// Anonymized unique user identifier (DATA_DICTIONARY.md: user_id)
    let id: String
    /// Age in years (DATA_DICTIONARY.md: age)
    let age: Int
    /// Gender (self-described) (DATA_DICTIONARY.md: gender)
    let gender: String
    /// Device model used for recording (DATA_DICTIONARY.md: device_model)
    let deviceModel: String
    /// OS version (DATA_DICTIONARY.md: os_version)
    let osVersion: String
    /// Date of profile creation (ISO 8601, UTC)
    let createdAt: String
    // Add additional fields as required by DATA_DICTIONARY.md
    // e.g., pertinent health conditions, cycle_phase, etc.
    // let healthConditions: [String]?
    // let cyclePhase: String?
    // let symptomMood: Int?
    // ...
} 