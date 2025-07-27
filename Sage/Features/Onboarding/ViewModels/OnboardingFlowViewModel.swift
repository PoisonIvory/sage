import Foundation
import Combine
import SwiftUI
import DeviceKit
import FirebaseAuth
import Mixpanel

/// Analytics events for onboarding flow tracking
///
/// Provides type-safe analytics event names for onboarding-related events.
/// All events follow MixPanel best practices with descriptive, action-oriented names.
///
/// - SeeAlso: `DATA_STANDARDS.md` §5.1 for analytics requirements
/// - SeeAlso: `AnalyticsService.swift` for event naming standards
enum OnboardingAnalyticsEvent: String {
    case onboardingStarted = "Onboarding Started"
    case onboardingCompleted = "Onboarding Completed"
    case signupMethodSelected = "Signup Method Selected"
    case profileEnriched = "Profile Enriched"
    case loginSelected = "Login Selected"
    case signupSelected = "Signup Selected"
}

/// Onboarding steps for the onboarding flow
// OnboardingStep is defined in OnboardingTypes.swift

/// Protocol for onboarding flow actions (for testability)
protocol OnboardingFlowCoordinating: AnyObject {
    func onboardingDidComplete(userProfile: UserProfile)
    /// Handles transition to login flow for existing users
    func transitionToLogin()
}

/// ViewModel for the onboarding flow, compliant with DATA_STANDARDS.md §2.2, §2.3, and AI_GENERATION_RULES.md
///
/// - Handles onboarding navigation and user profile creation.
/// - All user profile fields must be defined in DATA_DICTIONARY.md.
/// - All onboarding steps and prompts must match DATA_STANDARDS.md §2.2.
/// - All code is documented for AI self-audit per AI_GENERATION_RULES.md.


// DOMAIN OnboardingFlowViewModel manages the onboarding process for new users
//
// Responsibilities (in order of execution):
// - Navigate through onboarding steps
// - Create a new UserProfile upon signup method selection
// - Incrementally enrich the UserProfile as the user provides more information
// - Validate user input at each step
// - Coordinate completion of onboarding
//
// This ViewModel follows Domain-Driven Design (DDD) best practices:
// - The UserProfile is a domain entity created at initial signup intent
// - The profile is enriched as onboarding progresses

// MARK: - Protocols for Dependency Injection
// Protocols are defined in OnboardingProtocols.swift and AuthService.swift

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    // MARK: - Published State (UI Layer)
    @Published var currentStep: OnboardingStep = .signupMethod
    @Published private(set) var selectedSignupMethod: SignupMethod?
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var userProfileData: UserProfileData = UserProfileData()
    @Published private(set) var validationErrors: [ValidationError] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var operationInProgress: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - UI State Properties
    @Published var userInfo: UserInfo = UserInfo()
    var isAnonymous: Bool {
        return selectedSignupMethod == .anonymous
    }

    // MARK: - Dependencies
    private weak var coordinator: OnboardingFlowCoordinating?
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let authService: AuthServiceProtocol

    // MARK: - Constants
    private let defaultAge = 0 // Will be updated when user provides age
    private let defaultGender = "" // Will be updated when user provides gender

    // MARK: - Initialization
    init(
        coordinator: OnboardingFlowCoordinating?,
        userProfileRepository: UserProfileRepositoryProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.coordinator = coordinator
        self.userProfileRepository = userProfileRepository
        self.analyticsService = analyticsService
        self.authService = authService
        print("OnboardingFlowViewModel: initialized for new user onboarding")
    }

    // MARK: - Public Interface (Domain Commands)

    /// Handles user signup method selection. Checks for existing profile and creates a new one if needed.
    /// - Parameter method: The selected signup method (anonymous or email)
    /// - Returns: The result of the operation (created, exists, or error)
    func selectSignupMethod(_ method: SignupMethod) async -> SignupResult {
        guard !operationInProgress else { return .error(OnboardingError.concurrentOperation) }
        operationInProgress = true
        isLoading = true
        errorMessage = nil
        let userId = authService.currentUserId ?? UUID().uuidString
        do {
            let exists = try await checkExistingProfile(userId: userId)
            if exists {
                return await handleExistingProfile(userId: userId, method: method)
            } else {
                return await handleNewProfile(userId: userId, method: method)
            }
        } catch {
            errorMessage = "Unable to check your account status. Please try again."
            isLoading = false
            operationInProgress = false
            return .error(error)
        }
    }

    func updateUserProfileData(_ data: UserProfileData) {
        // Given: User is editing their profile data
        // When: Data is updated, update the UserProfileData and UserProfile entity
        userProfileData = data
        if var profile = userProfile {
            profile = UserProfile(
                id: profile.id,
                age: data.age,
                gender: data.gender,
                deviceModel: profile.deviceModel,
                osVersion: profile.osVersion,
                createdAt: profile.createdAt
            )
            userProfile = profile
        }
        // Then: Validation errors are cleared
        validationErrors = []
        print("OnboardingFlowViewModel: user profile data updated and UserProfile enriched")

        // Analytics: Track onboarding_profile_enriched event
        if let profile = userProfile {
            analyticsService.track(
                OnboardingAnalyticsEvent.profileEnriched.rawValue,
                properties: [
                    AnalyticsProperties.userId: profile.id,
                    AnalyticsProperties.step: "profile_enriched",
                    AnalyticsProperties.onboardingStep: currentStep.rawValue
                ],
                origin: "OnboardingFlowViewModel"
            )
        }
    }

    func completeUserProfile() {
        // Given: User is in the profile creation step with some profile data
        print("OnboardingFlowViewModel: attempting to complete user profile")

        // When: We validate the profile data
        let errors = validateUserProfile()
        validationErrors = errors

        // Then: If valid, mark onboarding as complete and notify coordinator; else, show errors
        if errors.isEmpty {
            // Then: Profile data is valid, onboarding is complete
            completeOnboarding()
        } else {
            // Then: Validation failed, show errors and stay on profile creation step
            print("OnboardingFlowViewModel: validation failed with \(errors.count) errors")
        }
    }

    // MARK: - Private Implementation (Domain Logic)

    private func validateUserProfile() -> [ValidationError] {
        var errors: [ValidationError] = []
        // Given: Profile data to validate
        // Note: Name is not required for true anonymity
        // Only age is required for research purposes (demographic data)
        if userProfileData.age <= 0 {
            errors.append(.ageRequired)
        }
        if userProfileData.age < 13 || userProfileData.age > 120 {
            errors.append(.ageInvalid)
        }
        // Then: Return all validation errors found
        print("OnboardingFlowViewModel: validation completed with \(errors.count) errors")
        return errors
    }

    private func completeOnboarding() {
        // Given: Validated and enriched UserProfile
        print("OnboardingFlowViewModel: completing onboarding for user id=\(userProfile?.id ?? "nil")")
        // When: Notifying coordinator and marking onboarding as completed
        if let profile = userProfile {
            coordinator?.onboardingDidComplete(userProfile: profile)
            // Analytics: Track onboarding_completed event
            analyticsService.track(
                OnboardingAnalyticsEvent.onboardingCompleted.rawValue,
                properties: [
                    AnalyticsProperties.userId: profile.id,
                    AnalyticsProperties.signupMethod: selectedSignupMethod?.rawValue ?? "unknown",
                    AnalyticsProperties.step: "completed",
                    AnalyticsProperties.onboardingStep: currentStep.rawValue
                ],
                origin: "OnboardingFlowViewModel"
            )
        }
        currentStep = .completed
        // Then: Onboarding is complete
        print("OnboardingFlowViewModel: onboarding completed successfully")
    }

    // Analytics: Track onboarding_started event when onboarding begins
    func trackOnboardingStartedIfNeeded() {
        if let profile = userProfile {
            analyticsService.track(
                OnboardingAnalyticsEvent.onboardingStarted.rawValue,
                properties: [
                    AnalyticsProperties.userId: profile.id,
                    AnalyticsProperties.step: "started",
                    AnalyticsProperties.onboardingStep: currentStep.rawValue
                ],
                origin: "OnboardingFlowViewModel"
            )
        }
    }

    /// Checks if a user profile exists for the given userId.
    private func checkExistingProfile(userId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            userProfileRepository.fetchUserProfile(withId: userId) { profile in
                // In a real implementation, handle error propagation from repository
                continuation.resume(returning: profile != nil)
            }
        }
    }

    /// Handles the flow for an existing user profile.
    @MainActor
    private func handleExistingProfile(userId: String, method: SignupMethod) async -> SignupResult {
        return await withCheckedContinuation { continuation in
            userProfileRepository.fetchUserProfile(withId: userId) { [weak self] profile in
                guard let self = self else { 
                    continuation.resume(returning: .error(OnboardingError.concurrentOperation))
                    return 
                }
                self.userProfile = profile
                self.selectedSignupMethod = method
                self.currentStep = .completed
                self.trackSignupMethodSelected(userId: userId, method: method)
                self.isLoading = false
                self.operationInProgress = false
                continuation.resume(returning: .exists)
            }
        }
    }

    /// Handles the flow for a new user profile.
    @MainActor
    private func handleNewProfile(userId: String, method: SignupMethod) async -> SignupResult {
        let newProfile = createNewUserProfile(userId: userId)
        self.userProfile = newProfile
        self.selectedSignupMethod = method
        self.currentStep = .explainer
        self.trackSignupMethodSelected(userId: userId, method: method)
        
        // Automatically track onboarding started when new profile is created
        trackOnboardingStartedIfNeeded()
        
        self.isLoading = false
        self.operationInProgress = false
        return .created
    }

    /// Creates a new UserProfile with default values.
    private func createNewUserProfile(userId: String) -> UserProfile {
        UserProfile(
            id: userId,
            age: defaultAge,
            gender: defaultGender,
            deviceModel: Device.current.description,
            osVersion: UIDevice.current.systemVersion,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    /// Tracks the onboarding_signup_method_selected event.
    func trackSignupMethodSelected(userId: String, method: SignupMethod) {
        analyticsService.track(
            OnboardingAnalyticsEvent.signupMethodSelected.rawValue,
            properties: [
                AnalyticsProperties.userId: userId,
                AnalyticsProperties.signupMethod: String(describing: method),
                AnalyticsProperties.step: "signup_method",
                AnalyticsProperties.onboardingStep: currentStep.rawValue
            ],
            origin: "OnboardingFlowViewModel"
        )
    }

    /// Validates the user profile data.
    func validateProfileData(_ data: UserProfileData) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Age validation
        if data.age <= 0 {
            errors.append(.ageRequired)
        }
        if data.age < 13 || data.age > 120 {
            errors.append(.ageInvalid)
        }
        
        // Gender validation (if provided)
        if !data.gender.isEmpty {
            let validGenders = ["male", "female", "other", "prefer not to say"]
            if !validGenders.contains(data.gender.lowercased()) {
                errors.append(.genderInvalid)
            }
        }
        
        return errors
    }
    
    // MARK: - Navigation Methods
    
    /// Handles user selection of "I already have an account"
    /// 
    /// Transitions to login flow for existing users and tracks the selection for analytics.
    /// Existing users should not go through onboarding - they should be directed to login.
    ///
    /// - Returns: Void
    /// - SideEffects: Transitions to login flow and tracks analytics event
    /// - SeeAlso: `DATA_STANDARDS.md` §2.2 for onboarding flow requirements
    func selectIAlreadyHaveAccount() {
        print("OnboardingFlowViewModel: user selected 'I already have an account' - transitioning to login flow")
        
        // Track analytics before transitioning
        analyticsService.track(
            OnboardingAnalyticsEvent.loginSelected.rawValue,
            properties: [
                AnalyticsProperties.step: "login_selected",
                AnalyticsProperties.onboardingStep: currentStep.rawValue
            ],
            origin: "OnboardingFlowViewModel"
        )
        
        // Transition to login flow for existing users
        coordinator?.transitionToLogin()
    }
    
    /// Handles user selection of "Get Started"
    /// 
    /// Navigates to signup method selection and tracks the selection for analytics.
    ///
    /// - Returns: Void
    /// - SideEffects: Updates currentStep and tracks analytics event
    /// - SeeAlso: `DATA_STANDARDS.md` §2.2 for onboarding flow requirements
    func selectGetStarted() {
        print("OnboardingFlowViewModel: user selected 'Get Started'")
        currentStep = .signupMethod
        analyticsService.track(
            OnboardingAnalyticsEvent.signupSelected.rawValue,
            properties: [
                AnalyticsProperties.step: "signup_selected",
                AnalyticsProperties.onboardingStep: currentStep.rawValue
            ],
            origin: "OnboardingFlowViewModel"
        )
    }
    
    /// Handles user selection of anonymous signup
    /// 
    /// Creates anonymous user profile and navigates to profile creation.
    ///
    /// - Returns: Void
    /// - SideEffects: Creates user profile, updates currentStep, tracks analytics
    /// - SeeAlso: `DATA_STANDARDS.md` §2.3 for user profile requirements
    func selectAnonymous() {
        print("OnboardingFlowViewModel: user selected anonymous signup")
        Task {
            let result = await selectSignupMethod(.anonymous)
            print("OnboardingFlowViewModel: anonymous signup result: \(result)")
        }
    }
    
    /// Handles user selection of email signup
    /// 
    /// Creates email-based user profile and navigates to profile creation.
    ///
    /// - Returns: Void
    /// - SideEffects: Creates user profile, updates currentStep, tracks analytics
    /// - SeeAlso: `DATA_STANDARDS.md` §2.3 for user profile requirements
    func selectEmail() {
        print("OnboardingFlowViewModel: user selected email signup")
        Task {
            let result = await selectSignupMethod(.email)
            print("OnboardingFlowViewModel: email signup result: \(result)")
        }
    }
    
    /// Completes user info form and validates profile data
    /// 
    /// Validates the user information and proceeds to completion if valid.
    ///
    /// - Returns: Void
    /// - SideEffects: Validates data, updates validation errors, completes onboarding if valid
    /// - SeeAlso: `DATA_STANDARDS.md` §2.3 for user profile validation requirements
    func completeUserInfo() {
        print("OnboardingFlowViewModel: completing user info")
        
        // Convert UserInfo to UserProfileData for validation
        let profileData = UserProfileData(
            age: userInfo.age,
            gender: userInfo.gender
        )
        
        // Validate the profile data using the correct method
        let errors = validateProfileData(profileData)
        validationErrors = errors
        
        if errors.isEmpty {
            // Update the user profile with the new data
            updateUserProfileData(profileData)
            completeUserProfile()
        } else {
            print("OnboardingFlowViewModel: validation failed with \(errors.count) errors")
        }
    }

    enum OnboardingError: Error {
        case concurrentOperation
    }
}

// MARK: - UserInfo Model (local, for onboarding form binding)
/// UserInfo is a local struct for onboarding form state, mapped to UserProfile for persistence.
/// All fields must be defined in DATA_DICTIONARY.md and comply with DATA_STANDARDS.md §2.3.
struct UserInfo {
    var name: String = ""
    var age: Int = 0
    var gender: String = ""
}

// MARK: - AI Self-Audit
// - All onboarding steps and user profile fields are traceable to DATA_STANDARDS.md §2.2, §2.3, and DATA_DICTIONARY.md.
// - All user input is validated per DATA_STANDARDS.md §2.3.
// - All code is documented for AI self-audit per AI_GENERATION_RULES.md.
// - MVVM and dependency injection are used for testability (see CONTRIBUTING.md).
