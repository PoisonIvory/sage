import XCTest
@testable import Sage

final class UserProfileTests: XCTestCase {
    
    // MARK: - Basic Initialization Tests
    
    func testValidUserProfileCreation() throws {
        let profile = try UserProfile(
            id: "test-123",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        
        XCTAssertEqual(profile.id, "test-123")
        XCTAssertEqual(profile.age.value, 25)
        XCTAssertEqual(profile.genderIdentity, .woman)
        XCTAssertEqual(profile.sexAssignedAtBirth, .female)
        XCTAssertEqual(profile.voiceConditions, ["None"])
        XCTAssertEqual(profile.diagnosedConditions, ["None"])
        XCTAssertTrue(profile.suspectedConditions.isEmpty)
    }
    
    func testInvalidAgeValidation() {
        XCTAssertThrowsError(try UserProfile(
            id: "test",
            age: 12,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        ))
        
        XCTAssertThrowsError(try UserProfile(
            id: "test",
            age: 121,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        ))
    }
    
    func testEmptyConditionsValidation() {
        XCTAssertThrowsError(try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: [],
            diagnosedConditions: ["None"]
        ))
        
        XCTAssertThrowsError(try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: []
        ))
    }
    
    // MARK: - Voice Analysis Tests
    
    func testVoiceDemographic() throws {
        // Adult woman
        let adultWoman = try UserProfile(
            id: "test",
            age: 30,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(adultWoman.voiceDemographic, .adultFemale)
        
        // Adult man
        let adultMan = try UserProfile(
            id: "test",
            age: 35,
            genderIdentity: .man,
            sexAssignedAtBirth: .male,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(adultMan.voiceDemographic, .adultMale)
        
        // Adolescent
        let adolescent = try UserProfile(
            id: "test",
            age: 16,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(adolescent.voiceDemographic, .adolescent)
        
        // Elderly
        let elderly = try UserProfile(
            id: "test",
            age: 70,
            genderIdentity: .man,
            sexAssignedAtBirth: .male,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(elderly.voiceDemographic, .elderly)
    }
    
    func testHasVoiceImpactingConditions() throws {
        // No conditions
        let clean = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertFalse(clean.hasVoiceImpactingConditions)
        
        // Voice conditions
        let voiceImpacted = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["Hoarseness"],
            diagnosedConditions: ["None"]
        )
        XCTAssertTrue(voiceImpacted.hasVoiceImpactingConditions)
        
        // Hormonal conditions
        let hormonalImpacted = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["PMDD"]
        )
        XCTAssertTrue(hormonalImpacted.hasVoiceImpactingConditions)
    }
    
    func testHasHormonalConditions() throws {
        // No hormonal conditions
        let noHormonal = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["Anxiety"]
        )
        XCTAssertFalse(noHormonal.hasHormonalConditions)
        
        // Diagnosed hormonal
        let diagnosedHormonal = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["PMDD"]
        )
        XCTAssertTrue(diagnosedHormonal.hasHormonalConditions)
        
        // Suspected hormonal
        let suspectedHormonal = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"],
            suspectedConditions: ["PCOS"]
        )
        XCTAssertTrue(suspectedHormonal.hasHormonalConditions)
    }
    
    func testAnalysisConfidenceAdjustment() throws {
        // Clean profile
        let clean = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(clean.analysisConfidenceAdjustment, 1.0)
        
        // Laryngitis (most severe)
        let laryngitis = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["Laryngitis"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(laryngitis.analysisConfidenceAdjustment, 0.6)
        
        // Hoarseness
        let hoarseness = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["Hoarseness"],
            diagnosedConditions: ["None"]
        )
        XCTAssertEqual(hoarseness.analysisConfidenceAdjustment, 0.8)
        
        // Hormonal conditions
        let hormonal = try UserProfile(
            id: "test",
            age: 25,
            genderIdentity: .woman,
            sexAssignedAtBirth: .female,
            voiceConditions: ["None"],
            diagnosedConditions: ["PMDD"]
        )
        XCTAssertEqual(hormonal.analysisConfidenceAdjustment, 0.9)
    }
    
    // MARK: - Helper Methods Tests
    
    func testCreateMinimal() throws {
        let minimal = try UserProfile.createMinimal(
            userId: "test-123",
            deviceModel: "iPhone 15",
            osVersion: "iOS 17.0"
        )
        
        XCTAssertEqual(minimal.id, "test-123")
        XCTAssertEqual(minimal.age.value, 25)
        XCTAssertEqual(minimal.genderIdentity, .preferNotToSay)
        XCTAssertEqual(minimal.sexAssignedAtBirth, .preferNotToSay)
        XCTAssertEqual(minimal.voiceConditions, ["None"])
        XCTAssertEqual(minimal.diagnosedConditions, ["None"])
        XCTAssertEqual(minimal.deviceModel, "iPhone 15")
        XCTAssertEqual(minimal.osVersion, "iOS 17.0")
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let original = try UserProfile(
            id: "test-123",
            age: 28,
            genderIdentity: .nonbinary,
            sexAssignedAtBirth: .intersex,
            voiceConditions: ["Hoarseness", "Other"],
            diagnosedConditions: ["PMDD", "Anxiety"],
            suspectedConditions: ["PCOS"],
            deviceModel: "iPhone 14",
            osVersion: "iOS 16.5"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfile.self, from: data)
        
        // Verify
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - Enum Tests
    
    func testGenderIdentityCases() {
        let allCases: [GenderIdentity] = [.woman, .man, .nonbinary, .preferNotToSay, .other]
        XCTAssertEqual(GenderIdentity.allCases, allCases)
        
        XCTAssertEqual(GenderIdentity.woman.rawValue, "Woman")
        XCTAssertEqual(GenderIdentity.man.rawValue, "Man")
        XCTAssertEqual(GenderIdentity.nonbinary.rawValue, "Nonbinary")
        XCTAssertEqual(GenderIdentity.preferNotToSay.rawValue, "Prefer not to say")
        XCTAssertEqual(GenderIdentity.other.rawValue, "Other")
    }
    
    func testSexAssignedAtBirthCases() {
        let allCases: [SexAssignedAtBirth] = [.female, .male, .intersex, .preferNotToSay]
        XCTAssertEqual(SexAssignedAtBirth.allCases, allCases)
        
        XCTAssertEqual(SexAssignedAtBirth.female.rawValue, "Female")
        XCTAssertEqual(SexAssignedAtBirth.male.rawValue, "Male")
        XCTAssertEqual(SexAssignedAtBirth.intersex.rawValue, "Intersex")
        XCTAssertEqual(SexAssignedAtBirth.preferNotToSay.rawValue, "Prefer not to say")
    }
}