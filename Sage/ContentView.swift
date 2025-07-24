//
//  ContentView.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            Text("Home Page Placeholder")
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

            // Sessions Tab
            Text("Sessions Page Placeholder")
                .tabItem {
                    Image(systemName: "clock")
                    Text("Sessions")
                }
                .tag(1)

            // Profile Tab
            Text("Profile Page Placeholder")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import FirebaseAuth

struct LoginSignupChoiceView: View {
    var onChoice: (Bool) -> Void // true = signup, false = login

    var body: some View {
        VStack(spacing: 32) {
            Text("Welcome to Sage")
                .font(.largeTitle)
                .padding(.top, 60)
            Text("Sign up or log in to get started.")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("Sign Up") {
                onChoice(true)
            }
            .buttonStyle(.borderedProminent)
            Button("Log In") {
                // For demo, treat as sign up; in real app, present login form
                onChoice(false)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }
}

import SwiftUI
import FirebaseAuth

struct SignupMethodView: View {
    var onSignedUp: (String) -> Void // Passes userId

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Sign Up Method")
                .font(.title2)
                .padding(.top, 40)
            Button("Continue Anonymously") {
                Auth.auth().signInAnonymously { result, error in
                    if let user = result?.user {
                        onSignedUp(user.uid)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            EmailSignupView(onSignedUp: onSignedUp)
            Spacer()
        }
        .padding()
    }
}

struct EmailSignupView: View {
    var onSignedUp: (String) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button("Sign Up with Email") {
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let user = result?.user {
                        onSignedUp(user.uid)
                    } else if let error = error {
                        self.error = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

import SwiftUI
import FirebaseFirestore

struct UserInfoFormView: View {
    let userId: String
    var onComplete: () -> Void

    @State private var name = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title2)
                .padding(.top, 40)
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            TextField("Gender", text: $gender)
                .textFieldStyle(.roundedBorder)
            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button(isSaving ? "Saving..." : "Continue") {
                saveUserInfo()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
            Spacer()
        }
        .padding()
    }

    func saveUserInfo() {
        guard !name.isEmpty, let ageInt = Int(age), !gender.isEmpty else {
            error = "Please fill out all fields."
            return
        }
        isSaving = true
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "name": name,
            "age": ageInt,
            "gender": gender
        ]) { err in
            isSaving = false
            if let err = err {
                error = "Failed to save: \(err.localizedDescription)"
            } else {
                onComplete()
            }
        }
    }
}

import SwiftUI

enum OnboardingStep {
    case loginSignupChoice
    case signupMethod
    case userInfoForm(userId: String)
    case home
}

struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .loginSignupChoice
    @State private var userId: String? = nil

    var body: some View {
        switch step {
        case .loginSignupChoice:
            LoginSignupChoiceView { isSignup in
                step = isSignup ? .signupMethod : .loginSignupChoice // Will be replaced by login logic
            }
        case .signupMethod:
            SignupMethodView { userId in
                self.userId = userId
                step = .userInfoForm(userId: userId)
            }
        case .userInfoForm(let userId):
            UserInfoFormView(userId: userId) {
                step = .home
            }
        case .home:
            ContentView()
        }
    }
}

import SwiftUI

struct SageColors {
    static let earthClay = Color("EarthClay") // #C3A18D
    static let sandstone = Color("Sandstone") // #E6CFBB
    static let cinnamonBark = Color("CinnamonBark") // #8B5A3C
    static let coralBlush = Color("CoralBlush") // #D99C7A
    static let sageTeal = Color("SageTeal") // #6CA59E
    static let fogWhite = Color("FogWhite") // #F5EEE7
    static let softTaupe = Color("SoftTaupe") // #B8A396
    static let espressoBrown = Color("EspressoBrown") // #3E2B25
}
