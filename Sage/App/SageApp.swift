//
//  SageApp.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import SwiftUI
import Firebase // DATA_STANDARDS.md §3.1
import FirebaseAuth // Add explicit FirebaseAuth import
import FirebaseAppCheck // Added for App Check App Attest support
import Mixpanel
// Remove: import SageDesignSystem

// AppDelegate for Firebase Messaging and other UIApplicationDelegate needs
// Implements UIApplicationDelegate as required for Firebase integration (see DATA_STANDARDS.md §5.1)
class AppDelegate: NSObject, UIApplicationDelegate {
    // Add delegate methods here as needed (e.g., for push notifications)
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // App Check debug provider setup for development
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        print("AppCheck: Debug provider enabled for development")
        #endif
        
        FirebaseApp.configure()
        print("Firebase configured")

        // App Check App Attest provider setup for iOS 14+
        if #available(iOS 14.0, *) {
            print("AppCheck: Setting up App Attest provider for iOS 14+")
            let providerFactory = AppAttestProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            print("AppCheck: App Attest provider registered")
            AppCheck.appCheck().token(forcingRefresh: false) { token, error in
                if let error = error {
                    print("AppCheck: Token generation failed: \(error.localizedDescription)")
                    print("AppCheck: Error details: \(error)")
                } else if let token = token {
                    print("AppCheck: Token generated successfully: \(token.token)")
                    print("AppCheck: Token type: \(type(of: token))")
                } else {
                    print("AppCheck: Token generation returned nil")
                }
            }
        } else {
            print("AppCheck: iOS version < 14.0, App Attest not available")
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: didRegisterForRemoteNotificationsWithDeviceToken called")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// App Check App Attest provider factory
import FirebaseAppCheck
class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return nil
        }
    }
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
    @State private var currentScreen: LaunchScreen = .welcome

    init() {
        print("Firebase configured") // UI_STANDARDS.md §5.2
        Mixpanel.initialize(token: "9cc09c14ce1dd1002def610c46d338ed", trackAutomaticEvents: false)
        print("Mixpanel initialized with project token")
    }

    var body: some Scene {
        WindowGroup {
            screenForLaunchState()
                .onAppear {
                    setupFirebaseAuthListener()
                    checkAuthenticationState()
                }
                .onChange(of: authViewModel.state) { oldState, state in
                    if case .idle = state {
                        print("SageApp: User logged out, navigating to welcome")
                        currentScreen = .welcome
                    }
                    // Note: We don't automatically navigate to browse on authentication
                    // This is handled by the specific views (SignUpView, LoginView) 
                    // to allow for onboarding flow checks
                }
        }
    }
    
    private func setupFirebaseAuthListener() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("Firebase Auth State: User signed in - \(user.uid)")
            } else {
                print("Firebase Auth State: User signed out")
            }
        }
    }

    private func checkAuthenticationState() {
        print("SageApp: Checking authentication state")
        if case .authenticated = authViewModel.state {
            print("SageApp: User is already authenticated, checking for onboarding completion")
            // For now, always show onboarding for authenticated users
            // In production, this would check if user has completed onboarding
            if shouldShowOnboarding() {
                print("SageApp: Onboarding needed, showing onboarding flow")
                currentScreen = .onboarding
            } else {
                print("SageApp: Onboarding complete, navigating to home")
                currentScreen = .browse
            }
        } else {
            print("SageApp: User not authenticated, showing welcome screen")
            currentScreen = .welcome
        }
    }
    
    private func shouldShowOnboarding() -> Bool {
        // Check if user has completed onboarding in UserDefaults
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Debug: Print Firebase Auth state
        if let user = Auth.auth().currentUser {
            print("Firebase Auth: User logged in - \(user.uid)")
            print("Firebase Auth: Has completed onboarding: \(hasCompletedOnboarding)")
        } else {
            print("Firebase Auth: No user authenticated")
        }
        
        // For new users or users who haven't completed onboarding, show onboarding
        return !hasCompletedOnboarding
    }
    
    // MARK: - Debug Helper Methods
    
    /// Resets onboarding completion flag for testing purposes
    /// Call this method to force onboarding to show again
    private func resetOnboardingCompletion() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        print("SageApp: Onboarding completion flag reset")
    }

    @ViewBuilder
    private func screenForLaunchState() -> some View {
        switch currentScreen {
        case .welcome:
            WelcomeView(
                onBrowse: {
                    print("SageApp: Navigating to ContentView (browse mode)")
                    currentScreen = .browse
                },
                onBegin: {
                    print("SageApp: Navigating to SignUpView")
                    currentScreen = .signup
                },
                onLogin: {
                    print("SageApp: Navigating to LoginView")
                    currentScreen = .login
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
                if shouldShowOnboarding() {
                    print("SageApp: Onboarding needed, showing onboarding flow")
                    currentScreen = .onboarding
                } else {
                    print("SageApp: Onboarding complete, navigating to home")
                    currentScreen = .browse
                }
            })
            .onAppear { print("SageApp: SignUpView is now visible") }
        case .login:
            LoginView(viewModel: authViewModel, onAuthenticated: {
                print("SageApp: LoginView onAuthenticated triggered")
                if shouldShowOnboarding() {
                    print("SageApp: Onboarding needed, showing onboarding flow")
                    currentScreen = .onboarding
                } else {
                    print("SageApp: Onboarding complete, navigating to home")
                    currentScreen = .browse
                }
            })
            .onAppear { print("SageApp: LoginView is now visible") }
        case .onboarding:
            OnboardingJourneyView(
                analyticsService: AnalyticsService.shared,
                authService: AuthService(),
                userProfileRepository: UserProfileRepository(),
                microphonePermissionManager: MicrophonePermissionManager(),
                vocalAnalysisService: HybridVocalAnalysisService(),
                coordinator: nil,
                dateProvider: SystemDateProvider(),
                onComplete: {
                    print("SageApp: Onboarding complete, navigating to home")
                    currentScreen = .browse
                }
            )
            .onAppear {
                print("SageApp: OnboardingJourneyView is now visible")
            }
        }
    }
}
