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
            SessionsView()
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
        .onAppear {
            print("ContentView: appeared")
        }
        .onChange(of: selectedTab) { newValue in
            print("ContentView: selectedTab changed to \(newValue)")
        }
    }
}

#Preview {
    ContentView()
}

