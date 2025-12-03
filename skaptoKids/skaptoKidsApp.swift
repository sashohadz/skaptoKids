//
//  skaptoKidsApp.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI

@main
struct skaptoKidsApp: App {
    init() {
        // Configure RevenueCat with your API key
        // Replace this with your actual RevenueCat API key from the dashboard
        RevenueCatManager.shared.configure(apiKey: "test_BrQgDaXblzSOTGXGcUfOFUIAgXD")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
