//
//  SageApp.swift
//  Sage
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import SwiftUI

@main
struct SageApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
