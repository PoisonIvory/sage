//
//  OnboardingTypesTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for onboarding type definitions
//  Tests SignupMethod, SignupResult, ValidationError, and UserProfileData
//  Following TDD Red-Green-Refactor cycle

import XCTest
@testable import Sage

class OnboardingTypesTests: XCTestCase {
    
    // MARK: - SignupMethod Tests
    func testSignupMethodCases() {
        // Given: All signup method cases
        let methods = SignupMethod.allCases
        
        // Then: Should have exactly 2 methods
        XCTAssertEqual(methods.count, 2)
        XCTAssertTrue(methods.contains(.anonymous))
        XCTAssertTrue(methods.contains(.email))
    }
    
    func testSignupMethodRawValues() {
        // Given: Signup method cases
        // Then: Raw values should match expected strings
        XCTAssertEqual(SignupMethod.anonymous.rawValue, "anonymous")
        XCTAssertEqual(SignupMethod.email.rawValue, "email")
    }
    
    func testSignupMethodCodable() throws {
        // Given: Signup method
        let method = SignupMethod.email
        
        // When: Encoding and decoding
        let data = try JSONEncoder().encode(method)
        let decoded = try JSONDecoder().decode(SignupMethod.self, from: data)
        
        // Then: Should maintain value
        XCTAssertEqual(decoded, method)
    }
    
    // MARK: - SignupResult Tests
    func testSignupResultEquality() {
        // Given: Same signup results
        let result1 = SignupResult.created
        let result2 = SignupResult.created
        
        // Then: Should be equal
        XCTAssertEqual(result1, result2)
        
        // Given: Different signup results
        let result3 = SignupResult.exists
        
        // Then: Should not be equal
        XCTAssertNotEqual(result1, result3)
    }
    
    func testSignupResultErrorEquality() {
        // Given: Error results with same description
        let error1 = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error2 = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let result1 = SignupResult.error(error1)
        let result2 = SignupResult.error(error2)
        
        // Then: Should be equal (based on description)
        XCTAssertEqual(result1, result2)
    }
    
    // MARK: - ValidationError Tests
    func testValidationErrorDescriptions() {
        // Given: Validation errors
        // Then: Should have user-friendly descriptions
        XCTAssertEqual(ValidationError.ageRequired.errorDescription, "Age is required for research purposes")
        XCTAssertEqual(ValidationError.ageInvalid.errorDescription, "Age must be between 13 and 120")
    }
    
    func testValidationErrorEquality() {
        // Given: Same validation errors
        let error1 = ValidationError.ageRequired
        let error2 = ValidationError.ageRequired
        
        // Then: Should be equal
        XCTAssertEqual(error1, error2)
        
        // Given: Different validation errors
        let error3 = ValidationError.ageInvalid
        
        // Then: Should not be equal
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - UserProfileData Tests
    func testUserProfileDataDefaultValues() {
        // Given: Default UserProfileData
        let data = UserProfileData()
        
        // Then: Should have empty default values
        XCTAssertEqual(data.name, "")
        XCTAssertEqual(data.age, 0)
        XCTAssertEqual(data.gender, "")
    }
    
    func testUserProfileDataToUserProfile() {
        // Given: UserProfileData with values
        var data = UserProfileData()
        data.name = "Test User"
        data.age = 25
        data.gender = "Female"
        
        // When: Converting to UserProfile
        let profile = data.toUserProfile(
            id: "test-id",
            deviceModel: "iPhone 15",
            osVersion: "17.0"
        )
        
        // Then: Should create correct UserProfile
        XCTAssertEqual(profile.id, "test-id")
        XCTAssertEqual(profile.age, 25)
        XCTAssertEqual(profile.gender, "Female")
        XCTAssertEqual(profile.deviceModel, "iPhone 15")
        XCTAssertEqual(profile.osVersion, "17.0")
        XCTAssertFalse(profile.createdAt.isEmpty)
        
        // Then: Should use ISO8601 format
        XCTAssertTrue(profile.createdAt.contains("T"))
        XCTAssertTrue(profile.createdAt.contains("Z"))
    }
    
    func testUserProfileDataEquality() {
        // Given: Two UserProfileData instances with same values
        var data1 = UserProfileData()
        data1.name = "Test"
        data1.age = 25
        
        var data2 = UserProfileData()
        data2.name = "Test"
        data2.age = 25
        
        // Then: Should be equal
        XCTAssertEqual(data1, data2)
        
        // Given: Different values
        data2.age = 30
        
        // Then: Should not be equal
        XCTAssertNotEqual(data1, data2)
    }
    

} 