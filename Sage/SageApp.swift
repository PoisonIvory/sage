//
//  SageApp.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import SwiftUI
import Firebase // DATA_STANDARDS.md §3.1
import Mixpanel
// Remove: import SageDesignSystem

// AppDelegate for Firebase Messaging and other UIApplicationDelegate needs
// Implements UIApplicationDelegate as required for Firebase integration (see DATA_STANDARDS.md §5.1)
class AppDelegate: NSObject, UIApplicationDelegate {
    // Add delegate methods here as needed (e.g., for push notifications)
}

// Directly use WelcomeView from DesignSystem folder
@main
struct SageApp: App {
    // Use UIApplicationDelegateAdaptor to bridge AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()

    enum LaunchScreen {
        case welcome, browse, signup, login, onboarding
    }
    @State private var screen: LaunchScreen = .welcome

    init() {
        FirebaseApp.configure() // DATA_STANDARDS.md §3.1, AI_GENERATION_RULES.md §2.2
        print("Firebase configured") // UI_STANDARDS.md §5.2
        Mixpanel.initialize(token: "9cc09c14ce1dd1002def610c46d338ed", trackAutomaticEvents: false)
        print("Mixpanel initialized with project token")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch screen {
                case .welcome:
                    WelcomeView(
                        onBrowse: {
                            print("SageApp: Navigating to ContentView (browse mode)")
                            screen = .browse
                        },
                        onBegin: {
                            print("SageApp: Navigating to SignUpView")
                            screen = .signup
                        },
                        onLogin: {
                            print("SageApp: Navigating to LoginView")
                            screen = .login
                        }
                    )
                    .onAppear { print("SageApp: WelcomeView is now visible") }
                case .browse:
                    ContentView()
                        .environmentObject(authViewModel)
                        .onAppear { print("SageApp: ContentView (browse mode) is now visible") }
                case .signup:
                    SignUpView(viewModel: authViewModel, onAuthenticated: {
                        print("SageApp: SignUpView onAuthenticated triggered")
                        // Check if user has any recordings
                        if AudioRecorder.shared.recordings.isEmpty {
                            print("SageApp: No recordings found, showing onboarding flow")
                            screen = .onboarding
                        } else {
                            print("SageApp: Recordings found, navigating to home")
                            screen = .browse
                        }
                    })
                        .onAppear { print("SageApp: SignUpView is now visible") }
                case .login:
                    LoginView(viewModel: authViewModel)
                        .onAppear { print("SageApp: LoginView is now visible") }
                case .onboarding:
                    FirstTimeOnboardingView(onComplete: {
                        print("SageApp: Onboarding complete, navigating to home")
                        AnalyticsService.shared.track(
                            "onboarding_successful",
                            properties: [
                                "source": "SageApp",
                                "event_version": 1
                            ]
                        )
                        screen = .browse
                    })
                    .onAppear { print("SageApp: FirstTimeOnboardingView is now visible") }
                }
            }
        }
    }
}
