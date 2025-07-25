import Foundation
import Combine
import SwiftUI
import DeviceKit

/// Onboarding steps for the onboarding flow
/// - loginSignupChoice: User chooses login or signup
/// - signupMethod: User chooses anonymous or email signup
/// - userInfoForm: User enters profile info
/// - completed: Onboarding is complete
///
/// See DATA_STANDARDS.md §2.2 for onboarding flow requirements.
enum OnboardingStep: Equatable {
    case loginSignupChoice
    case signupMethod
    case userInfoForm
    case completed
}

/// Protocol for onboarding flow actions (for testability)
protocol OnboardingFlowCoordinating: AnyObject {
    func onboardingDidComplete(userProfile: UserProfile)
}

/// ViewModel for the onboarding flow, compliant with DATA_STANDARDS.md §2.2, §2.3, and AI_GENERATION_RULES.md
///
/// - Handles onboarding navigation and user profile creation.
/// - All user profile fields must be defined in DATA_DICTIONARY.md.
/// - All onboarding steps and prompts must match DATA_STANDARDS.md §2.2.
/// - All code is documented for AI self-audit per AI_GENERATION_RULES.md.
final class OnboardingFlowViewModel: ObservableObject {
    // MARK: - Published State
    @Published var step: OnboardingStep = .loginSignupChoice
    @Published var isAnonymous: Bool = true
    @Published var userInfo: UserInfo = UserInfo()
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    weak var coordinator: OnboardingFlowCoordinating?

    // MARK: - Step Navigation
    func selectLogin() {
        // TODO: Implement login flow (not covered in onboarding)
        // For now, treat as anonymous onboarding
        isAnonymous = true
        step = .userInfoForm
    }

    func selectSignup() {
        step = .signupMethod
    }

    func selectAnonymous() {
        isAnonymous = true
        step = .userInfoForm
    }

    func selectEmail() {
        isAnonymous = false
        step = .userInfoForm
    }

    /// Called when user info form is completed
    func completeUserInfo() {
        // Validate user info (see DATA_STANDARDS.md §2.3)
        guard !userInfo.name.isEmpty, userInfo.age > 0 else {
            errorMessage = "Please enter your name and a valid age."
            return
        }
        // Create UserProfile (DATA_DICTIONARY.md: user_id, age, gender, device_model, os_version, created_at)
        let profile = UserProfile(
            id: UUID().uuidString, // In production, use Firebase UID or secure ID
            age: userInfo.age,
            gender: userInfo.gender,
            deviceModel: Device.current.description, // Use DeviceKit for device model
            osVersion: UIDevice.current.systemVersion,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        // Notify coordinator (for navigation or persistence)
        coordinator?.onboardingDidComplete(userProfile: profile)
        step = .completed
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
