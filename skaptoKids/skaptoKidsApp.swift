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
        // API key is stored in Config.swift (not committed to git)
        RevenueCatManager.shared.configure(apiKey: Config.revenueCatAPIKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
