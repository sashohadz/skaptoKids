//
//  ContentView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    var revenueCatManager = RevenueCatManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyProgramView()
                .tabItem {
                    Label("Workshops", systemImage: "calendar")
                }
                .tag(0)
            
            SubscriptionView()
                .tabItem {
                    Label("Membership", systemImage: "star.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
