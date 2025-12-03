//
//  WorkshopDetailView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct WorkshopDetailView: View {
    let workshop: Workshop
    @Environment(\.dismiss) var dismiss
    @State private var showingBookingConfirmation = false
    @State private var displayPaywall = false
    
    var revenueCatManager = RevenueCatManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Date & Time
                dateTimeSection
                
                Divider()
                
                // Description
                descriptionSection
                
                Divider()
                
                // Details
                detailsSection
                
                Divider()
                
                // Instructor
                instructorSection
                
                // Booking Button
                bookingButton
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Workshop Booked!", isPresented: $showingBookingConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("You're all set for \(workshop.title)! See you there!")
        }
        .sheet(isPresented: $displayPaywall) {
            RevenueCatUI.PaywallView()
                .onPurchaseCompleted { customerInfo in
                    // Purchase completed successfully
                    print("🎯 Purchase completed in WorkshopDetailView")
                    Task {
                        // Check what was purchased and track it
                        if customerInfo.entitlements["singleVisit"]?.isActive == true {
                            print("🎫 Single visit pass detected, tracking purchase...")
                            await revenueCatManager.incrementDailyPassesCount()
                        }
                        
                        await revenueCatManager.checkSubscriptionStatus()
                        // After subscription is updated, book the workshop
                        if revenueCatManager.currentSubscription.isActive {
                            displayPaywall = false
                            showingBookingConfirmation = true
                        }
                    }
                }
                .onRestoreCompleted { customerInfo in
                    // Restore completed
                    Task {
                        await revenueCatManager.checkSubscriptionStatus()
                        displayPaywall = false
                    }
                }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(workshopColor.gradient)
                    .frame(width: 100, height: 100)
                
                Image(systemName: workshop.imageName)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            
            Text(workshop.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(workshopColor)
                Text(workshop.date.formatted(date: .long, time: .omitted))
                    .font(.body)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(workshopColor)
                Text(workshop.timeString)
                    .font(.body)
                Text("(\(workshop.duration) minutes)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(workshop.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            DetailRow(icon: "person.2.fill", title: "Age Range", value: workshop.ageRange)
            DetailRow(icon: "number", title: "Class Size", value: "Max \(workshop.maxParticipants) participants")
            DetailRow(icon: "checkmark.circle.fill", title: "Available Spots", value: "\(workshop.spotsAvailable)", valueColor: workshop.spotsAvailable < 3 ? .orange : .green)
            
            if workshop.requiresMembership {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Membership Required")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var instructorSection: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(workshopColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(workshop.instructor)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var bookingButton: some View {
        Button {
            // Check if there are spots available
            guard workshop.spotsAvailable > 0 else { return }
            
            // Check if user has access to book
            if revenueCatManager.canBookWorkshop() {
                // User has access - book the workshop
                bookWorkshop()
            } else {
                // User doesn't have access - show paywall
                displayPaywall = true
            }
        } label: {
            HStack {
                Image(systemName: workshop.spotsAvailable > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                Text(bookingButtonText)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(bookingButtonColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canBook)
        .padding(.top)
    }
    
    private var bookingButtonText: String {
        if workshop.spotsAvailable == 0 {
            return "Workshop Full"
        } else if !revenueCatManager.canBookWorkshop() && workshop.requiresMembership {
            return "Get Access to Book"
        } else {
            return "Book This Workshop"
        }
    }
    
    private var bookingButtonColor: Color {
        if workshop.spotsAvailable == 0 {
            return .gray
        } else if !revenueCatManager.canBookWorkshop() && workshop.requiresMembership {
            return .blue
        } else {
            return workshopColor
        }
    }
    
    private var canBook: Bool {
        workshop.spotsAvailable > 0
    }
    
    private func bookWorkshop() {
        Task {
            // If user has a single visit pass, consume it
            if revenueCatManager.currentSubscription.type == .oneTime {
                await revenueCatManager.consumeSingleVisitPass()
            }
            
            // Show booking confirmation
            showingBookingConfirmation = true
        }
    }
    
    private var workshopColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo]
        return colors[abs(workshop.id.hashValue) % colors.count]
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        WorkshopDetailView(workshop: Workshop(
            id: UUID(),
            title: "Creative Painting",
            description: "Express yourself through colors and imagination",
            imageName: "paintbrush.fill",
            ageRange: "5-8 years",
            duration: 90,
            instructor: "Maria Thompson",
            date: Date(),
            maxParticipants: 12,
            spotsAvailable: 5,
            requiresMembership: false
        ))
    }
}
