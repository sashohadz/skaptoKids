//
//  WorkshopDetailView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI

struct WorkshopDetailView: View {
    let workshop: Workshop
    @Environment(\.dismiss) var dismiss
    @State private var showingBookingConfirmation = false
    @State private var showingSubscriptionRequired = false
    
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
        .alert("Membership Required", isPresented: $showingSubscriptionRequired) {
            Button("View Plans") {
                // Navigate to subscription view
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This workshop requires an active membership. Check out our plans to get started!")
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
            if workshop.requiresMembership && !revenueCatManager.currentSubscription.isActive {
                showingSubscriptionRequired = true
            } else if workshop.spotsAvailable > 0 {
                showingBookingConfirmation = true
            }
        } label: {
            HStack {
                Image(systemName: workshop.spotsAvailable > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                Text(workshop.spotsAvailable > 0 ? "Book This Workshop" : "Workshop Full")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(workshop.spotsAvailable > 0 ? workshopColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(workshop.spotsAvailable == 0)
        .padding(.top)
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
