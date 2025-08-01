import XCTest
@testable import Sage

/// Tests for UserProfile demographic mapping functionality
/// - Tests the static demographicCategory methods for various age/gender combinations
/// - Follows GWT structure for clear test organization
final class UserProfileDemographicMappingTests: XCTestCase {
    
    // MARK: - Adolescent Tests
    
    func testDemographicCategoryForAdolescentWoman() {
        // Given: User is 15 years old and identifies as woman
        let age = 15
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adolescent category
        XCTAssertEqual(demographic, .adolescent)
    }
    
    func testDemographicCategoryForAdolescentMan() {
        // Given: User is 17 years old and identifies as man
        let age = 17
        let genderIdentity = GenderIdentity.man
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adolescent category
        XCTAssertEqual(demographic, .adolescent)
    }
    
    func testDemographicCategoryForAdolescentNonbinary() {
        // Given: User is 13 years old and identifies as nonbinary
        let age = 13
        let genderIdentity = GenderIdentity.nonbinary
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adolescent category
        XCTAssertEqual(demographic, .adolescent)
    }
    
    // MARK: - Adult Tests
    
    func testDemographicCategoryForAdultWoman() {
        // Given: User is 25 years old and identifies as woman
        let age = 25
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultFemale category
        XCTAssertEqual(demographic, .adultFemale)
    }
    
    func testDemographicCategoryForAdultMan() {
        // Given: User is 45 years old and identifies as man
        let age = 45
        let genderIdentity = GenderIdentity.man
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultMale category
        XCTAssertEqual(demographic, .adultMale)
    }
    
    func testDemographicCategoryForAdultNonbinary() {
        // Given: User is 30 years old and identifies as nonbinary
        let age = 30
        let genderIdentity = GenderIdentity.nonbinary
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultOther category
        XCTAssertEqual(demographic, .adultOther)
    }
    
    func testDemographicCategoryForAdultOther() {
        // Given: User is 50 years old and identifies as other
        let age = 50
        let genderIdentity = GenderIdentity.other
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultOther category
        XCTAssertEqual(demographic, .adultOther)
    }
    
    func testDemographicCategoryForAdultPreferNotToSay() {
        // Given: User is 35 years old and prefers not to say gender
        let age = 35
        let genderIdentity = GenderIdentity.preferNotToSay
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultOther category
        XCTAssertEqual(demographic, .adultOther)
    }
    
    // MARK: - Senior Tests
    
    func testDemographicCategoryForSeniorWoman() {
        // Given: User is 70 years old and identifies as woman
        let age = 70
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return seniorFemale category
        XCTAssertEqual(demographic, .seniorFemale)
    }
    
    func testDemographicCategoryForSeniorMan() {
        // Given: User is 80 years old and identifies as man
        let age = 80
        let genderIdentity = GenderIdentity.man
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return seniorMale category
        XCTAssertEqual(demographic, .seniorMale)
    }
    
    func testDemographicCategoryForSeniorNonbinary() {
        // Given: User is 65 years old and identifies as nonbinary
        let age = 65
        let genderIdentity = GenderIdentity.nonbinary
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return seniorOther category
        XCTAssertEqual(demographic, .seniorOther)
    }
    
    // MARK: - Age Value Object Tests
    
    func testDemographicCategoryWithAgeValueObject() {
        // Given: User has validated age value object and identifies as woman
        let age = try! Age(25)
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated using Age value object
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultFemale category
        XCTAssertEqual(demographic, .adultFemale)
    }
    
    // MARK: - Edge Cases
    
    func testDemographicCategoryForMinimumAdolescentAge() {
        // Given: User is exactly 13 years old and identifies as woman
        let age = 13
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adolescent category
        XCTAssertEqual(demographic, .adolescent)
    }
    
    func testDemographicCategoryForMaximumAdolescentAge() {
        // Given: User is exactly 17 years old and identifies as man
        let age = 17
        let genderIdentity = GenderIdentity.man
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adolescent category
        XCTAssertEqual(demographic, .adolescent)
    }
    
    func testDemographicCategoryForMinimumAdultAge() {
        // Given: User is exactly 18 years old and identifies as woman
        let age = 18
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultFemale category
        XCTAssertEqual(demographic, .adultFemale)
    }
    
    func testDemographicCategoryForMaximumAdultAge() {
        // Given: User is exactly 64 years old and identifies as man
        let age = 64
        let genderIdentity = GenderIdentity.man
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return adultMale category
        XCTAssertEqual(demographic, .adultMale)
    }
    
    func testDemographicCategoryForMinimumSeniorAge() {
        // Given: User is exactly 65 years old and identifies as woman
        let age = 65
        let genderIdentity = GenderIdentity.woman
        
        // When: Demographic category is calculated
        let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
        
        // Then: Should return seniorFemale category
        XCTAssertEqual(demographic, .seniorFemale)
    }
    
    // MARK: - Boundary Condition Tests
    
    func testDemographicCategoryBoundaryConditions() {
        // Given: All boundary ages and gender identities
        let boundaryAges = [13, 17, 18, 64, 65]
        let allGenderIdentities: [GenderIdentity] = [.woman, .man, .nonbinary, .other, .preferNotToSay]
        
        // When: Each boundary age is tested with each gender identity
        for age in boundaryAges {
            for genderIdentity in allGenderIdentities {
                let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
                
                // Then: Should return appropriate category based on age and gender
                switch (age, genderIdentity) {
                case (13...17, _):
                    XCTAssertEqual(demographic, .adolescent, "Age \(age) with \(genderIdentity) should be adolescent")
                case (18...64, .woman):
                    XCTAssertEqual(demographic, .adultFemale, "Age \(age) with \(genderIdentity) should be adultFemale")
                case (18...64, .man):
                    XCTAssertEqual(demographic, .adultMale, "Age \(age) with \(genderIdentity) should be adultMale")
                case (18...64, _):
                    XCTAssertEqual(demographic, .adultOther, "Age \(age) with \(genderIdentity) should be adultOther")
                case (65..., .woman):
                    XCTAssertEqual(demographic, .seniorFemale, "Age \(age) with \(genderIdentity) should be seniorFemale")
                case (65..., .man):
                    XCTAssertEqual(demographic, .seniorMale, "Age \(age) with \(genderIdentity) should be seniorMale")
                case (65..., _):
                    XCTAssertEqual(demographic, .seniorOther, "Age \(age) with \(genderIdentity) should be seniorOther")
                default:
                    XCTFail("Unexpected combination: age \(age) with \(genderIdentity)")
                }
            }
        }
    }
    
    func testDemographicCategoryForUnexpectedGenderValues() {
        // Given: Boundary ages with unexpected gender values
        let boundaryAges = [13, 17, 18, 64, 65]
        let unexpectedGenders: [GenderIdentity] = [.other, .preferNotToSay]
        
        // When: Each boundary age is tested with unexpected gender identities
        for age in boundaryAges {
            for genderIdentity in unexpectedGenders {
                let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
                
                // Then: Should handle unexpected gender values appropriately
                switch age {
                case 13...17:
                    XCTAssertEqual(demographic, .adolescent, "Adolescent age \(age) with \(genderIdentity) should be adolescent")
                case 18...64:
                    XCTAssertEqual(demographic, .adultOther, "Adult age \(age) with \(genderIdentity) should be adultOther")
                case 65...:
                    XCTAssertEqual(demographic, .seniorOther, "Senior age \(age) with \(genderIdentity) should be seniorOther")
                default:
                    XCTFail("Unexpected age: \(age)")
                }
            }
        }
    }
    
    func testDemographicCategoryForMinimumAdolescentBoundary() {
        // Given: User is exactly at the minimum adolescent age with different genders
        let age = 13
        let testCases: [(GenderIdentity, VoiceDemographic)] = [
            (.woman, .adolescent),
            (.man, .adolescent),
            (.nonbinary, .adolescent),
            (.other, .adolescent),
            (.preferNotToSay, .adolescent)
        ]
        
        // When: Each gender identity is tested
        for (genderIdentity, expectedDemographic) in testCases {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should return adolescent for all gender identities at minimum age
            XCTAssertEqual(demographic, expectedDemographic, "Age 13 with \(genderIdentity) should be \(expectedDemographic)")
        }
    }
    
    func testDemographicCategoryForMaximumAdolescentBoundary() {
        // Given: User is exactly at the maximum adolescent age with different genders
        let age = 17
        let testCases: [(GenderIdentity, VoiceDemographic)] = [
            (.woman, .adolescent),
            (.man, .adolescent),
            (.nonbinary, .adolescent),
            (.other, .adolescent),
            (.preferNotToSay, .adolescent)
        ]
        
        // When: Each gender identity is tested
        for (genderIdentity, expectedDemographic) in testCases {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should return adolescent for all gender identities at maximum age
            XCTAssertEqual(demographic, expectedDemographic, "Age 17 with \(genderIdentity) should be \(expectedDemographic)")
        }
    }
    
    func testDemographicCategoryForMinimumAdultBoundary() {
        // Given: User is exactly at the minimum adult age with different genders
        let age = 18
        let testCases: [(GenderIdentity, VoiceDemographic)] = [
            (.woman, .adultFemale),
            (.man, .adultMale),
            (.nonbinary, .adultOther),
            (.other, .adultOther),
            (.preferNotToSay, .adultOther)
        ]
        
        // When: Each gender identity is tested
        for (genderIdentity, expectedDemographic) in testCases {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should return appropriate adult category
            XCTAssertEqual(demographic, expectedDemographic, "Age 18 with \(genderIdentity) should be \(expectedDemographic)")
        }
    }
    
    func testDemographicCategoryForMaximumAdultBoundary() {
        // Given: User is exactly at the maximum adult age with different genders
        let age = 64
        let testCases: [(GenderIdentity, VoiceDemographic)] = [
            (.woman, .adultFemale),
            (.man, .adultMale),
            (.nonbinary, .adultOther),
            (.other, .adultOther),
            (.preferNotToSay, .adultOther)
        ]
        
        // When: Each gender identity is tested
        for (genderIdentity, expectedDemographic) in testCases {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should return appropriate adult category
            XCTAssertEqual(demographic, expectedDemographic, "Age 64 with \(genderIdentity) should be \(expectedDemographic)")
        }
    }
    
    func testDemographicCategoryForMinimumSeniorBoundary() {
        // Given: User is exactly at the minimum senior age with different genders
        let age = 65
        let testCases: [(GenderIdentity, VoiceDemographic)] = [
            (.woman, .seniorFemale),
            (.man, .seniorMale),
            (.nonbinary, .seniorOther),
            (.other, .seniorOther),
            (.preferNotToSay, .seniorOther)
        ]
        
        // When: Each gender identity is tested
        for (genderIdentity, expectedDemographic) in testCases {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should return appropriate senior category
            XCTAssertEqual(demographic, expectedDemographic, "Age 65 with \(genderIdentity) should be \(expectedDemographic)")
        }
    }
    
    func testDemographicCategoryForExtremeAges() {
        // Given: Extreme age values to test edge cases
        let extremeAges = [1, 12, 120, 150]
        let genderIdentity = GenderIdentity.woman
        
        // When: Each extreme age is tested
        for age in extremeAges {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should handle extreme ages gracefully
            switch age {
            case 1...12:
                // Ages below minimum should default to adultOther (as per current implementation)
                XCTAssertEqual(demographic, .adultOther, "Age \(age) should default to adultOther")
            case 13...17:
                XCTAssertEqual(demographic, .adolescent, "Age \(age) should be adolescent")
            case 18...64:
                XCTAssertEqual(demographic, .adultFemale, "Age \(age) should be adultFemale")
            case 65...120:
                XCTAssertEqual(demographic, .seniorFemale, "Age \(age) should be seniorFemale")
            default:
                // Ages above maximum should default to adultOther (as per current implementation)
                XCTAssertEqual(demographic, .adultOther, "Age \(age) should default to adultOther")
            }
        }
    }
    
    func testDemographicCategoryWithAgeValueObjectBoundaries() {
        // Given: Age value objects at boundary conditions
        let boundaryAges = [try! Age(13), try! Age(17), try! Age(18), try! Age(64), try! Age(65)]
        let genderIdentity = GenderIdentity.man
        
        // When: Each boundary age value object is tested
        for age in boundaryAges {
            let demographic = UserProfile.demographicCategory(for: age, genderIdentity: genderIdentity)
            
            // Then: Should work correctly with Age value objects
            switch age.value {
            case 13...17:
                XCTAssertEqual(demographic, .adolescent, "Age value object \(age.value) should be adolescent")
            case 18...64:
                XCTAssertEqual(demographic, .adultMale, "Age value object \(age.value) should be adultMale")
            case 65...:
                XCTAssertEqual(demographic, .seniorMale, "Age value object \(age.value) should be seniorMale")
            default:
                XCTFail("Unexpected age value: \(age.value)")
            }
        }
    }
} 