import XCTest
@testable import Sage

/// Tests for UserProfile Codable conformance
/// - Tests encoding and decoding of UserProfile with all value objects
/// - Ensures smooth persistence and backend sync compatibility
/// - Follows GWT structure for clear test organization
final class UserProfileCodableTests: XCTestCase {
    
    // MARK: - UserProfile Codable Tests
    
    func testUserProfileEncodingAndDecoding() {
        // Given: A complete UserProfile with all fields populated
        let userProfile = try! UserProfile(
            id: "test-user-123",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            suspectedConditions: ["PCOS"],
            deviceModel: "iPhone 15",
            osVersion: "17.0",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded to JSON
        let encoder = JSONEncoder()
        let data = try! encoder.encode(userProfile)
        
        // Then: Should encode successfully
        XCTAssertNotNil(data)
        
        // When: UserProfile is decoded from JSON
        let decoder = JSONDecoder()
        let decodedProfile = try! decoder.decode(UserProfile.self, from: data)
        
        // Then: Should decode successfully and match original
        XCTAssertEqual(decodedProfile.id, userProfile.id)
        XCTAssertEqual(decodedProfile.age.value, userProfile.age.value)
        XCTAssertEqual(decodedProfile.genderIdentity, userProfile.genderIdentity)
        XCTAssertEqual(decodedProfile.sexAssignedAtBirth, userProfile.sexAssignedAtBirth)
        XCTAssertEqual(decodedProfile.voiceConditions, userProfile.voiceConditions)
        XCTAssertEqual(decodedProfile.diagnosedConditions, userProfile.diagnosedConditions)
        XCTAssertEqual(decodedProfile.suspectedConditions, userProfile.suspectedConditions)
        XCTAssertEqual(decodedProfile.deviceModel, userProfile.deviceModel)
        XCTAssertEqual(decodedProfile.osVersion, userProfile.osVersion)
        XCTAssertEqual(decodedProfile.createdAt, userProfile.createdAt)
    }
    
    func testUserProfileWithMinimalData() {
        // Given: A minimal UserProfile with required fields only
        let userProfile = try! UserProfile(
            id: "minimal-user",
            age: 30,
            genderIdentity: .preferNotToSay,
            sexAssignedAtBirth: .preferNotToSay,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            deviceModel: "iPhone 14",
            osVersion: "16.0"
        )
        
        // When: UserProfile is encoded and decoded
        let encoder = JSONEncoder()
        let data = try! encoder.encode(userProfile)
        let decoder = JSONDecoder()
        let decodedProfile = try! decoder.decode(UserProfile.self, from: data)
        
        // Then: Should handle minimal data correctly
        XCTAssertEqual(decodedProfile.id, userProfile.id)
        XCTAssertEqual(decodedProfile.age.value, userProfile.age.value)
        XCTAssertEqual(decodedProfile.genderIdentity, userProfile.genderIdentity)
        XCTAssertEqual(decodedProfile.suspectedConditions, []) // Should be empty array
    }
    
    func testUserProfileWithComplexConditions() {
        // Given: A UserProfile with multiple conditions
        let userProfile = try! UserProfile(
            id: "complex-user",
            age: 45,
            genderIdentity: .man,
            sexAssignedAtBirth: .male,
            voiceConditions: ["Hoarseness", "Voice fatigue", "Pitch changes"],
            diagnosedConditions: ["PCOS", "PMDD"],
            suspectedConditions: ["Thyroid issues"],
            deviceModel: "iPhone 15 Pro",
            osVersion: "17.1",
            createdAt: "2024-01-15T12:30:45.123Z"
        )
        
        // When: UserProfile is encoded and decoded
        let encoder = JSONEncoder()
        let data = try! encoder.encode(userProfile)
        let decoder = JSONDecoder()
        let decodedProfile = try! decoder.decode(UserProfile.self, from: data)
        
        // Then: Should handle complex conditions correctly
        XCTAssertEqual(decodedProfile.voiceConditions.count, 3)
        XCTAssertEqual(decodedProfile.diagnosedConditions.count, 2)
        XCTAssertEqual(decodedProfile.suspectedConditions.count, 1)
        XCTAssertTrue(decodedProfile.voiceConditions.contains("Hoarseness"))
        XCTAssertTrue(decodedProfile.diagnosedConditions.contains("PCOS"))
    }
    
    // MARK: - Age Value Object Codable Tests
    
    func testAgeValueObjectCodable() {
        // Given: A valid Age value object
        let age = try! Age(25)
        
        // When: Age is encoded and decoded
        let encoder = JSONEncoder()
        let data = try! encoder.encode(age)
        let decoder = JSONDecoder()
        let decodedAge = try! decoder.decode(Age.self, from: data)
        
        // Then: Should encode and decode correctly
        XCTAssertEqual(decodedAge.value, age.value)
    }
    
    func testAgeValueObjectEdgeCases() {
        // Given: Age values at the boundaries
        let minimumAge = try! Age(13)
        let maximumAge = try! Age(120)
        
        // When: Boundary ages are encoded and decoded
        let encoder = JSONEncoder()
        let minData = try! encoder.encode(minimumAge)
        let maxData = try! encoder.encode(maximumAge)
        
        let decoder = JSONDecoder()
        let decodedMinAge = try! decoder.decode(Age.self, from: minData)
        let decodedMaxAge = try! decoder.decode(Age.self, from: maxData)
        
        // Then: Should handle boundary values correctly
        XCTAssertEqual(decodedMinAge.value, 13)
        XCTAssertEqual(decodedMaxAge.value, 120)
    }
    
    // MARK: - Enum Codable Tests
    
    func testGenderIdentityEnumCodable() {
        // Given: All gender identity cases
        let cases: [GenderIdentity] = [.woman, .man, .nonbinary, .other, .preferNotToSay]
        
        // When: Each case is encoded and decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for genderCase in cases {
            let data = try! encoder.encode(genderCase)
            let decodedCase = try! decoder.decode(GenderIdentity.self, from: data)
            
            // Then: Should encode and decode correctly
            XCTAssertEqual(decodedCase, genderCase)
        }
    }
    
    func testSexAssignedAtBirthEnumCodable() {
        // Given: All sex assigned at birth cases
        let cases: [SexAssignedAtBirth] = [.female, .male, .intersex, .preferNotToSay]
        
        // When: Each case is encoded and decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for sexCase in cases {
            let data = try! encoder.encode(sexCase)
            let decodedCase = try! decoder.decode(SexAssignedAtBirth.self, from: data)
            
            // Then: Should encode and decode correctly
            XCTAssertEqual(decodedCase, sexCase)
        }
    }
    
    // MARK: - JSON Format Tests
    
    func testUserProfileJSONFormat() {
        // Given: A UserProfile with known data
        let userProfile = try! UserProfile(
            id: "json-test-user",
            age: 28,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            deviceModel: "iPhone 15",
            osVersion: "17.0",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(userProfile)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Then: Should contain expected JSON structure
        XCTAssertTrue(jsonString.contains("\"id\""))
        XCTAssertTrue(jsonString.contains("\"age\""))
        XCTAssertTrue(jsonString.contains("\"genderIdentity\""))
        XCTAssertTrue(jsonString.contains("\"sexAssignedAtBirth\""))
        XCTAssertTrue(jsonString.contains("\"voiceConditions\""))
        XCTAssertTrue(jsonString.contains("\"diagnosedConditions\""))
        XCTAssertTrue(jsonString.contains("\"suspectedConditions\""))
        XCTAssertTrue(jsonString.contains("\"deviceModel\""))
        XCTAssertTrue(jsonString.contains("\"osVersion\""))
        XCTAssertTrue(jsonString.contains("\"createdAt\""))
        
        // And: Should contain correct enum values
        XCTAssertTrue(jsonString.contains("\"Woman\""))
        XCTAssertTrue(jsonString.contains("\"Female\""))
    }
    
    // MARK: - Backend Compatibility Tests
    
    func testUserProfileFromBackendJSON() {
        // Given: JSON data that might come from a backend
        let backendJSON = """
        {
            "id": "backend-user-123",
            "age": 35,
            "genderIdentity": "Man",
            "sexAssignedAtBirth": "Male",
            "voiceConditions": ["Hoarseness"],
            "diagnosedConditions": ["PCOS"],
            "suspectedConditions": [],
            "deviceModel": "iPhone 15 Pro",
            "osVersion": "17.0",
            "createdAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        // When: JSON is decoded to UserProfile
        let decoder = JSONDecoder()
        let userProfile = try! decoder.decode(UserProfile.self, from: backendJSON)
        
        // Then: Should decode backend format correctly
        XCTAssertEqual(userProfile.id, "backend-user-123")
        XCTAssertEqual(userProfile.age.value, 35)
        XCTAssertEqual(userProfile.genderIdentity, .man)
        XCTAssertEqual(userProfile.sexAssignedAtBirth, .male)
        XCTAssertEqual(userProfile.voiceConditions, ["Hoarseness"])
        XCTAssertEqual(userProfile.diagnosedConditions, ["PCOS"])
        XCTAssertEqual(userProfile.suspectedConditions, [])
    }
    
    func testUserProfileToBackendJSON() {
        // Given: A UserProfile that needs to be sent to backend
        let userProfile = try! UserProfile(
            id: "frontend-user-456",
            age: 42,
            genderIdentity: .nonbinary,
            sexAssignedAtBirth: .intersex,
            voiceConditions: ["Voice fatigue"],
            diagnosedConditions: ["PMDD"],
            suspectedConditions: ["Thyroid issues"],
            deviceModel: "iPhone 14",
            osVersion: "16.5",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded for backend
        let encoder = JSONEncoder()
        let data = try! encoder.encode(userProfile)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Then: Should produce valid JSON for backend consumption
        XCTAssertTrue(jsonString.contains("\"frontend-user-456\""))
        XCTAssertTrue(jsonString.contains("\"age\":42"))
        XCTAssertTrue(jsonString.contains("\"Nonbinary\""))
        XCTAssertTrue(jsonString.contains("\"Intersex\""))
        
        // And: Should be parseable by backend
        let decoder = JSONDecoder()
        let decodedProfile = try! decoder.decode(UserProfile.self, from: data)
        XCTAssertEqual(decodedProfile.id, userProfile.id)
    }
    
    // MARK: - Error Handling Tests
    
    func testUserProfileDecodingWithInvalidAge() {
        // Given: JSON with invalid age value
        let invalidAgeJSON = """
        {
            "id": "invalid-age-user",
            "age": 5,
            "genderIdentity": "Woman",
            "sexAssignedAtBirth": "Female",
            "voiceConditions": ["None"],
            "diagnosedConditions": ["None"],
            "deviceModel": "iPhone 15",
            "osVersion": "17.0",
            "createdAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        // When: JSON is decoded
        let decoder = JSONDecoder()
        
        // Then: Should throw validation error during Age value object decoding
        XCTAssertThrowsError(try decoder.decode(UserProfile.self, from: invalidAgeJSON)) { error in
            // Should throw ValidationError.ageInvalid() from Age value object
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testAgeValueObjectDecodingWithInvalidValue() {
        // Given: JSON with invalid age value
        let invalidAgeJSON = "5".data(using: .utf8)!
        
        // When: Age value object is decoded directly
        let decoder = JSONDecoder()
        
        // Then: Should throw validation error
        XCTAssertThrowsError(try decoder.decode(Age.self, from: invalidAgeJSON)) { error in
            XCTAssertTrue(error is ValidationError)
            if case .ageInvalid = error as? ValidationError {
                // Expected error type
            } else {
                XCTFail("Expected ValidationError.ageInvalid but got \(error)")
            }
        }
    }
    
    func testAgeValueObjectDecodingWithValidValue() {
        // Given: JSON with valid age value
        let validAgeJSON = "25".data(using: .utf8)!
        
        // When: Age value object is decoded directly
        let decoder = JSONDecoder()
        let age = try! decoder.decode(Age.self, from: validAgeJSON)
        
        // Then: Should decode successfully
        XCTAssertEqual(age.value, 25)
    }
    
    func testUserProfileDecodingWithMissingRequiredFields() {
        // Given: JSON missing required fields
        let incompleteJSON = """
        {
            "id": "incomplete-user",
            "age": 25,
            "genderIdentity": "Woman",
            "sexAssignedAtBirth": "Female"
        }
        """.data(using: .utf8)!
        
        // When: JSON is decoded
        let decoder = JSONDecoder()
        
        // Then: Should throw decoding error
        XCTAssertThrowsError(try decoder.decode(UserProfile.self, from: incompleteJSON))
    }
    
    // MARK: - Conditional Encoding Tests
    
    func testUserProfileEncodingOmitsEmptySuspectedConditions() {
        // Given: UserProfile with empty suspectedConditions
        let userProfile = try! UserProfile(
            id: "empty-suspected-user",
            age: 30,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            suspectedConditions: [], // Empty array
            deviceModel: "iPhone 15",
            osVersion: "17.0",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(userProfile)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Then: Should omit suspectedConditions field from JSON
        XCTAssertFalse(jsonString.contains("\"suspectedConditions\""))
        XCTAssertTrue(jsonString.contains("\"voiceConditions\""))
        XCTAssertTrue(jsonString.contains("\"diagnosedConditions\""))
    }
    
    func testUserProfileEncodingIncludesNonEmptySuspectedConditions() {
        // Given: UserProfile with non-empty suspectedConditions
        let userProfile = try! UserProfile(
            id: "non-empty-suspected-user",
            age: 30,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            suspectedConditions: ["PCOS", "Thyroid issues"], // Non-empty array
            deviceModel: "iPhone 15",
            osVersion: "17.0",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(userProfile)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Then: Should include suspectedConditions field in JSON
        XCTAssertTrue(jsonString.contains("\"suspectedConditions\""))
        XCTAssertTrue(jsonString.contains("\"PCOS\""))
        XCTAssertTrue(jsonString.contains("\"Thyroid issues\""))
    }
    
    func testUserProfileDecodingWithMissingSuspectedConditions() {
        // Given: JSON without suspectedConditions field
        let jsonWithoutSuspected = """
        {
            "id": "missing-suspected-user",
            "age": 30,
            "genderIdentity": "Woman",
            "sexAssignedAtBirth": "Female",
            "voiceConditions": ["None"],
            "diagnosedConditions": ["None"],
            "deviceModel": "iPhone 15",
            "osVersion": "17.0",
            "createdAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        // When: JSON is decoded
        let decoder = JSONDecoder()
        let userProfile = try! decoder.decode(UserProfile.self, from: jsonWithoutSuspected)
        
        // Then: Should provide empty array as default for suspectedConditions
        XCTAssertEqual(userProfile.suspectedConditions, [])
        XCTAssertEqual(userProfile.id, "missing-suspected-user")
    }
    
    func testUserProfileDecodingWithPresentSuspectedConditions() {
        // Given: JSON with suspectedConditions field
        let jsonWithSuspected = """
        {
            "id": "present-suspected-user",
            "age": 30,
            "genderIdentity": "Woman",
            "sexAssignedAtBirth": "Female",
            "voiceConditions": ["None"],
            "diagnosedConditions": ["None"],
            "suspectedConditions": ["PCOS"],
            "deviceModel": "iPhone 15",
            "osVersion": "17.0",
            "createdAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        // When: JSON is decoded
        let decoder = JSONDecoder()
        let userProfile = try! decoder.decode(UserProfile.self, from: jsonWithSuspected)
        
        // Then: Should decode suspectedConditions correctly
        XCTAssertEqual(userProfile.suspectedConditions, ["PCOS"])
        XCTAssertEqual(userProfile.id, "present-suspected-user")
    }
    
    func testUserProfileRoundTripWithConditionalEncoding() {
        // Given: UserProfile with empty suspectedConditions
        let originalProfile = try! UserProfile(
            id: "roundtrip-user",
            age: 35,
            genderIdentity: .man,
            sexAssignedAtBirth: .male,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            suspectedConditions: [], // Empty array
            deviceModel: "iPhone 15",
            osVersion: "17.0",
            createdAt: "2024-01-01T00:00:00.000Z"
        )
        
        // When: UserProfile is encoded and then decoded
        let encoder = JSONEncoder()
        let data = try! encoder.encode(originalProfile)
        let decoder = JSONDecoder()
        let decodedProfile = try! decoder.decode(UserProfile.self, from: data)
        
        // Then: Should maintain data integrity through round trip
        XCTAssertEqual(decodedProfile.id, originalProfile.id)
        XCTAssertEqual(decodedProfile.age.value, originalProfile.age.value)
        XCTAssertEqual(decodedProfile.genderIdentity, originalProfile.genderIdentity)
        XCTAssertEqual(decodedProfile.suspectedConditions, originalProfile.suspectedConditions)
        XCTAssertEqual(decodedProfile.suspectedConditions.count, 0)
    }
} 