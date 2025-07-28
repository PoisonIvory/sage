import Foundation
import Combine
import FirebaseAuth
import os.log

// MARK: - Error Constants
enum AuthError: String, CaseIterable {
    case invalidEmail = "Invalid email"
    case invalidPassword = "Invalid password"
    
    var message: String {
        return self.rawValue
    }
}

// MARK: - Auth State Enum
enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(signUpMethod: String)
    case failed(error: String)
}

// MARK: - Auth Protocol
protocol AuthProtocol {
    var currentUser: User? { get }
    func signOut() throws
    func signInAnonymously(completion: @escaping (AuthDataResult?, Error?) -> Void)
    func signUpWithEmail(email: String, password: String, completion: @escaping (Bool, Error?) -> Void)
}

// MARK: - Firebase Auth Service
class FirebaseAuthService: AuthProtocol {
    private let auth = Auth.auth()
    var currentUser: User? { auth.currentUser }
    func signOut() throws { try auth.signOut() }
    func signInAnonymously(completion: @escaping (AuthDataResult?, Error?) -> Void) {
        auth.signInAnonymously(completion: completion)
    }
    func signUpWithEmail(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            completion(result != nil, error)
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var state: AuthState = .idle
    @Published var signUpMethod: String? // "anonymous" or "email"
    @Published var shouldShowRetryOption: Bool = false
    @Published var canWorkOffline: Bool = false

    private let auth: AuthProtocol
    private var hasExplicitlySignedOut: Bool = false

    init(disableAutoAuth: Bool = false, auth: AuthProtocol = FirebaseAuthService()) {
        self.auth = auth
        os_log("AuthViewModel: Initializing")
        if !disableAutoAuth && !hasExplicitlySignedOut {
            checkExistingAuthentication()
        }
    }

    // MARK: - Computed Properties for Tests
    var isAuthenticated: Bool {
        if case .authenticated = state {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failed(let error) = state {
            return error
        }
        return nil
    }

    // MARK: - Email/Password Auth
    func signUpWithEmail() {
        clearSignOutFlag() // Clear flag when user explicitly signs up
        os_log("AuthViewModel: Attempting sign up with email: %{public}@", email)
        guard isEmailValid, isPasswordValid else {
            if !isEmailValid {
                state = .failed(error: AuthError.invalidEmail.message)
            } else if !isPasswordValid {
                state = .failed(error: AuthError.invalidPassword.message)
            }
            os_log("AuthViewModel: Invalid email or password")
            return
        }
        state = .loading
        auth.signUpWithEmail(email: email, password: password) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.state = .failed(error: error.localizedDescription)
                    os_log("AuthViewModel: Sign up failed: %{public}@", error.localizedDescription)
                } else if success {
                    self?.handleAuthenticationSuccess(signUpMethod: "email")
                } else {
                    self?.state = .failed(error: "Unknown error during sign up")
                }
            }
        }
    }

    func loginWithEmail() {
        clearSignOutFlag() // Clear flag when user explicitly logs in
        os_log("AuthViewModel: Attempting login with email: %{public}@", email)
        guard isEmailValid, isPasswordValid else {
            if !isEmailValid {
                state = .failed(error: AuthError.invalidEmail.message)
            } else if !isPasswordValid {
                state = .failed(error: AuthError.invalidPassword.message)
            }
            os_log("AuthViewModel: Invalid email or password")
            return
        }
        state = .loading
        // Login logic extraction to service to be implemented
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.state = .authenticated(signUpMethod: "email")
            self.signUpMethod = "email"
            os_log("AuthViewModel: Login successful, isAuthenticated=true")
        }
    }

    // MARK: - Anonymous Auth
    func signInAnonymously() {
        clearSignOutFlag() // Clear flag when user explicitly signs in anonymously
        os_log("AuthViewModel: Attempting anonymous sign in")
        state = .loading
        auth.signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.state = .failed(error: error.localizedDescription)
                    os_log("AuthViewModel: Anonymous sign in failed: %{public}@", error.localizedDescription)
                } else {
                    self?.handleAuthenticationSuccess(signUpMethod: "anonymous")
                }
            }
        }
    }

    func retryAnonymousSignIn() {
        os_log("AuthViewModel: Retrying anonymous sign in")
        shouldShowRetryOption = false
        signInAnonymously()
    }

    // MARK: - Persistent Authentication
    func checkExistingAuthentication() {
        os_log("AuthViewModel: Checking for existing user session, hasExplicitlySignedOut=%{public}@", hasExplicitlySignedOut ? "true" : "false")
        if hasExplicitlySignedOut {
            os_log("AuthViewModel: Skipping auto-authentication due to explicit sign out")
            self.state = .idle
            return
        }
        
        if let currentUser = auth.currentUser {
            os_log("AuthViewModel: Found existing user session with UID: %{public}@", currentUser.uid)
            if currentUser.isAnonymous {
                self.state = .authenticated(signUpMethod: "anonymous")
                self.signUpMethod = "anonymous"
                os_log("AuthViewModel: Auto-authenticated anonymous user session")
            } else {
                self.state = .authenticated(signUpMethod: "email")
                self.signUpMethod = "email"
                os_log("AuthViewModel: Auto-authenticated email user session")
            }
        } else {
            os_log("AuthViewModel: No existing user session found")
            self.state = .idle
        }
    }

    // MARK: - Sign Out
    /// Signs out the current user and resets authentication state
    /// If signOut fails, state is not reset to avoid hiding errors. Documented for clarity.
    func signOut() {
        do {
            try auth.signOut()
            hasExplicitlySignedOut = true
            reset()
            state = .idle
            os_log("AuthViewModel: User signed out and state reset")
        } catch {
            state = .failed(error: "Failed to sign out: \(error.localizedDescription)")
            os_log("AuthViewModel: Sign out failed: %{public}@", error.localizedDescription)
        }
    }

    // MARK: - Helper Methods
    private func clearSignOutFlag() {
        hasExplicitlySignedOut = false
        os_log("AuthViewModel: Sign out flag cleared - user explicitly signing in")
    }

    private func handleAuthenticationSuccess(signUpMethod: String) {
        hasExplicitlySignedOut = false // Clear the flag when user explicitly signs in
        state = .authenticated(signUpMethod: signUpMethod)
        self.signUpMethod = signUpMethod
        shouldShowRetryOption = false
        canWorkOffline = false
        os_log("AuthViewModel: Authentication successful, method=%{public}@", signUpMethod)
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
        shouldShowRetryOption = false
        canWorkOffline = false
        signUpMethod = nil
        // Don't clear hasExplicitlySignedOut here - it should persist until user explicitly signs in
        os_log("AuthViewModel: Reset called")
    }
} 