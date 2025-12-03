//
//  ProfileView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI

struct ProfileView: View {
    var revenueCatManager = RevenueCatManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Parent Account")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(revenueCatManager.currentSubscription.statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Subscription Section
                Section("Membership") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Manage Subscription")
                        }
                    }
                    
                    if revenueCatManager.currentSubscription.isActive,
                       let expirationDate = revenueCatManager.currentSubscription.expirationDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expires")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(expirationDate.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                        }
                    }
                }
                
                // Bookings Section
                Section("My Bookings") {
                    NavigationLink {
                        BookingsView()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundStyle(.green)
                            Text("Upcoming Workshops")
                        }
                    }
                    
                    NavigationLink {
                        BookingHistoryView()
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.blue)
                            Text("Booking History")
                        }
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.orange)
                            Text("Notifications")
                        }
                    }
                    
                    Link(destination: URL(string: "https://your-website.com/support")!) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.purple)
                            Text("Help & Support")
                        }
                    }
                    
                    Link(destination: URL(string: "https://your-website.com/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.blue)
                            Text("Privacy Policy")
                        }
                    }
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Placeholder Views
struct BookingsView: View {
    var body: some View {
        List {
            Text("No upcoming workshops")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Upcoming Workshops")
    }
}

struct BookingHistoryView: View {
    var body: some View {
        List {
            Text("No booking history")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Booking History")
    }
}

struct NotificationSettingsView: View {
    @State private var workshopReminders = true
    @State private var weeklyUpdates = false
    @State private var specialOffers = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Workshop Reminders", isOn: $workshopReminders)
                Toggle("Weekly Updates", isOn: $weeklyUpdates)
                Toggle("Special Offers", isOn: $specialOffers)
            }
            
            Section {
                Text("We'll send you important updates about your bookings and membership.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notifications")
    }
}

#Preview {
    ProfileView()
}
