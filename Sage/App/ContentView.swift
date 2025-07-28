//
//  ContentView.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import Mixpanel
import SwiftUI
// Removed: import Features_Dashboard_Views
// VoiceDashboardView is in the same target/module, so no explicit import is needed.

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

            // Sessions Tab
            SessionsView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Sessions")
                }
                .tag(1)

            // Dashboard Tab
            VoiceDashboardView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Dashboard")
                }
                .tag(2)
                .onAppear {
                    print("ContentView: Dashboard tab appeared")
                }

            // Profile Tab
            ProfilePagePlaceholderView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .onAppear {
            print("ContentView: appeared")
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            print("ContentView: selectedTab changed to \(newValue)")
            switch newValue {
            case 0: print("ContentView: Home tab selected")
            case 1: print("ContentView: Sessions tab selected")
            case 2: print("ContentView: Dashboard tab selected")
            case 3: print("ContentView: Profile tab selected")
            default: print("ContentView: Unknown tab selected")
            }
        }
    }
}

#Preview {
    ContentView()
}

