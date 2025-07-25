import Foundation
import Combine
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false

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
            self.isAuthenticated = true
            self.errorMessage = nil
            print("AuthViewModel: Sign up successful, isAuthenticated=\(self.isAuthenticated)")
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
                    self?.errorMessage = error.localizedDescription
                    print("AuthViewModel: Anonymous sign in failed: \(error)")
                } else {
                    self?.isAuthenticated = true
                    self?.errorMessage = nil
                    print("AuthViewModel: Anonymous sign in successful, isAuthenticated=\(self?.isAuthenticated ?? false)")
                }
            }
        }
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
        print("AuthViewModel: Reset called")
    }
} 