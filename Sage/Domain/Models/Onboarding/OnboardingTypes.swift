/// Signup methods available to users
/// - anonymous: User signs up without email/password
/// - email: User signs up with email/password

import Foundation

enum SignupMethod: String, CaseIterable, Codable {
    case anonymous = "anonymous"
    case email = "email"
}

/// Specific error types for signup operations
/// - Enables robust error handling and testing with stable error comparison
enum SignupErrorType: String, Error, LocalizedError {
    case emailAlreadyInUse = "email_already_in_use"
    case networkRequestFailed = "network_request_failed"
    case invalidCredentials = "invalid_credentials"
    case unknown = "unknown"
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "This email is already registered. Try signing in instead."
        case .networkRequestFailed:
            return "Check your internet connection and try again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

/// Results of signup method selection operation
/// - created: New profile created successfully with UserProfile data
/// - exists: Profile already exists for this user with UserProfile data
/// - error: Operation failed with specific error type
/// 
/// Rationale: This allows direct use of the created profile without requiring re-fetching
enum SignupResult: Equatable {
    case created(UserProfile)
    case exists(UserProfile)
    case error(SignupErrorType)
}

// MARK: - Value Objects

/// Age value object with built-in validation
/// - Encapsulates age range validation (13-120)
/// - Provides semantic clarity and reusability
public struct Age: Equatable, Codable {
    public let value: Int
    
    public init(_ value: Int) throws {
        guard value >= 13 && value <= 120 else {
            throw ValidationError.ageInvalid()
        }
        self.value = value
    }
    
    /// Creates age from optional value with validation
    public init?(optional value: Int?) {
        guard let value = value, value.isValidAge else { return nil }
        self.value = value
    }
    
    /// Validates age without creating instance
    public static func isValid(_ value: Int) -> Bool {
        return value >= 13 && value <= 120
    }
    
    /// Minimum valid age for research purposes
    public static let minimum = 13
    
    /// Maximum valid age for research purposes
    public static let maximum = 120
    
    // MARK: - Codable Implementation
    
    /// Custom encoding to ensure validation during serialization
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    /// Custom decoding to ensure validation during deserialization
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        // Validate the decoded value
        guard rawValue >= 13 && rawValue <= 120 else {
            throw ValidationError.ageInvalid()
        }
        
        self.value = rawValue
    }
}



/// Extension to provide conditions validation on optional string arrays
extension Optional where Wrapped == [String] {
    /// Validates if the optional array contains at least one condition
    var hasValidConditions: Bool {
        return !(self?.isEmpty ?? true)
    }
}

/// Voice conditions value object
public struct VoiceConditions: Equatable, Codable {
    public let conditions: [String]
    
    public init(_ conditions: [String]) throws {
        guard !conditions.isEmpty else {
            throw ValidationError.voiceConditionsRequired()
        }
        self.conditions = conditions
    }
    
    /// Represents no voice conditions
    public static var none: Self {
        return Self(unsafeConditions: [])
    }
    
    /// Private initializer for creating .none case without validation
    private init(unsafeConditions: [String]) {
        self.conditions = unsafeConditions
    }
    
    // MARK: - Codable Implementation
    
    /// Custom encoding to ensure validation during serialization
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(conditions)
    }
    
    /// Custom decoding to ensure validation during deserialization
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawConditions = try container.decode([String].self)
        
        // Validate the decoded conditions
        guard !rawConditions.isEmpty else {
            throw ValidationError.voiceConditionsRequired()
        }
        
        self.conditions = rawConditions
    }
}

/// Diagnosed conditions value object
public struct DiagnosedConditions: Equatable, Codable {
    public let conditions: [String]
    
    public init(_ conditions: [String]) throws {
        guard !conditions.isEmpty else {
            throw ValidationError.diagnosedConditionsRequired()
        }
        self.conditions = conditions
    }
    
    /// Represents no diagnosed conditions
    public static var none: Self {
        return Self(unsafeConditions: [])
    }
    
    /// Private initializer for creating .none case without validation
    private init(unsafeConditions: [String]) {
        self.conditions = unsafeConditions
    }
    
    // MARK: - Codable Implementation
    
    /// Custom encoding to ensure validation during serialization
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(conditions)
    }
    
    /// Custom decoding to ensure validation during deserialization
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawConditions = try container.decode([String].self)
        
        // Validate the decoded conditions
        guard !rawConditions.isEmpty else {
            throw ValidationError.diagnosedConditionsRequired()
        }
        
        self.conditions = rawConditions
    }
}

// MARK: - Validation Errors

/// Comprehensive validation errors for user profile data
/// - Each field has specific error types for semantic clarity
/// - Provides stable error comparison and field-specific messaging
public enum ValidationError: LocalizedError, Equatable {
    case ageRequired(fieldName: String = "age")
    case ageInvalid(fieldName: String = "age")
    case genderInvalid(fieldName: String = "gender")
    case voiceConditionsRequired(fieldName: String = "voiceConditions")
    case diagnosedConditionsRequired(fieldName: String = "diagnosedConditions")
    
    public var errorDescription: String? {
        switch self {
        case .ageRequired:
            return "Age is required for research purposes"
        case .ageInvalid:
            return "Age must be between 13 and 120"
        case .genderInvalid:
            return "Please select a valid gender option"
        case .voiceConditionsRequired:
            return "Please select at least one voice condition"
        case .diagnosedConditionsRequired:
            return "Please select at least one diagnosed condition"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .ageRequired:
            return "Please enter your age to proceed."
        case .ageInvalid:
            return "Enter a valid age between \(Age.minimum) and \(Age.maximum)."
        case .genderInvalid:
            return "Please select a gender option from the list."
        case .voiceConditionsRequired:
            return "Select at least one voice condition or choose 'None' if you don't have any."
        case .diagnosedConditionsRequired:
            return "Select at least one diagnosed condition or choose 'None' if you don't have any."
        }
    }
    
    public var fieldName: String {
        switch self {
        case .ageRequired(let fieldName), 
             .ageInvalid(let fieldName), 
             .genderInvalid(let fieldName),
             .voiceConditionsRequired(let fieldName),
             .diagnosedConditionsRequired(let fieldName):
            return fieldName
        }
    }
}

/// Completion data for onboarding final step
/// - Encapsulates data collected during onboarding completion
/// - Provides extensible structure for future onboarding requirements
public struct OnboardingCompletionData: Equatable, Codable {
    public let completedAt: Date
    public let totalDuration: TimeInterval
    public let stepsCompleted: Int
    public let userProfileData: UserProfileData?
    
    public init(
        completedAt: Date = Date(),
        totalDuration: TimeInterval = 0,
        stepsCompleted: Int = 0,
        userProfileData: UserProfileData? = nil
    ) {
        self.completedAt = completedAt
        self.totalDuration = totalDuration
        self.stepsCompleted = stepsCompleted
        self.userProfileData = userProfileData
    }
}

/// Protocol for date injection to improve testability
public protocol DateProvider {
    var currentDate: Date { get }
}

/// Default date provider using system time
public struct SystemDateProvider: DateProvider {
    public var currentDate: Date {
        return Date()
    }
    
    public init() {}
}

/// Mock date provider for testing
public struct MockDateProvider: DateProvider {
    public let currentDate: Date
    
    public init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }
}

/// Onboarding steps for the new GWT-compliant onboarding flow
/// - signupMethod: User chooses [anonymous, email] signup with optional selected method
/// - explainer: View 1 - "Let's run some quick tests" screen
/// - userInfoForm: View 2 - User provides age, gender, and optional name with form data
/// - sustainedVowelTest: View 3 - "Ahhh" test with 10-second recording duration
/// - readingPrompt: View 4 - Reading prompt placeholder with optional prompt text
/// - finalStep: View 5 - Final completion step with optional completion data
/// - completed: Onboarding is complete with optional completion timestamp
enum OnboardingStep: Equatable {
    case signupMethod(SignupMethod? = nil)
    case explainer
    case userInfoForm(UserProfileData? = nil)
    case sustainedVowelTest(Duration = .seconds(10))
    case readingPrompt(String? = nil)
    case finalStep(OnboardingCompletionData? = nil)
    case completed(Date = Date())
    
    /// String identifier for analytics and persistence
    var identifier: String {
        switch self {
        case .signupMethod:
            return "signup_method"
        case .explainer:
            return "explainer"
        case .userInfoForm:
            return "user_info_form"
        case .sustainedVowelTest:
            return "sustained_vowel_test"
        case .readingPrompt:
            return "reading_prompt"
        case .finalStep:
            return "final_step"
        case .completed:
            return "completed"
        }
    }
    

    
    // MARK: - Convenience Methods
    
    /// Returns the selected signup method if available
    var selectedSignupMethod: SignupMethod? {
        if case .signupMethod(let method) = self {
            return method
        }
        return nil
    }
    
    /// Returns the user profile data if available
    var userProfileData: UserProfileData? {
        if case .userInfoForm(let data) = self {
            return data
        }
        return nil
    }
    
    /// Returns the sustained vowel test duration
    var sustainedVowelDuration: Duration {
        if case .sustainedVowelTest(let duration) = self {
            return duration
        }
        return .seconds(10)
    }
    
    /// Returns the reading prompt text if available
    var readingPromptText: String? {
        if case .readingPrompt(let prompt) = self {
            return prompt
        }
        return nil
    }
    
    /// Returns the completion data if available
    var completionData: OnboardingCompletionData? {
        if case .finalStep(let data) = self {
            return data
        }
        return nil
    }
    
    /// Returns the completion timestamp
    var completionTimestamp: Date {
        if case .completed(let timestamp) = self {
            return timestamp
        }
        return Date()
    }
    
    /// Creates a new step with updated associated data
    func withAssociatedData<T>(_ data: T) -> OnboardingStep {
        switch self {
        case .signupMethod:
            if let method = data as? SignupMethod {
                return .signupMethod(method)
            }
            return self
        case .userInfoForm:
            if let profileData = data as? UserProfileData {
                return .userInfoForm(profileData)
            }
            return self
        case .sustainedVowelTest:
            if let duration = data as? Duration {
                return .sustainedVowelTest(duration)
            }
            return self
        case .readingPrompt:
            if let prompt = data as? String {
                return .readingPrompt(prompt)
            }
            return self
        case .finalStep:
            if let completionData = data as? OnboardingCompletionData {
                return .finalStep(completionData)
            }
            return self
        case .completed:
            if let timestamp = data as? Date {
                return .completed(timestamp)
            }
            return self
        default:
            return self
        }
    }
}

/// User profile data for form binding during onboarding
/// This is a local struct for UI state, mapped to UserProfile for persistence
/// - Uses value objects for better encapsulation and validation
/// - Provides comprehensive validation with semantic error types
public struct UserProfileData: Equatable {
    public var age: Age?
    public var genderIdentity: GenderIdentity
    public var sexAssignedAtBirth: SexAssignedAtBirth
    public var voiceConditions: [String]?
    public var diagnosedConditions: [String]?
    
    public init(
        age: Int?,
        genderIdentity: GenderIdentity = .preferNotToSay,
        sexAssignedAtBirth: SexAssignedAtBirth = .preferNotToSay,
        voiceConditions: [String]? = nil,
        diagnosedConditions: [String]? = nil
    ) {
        self.age = age.flatMap { try? Age($0) }
        self.genderIdentity = genderIdentity
        self.sexAssignedAtBirth = sexAssignedAtBirth
        self.voiceConditions = voiceConditions
        self.diagnosedConditions = diagnosedConditions
    }
    
    // MARK: - Validation Methods
    
    /// Validates profile data - throws ValidationError on first failure
    /// - Uses value objects for consistent validation
    /// - Provides semantic error messages
    public func validate() throws {
        // Age validation using value object
        guard let age = age else {
            throw ValidationError.ageRequired()
        }
        
        // Voice conditions validation using shared helper
        if !voiceConditions.hasValidConditions {
            throw ValidationError.voiceConditionsRequired()
        }
        
        // Diagnosed conditions validation using shared helper
        if !diagnosedConditions.hasValidConditions {
            throw ValidationError.diagnosedConditionsRequired()
        }
    }
    
    /// Validates profile data - returns all errors at once
    /// - Collects all validation errors for comprehensive feedback
    /// - Useful for form validation where multiple errors can be shown
    public func validateAll() -> UserProfileValidationResult {
        let errors = collectValidationErrors()
        return UserProfileValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Collects all validation errors for the profile data
    /// - Centralized validation logic for reuse
    /// - Returns array of ValidationError instances
    private func collectValidationErrors() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Age validation using value object
        if age == nil {
            errors.append(.ageRequired())
        }
        
        // Voice conditions validation using shared helper
        if !voiceConditions.hasValidConditions {
            errors.append(.voiceConditionsRequired())
        }
        
        // Diagnosed conditions validation using shared helper
        if !diagnosedConditions.hasValidConditions {
            errors.append(.diagnosedConditionsRequired())
        }
        
        return errors
    }
    

    
    // MARK: - Profile Creation Methods
    

    
    /// Creates a UserProfile from this form data with injected date provider
    /// - Parameters:
    ///   - id: User identifier
    ///   - deviceModel: Device model string
    ///   - osVersion: Operating system version
    ///   - dateProvider: Date provider for consistent testing
    /// - Returns: UserProfile instance
    public func toUserProfile(
        id: String, 
        deviceModel: String, 
        osVersion: String, 
        dateProvider: DateProvider = SystemDateProvider()
    ) throws -> UserProfile {
        guard let age = age else {
            throw ValidationError.ageRequired()
        }
        
        let createdDate = dateProvider.currentDate
        return try UserProfile(
            id: id,
            age: age.value,
            genderIdentity: genderIdentity,
            sexAssignedAtBirth: sexAssignedAtBirth,
            voiceConditions: voiceConditions ?? [],
            diagnosedConditions: diagnosedConditions ?? [],
            suspectedConditions: [],
            deviceModel: deviceModel,
            osVersion: osVersion,
            createdAt: UserProfile.formatDate(createdDate)
        )
    }
}

/// Result of user profile validation
/// - Encapsulates validation results with semantic clarity
/// - Provides both boolean result and detailed error information
public struct UserProfileValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    
    public init(isValid: Bool, errors: [ValidationError]) {
        self.isValid = isValid
        self.errors = errors
    }
    
    /// Returns the first error for simple validation scenarios
    public var firstError: ValidationError? {
        return errors.first
    }
    
    /// Returns error messages for UI display
    public var errorMessages: [String] {
        return errors.compactMap { $0.errorDescription }
    }
    
    /// Returns field-specific errors for form validation
    public var fieldErrors: [String: String] {
        return mapErrorsToFieldDictionary { $0.errorDescription }
    }
    
    /// Returns field-specific validation errors for direct UI binding
    public var fieldErrorMap: [String: ValidationError] {
        return mapErrorsToFieldDictionary { $0 }
    }
    
    /// Maps validation errors to field dictionary using provided transform
    /// - Generic utility for creating field-specific error mappings
    /// - Parameter transform: Function to transform ValidationError to desired type
    /// - Returns: Dictionary mapping field names to transformed error values
    private func mapErrorsToFieldDictionary<T>(_ transform: (ValidationError) -> T) -> [String: T] {
        var fieldErrors: [String: T] = [:]
        for error in errors {
            fieldErrors[error.fieldName] = transform(error)
        }
        return fieldErrors
    }
}