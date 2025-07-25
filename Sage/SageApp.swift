//
//  SageApp.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import SwiftUI
import Firebase // DATA_STANDARDS.md §3.1

@main
struct SageApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure() // DATA_STANDARDS.md §3.1, AI_GENERATION_RULES.md §2.2
        print("Firebase configured") // UI_STANDARDS.md §5.2
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    AuthChoiceView()
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                print("SageApp: App launched")
            }
        }
    }
}
