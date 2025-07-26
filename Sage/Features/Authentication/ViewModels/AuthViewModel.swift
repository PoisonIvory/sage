import Foundation
import Combine
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var signUpMethod: String? // "anonymous" or "email"
    @Published var shouldShowRetryOption: Bool = false
    @Published var canWorkOffline: Bool = false

    init() {
        print("AuthViewModel: Initializing")
        checkExistingAuthentication()
    }

    // MARK: - Email/Password Auth
    func signUpWithEmail() {
        print("AuthViewModel: Sign Up button tapped with email=\(email)")
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            print("AuthViewModel: Invalid email or password")
            return
        }
        isLoading = true
        // Replace with Firebase Auth or your AuthManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.handleAuthenticationSuccess(signUpMethod: "email")
        }
    }

    func loginWithEmail() {
        print("AuthViewModel: Login button tapped with email=\(email)")
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            print("AuthViewModel: Invalid email or password")
            return
        }
        isLoading = true
        // Replace with Firebase Auth or your AuthManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.isAuthenticated = true
            self.errorMessage = nil
            print("AuthViewModel: Login successful, isAuthenticated=\(self.isAuthenticated)")
        }
    }

    // MARK: - Anonymous Auth
    func signInAnonymously() {
        print("AuthViewModel: Continue Anonymously button tapped")
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.handleAuthenticationFailure(error: error)
                } else {
                    self?.handleAuthenticationSuccess(signUpMethod: "anonymous")
                }
            }
        }
    }

    func retryAnonymousSignIn() {
        print("AuthViewModel: Retrying anonymous sign in")
        shouldShowRetryOption = false
        signInAnonymously()
    }

    // MARK: - Persistent Authentication
    /// Checks if there's an existing user session and automatically authenticates them
    func checkExistingAuthentication() {
        print("AuthViewModel: Checking for existing user session")
        
        if let currentUser = Auth.auth().currentUser {
            print("AuthViewModel: Found existing user session with UID: \(currentUser.uid)")
            
            if currentUser.isAnonymous {
                print("AuthViewModel: Existing user session is anonymous, auto-authenticating")
                self.isAuthenticated = true
                self.signUpMethod = "anonymous"
                print("AuthViewModel: Auto-authenticated anonymous user session")
            } else {
                print("AuthViewModel: Existing user session is email-based, auto-authenticating")
                self.isAuthenticated = true
                self.signUpMethod = "email"
                print("AuthViewModel: Auto-authenticated email user session")
            }
        } else {
            print("AuthViewModel: No existing user session found")
        }
    }

    /// Checks if there's an existing anonymous user session (for testing)
    func hasExistingAnonymousUser() -> Bool {
        if let currentUser = Auth.auth().currentUser {
            return currentUser.isAnonymous
        }
        return false
    }

    /// Checks if there's an existing email user session (for testing)
    func hasExistingEmailUser() -> Bool {
        if let currentUser = Auth.auth().currentUser {
            return !currentUser.isAnonymous
        }
        return false
    }

    // MARK: - Helper Methods
    private func handleAuthenticationSuccess(signUpMethod: String) {
        isAuthenticated = true
        errorMessage = nil
        self.signUpMethod = signUpMethod
        shouldShowRetryOption = false
        canWorkOffline = false
        print("AuthViewModel: Authentication successful, method=\(signUpMethod)")
    }

    private func handleAuthenticationFailure(error: Error) {
        isAuthenticated = false
        errorMessage = "We're having trouble connecting to your account. Your voice recordings won't be saved to track your progress over time. You can try again or continue using the app for now."
        signUpMethod = nil
        shouldShowRetryOption = true
        canWorkOffline = true
        print("AuthViewModel: Authentication failed: \(error)")
    }

    // MARK: - Validation
    var isEmailValid: Bool {
        let emailRegEx = "(?:[a-zA-Z0-9_'^&/+-])+(?:\\.(?:[a-zA-Z0-9_'^&/+-])+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }

    func reset() {
        email = ""
        password = ""
        errorMessage = nil
        isLoading = false
        isAuthenticated = false
        signUpMethod = nil
        shouldShowRetryOption = false
        canWorkOffline = false
        print("AuthViewModel: Reset called")
    }
} 