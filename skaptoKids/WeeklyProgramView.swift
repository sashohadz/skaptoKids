//
//  WeeklyProgramView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI

struct WeeklyProgramView: View {
    @State private var viewModel = WorkshopViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week Navigation
                    weekNavigationBar
                    
                    // Workshops by Day
                    if viewModel.workshopsThisWeek.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(sortedDays, id: \.self) { day in
                            if let workshops = viewModel.workshopsByDay[day] {
                                DaySection(day: day, workshops: workshops)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Workshop Program")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var weekNavigationBar: some View {
        HStack {
            Button {
                viewModel.selectedWeekOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .disabled(viewModel.selectedWeekOffset <= 0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(viewModel.weekTitle)
                    .font(.headline)
                Text("\(viewModel.currentWeekStart.formatted(date: .abbreviated, time: .omitted)) - \(viewModel.currentWeekEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                viewModel.selectedWeekOffset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .disabled(viewModel.selectedWeekOffset >= 2)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Workshops Scheduled")
                .font(.headline)
            Text("Check back later for upcoming workshops")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var sortedDays: [String] {
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return weekdays.filter { viewModel.workshopsByDay.keys.contains($0) }
    }
}

struct DaySection: View {
    let day: String
    let workshops: [Workshop]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            ForEach(workshops) { workshop in
                NavigationLink {
                    WorkshopDetailView(workshop: workshop)
                } label: {
                    WorkshopCard(workshop: workshop)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct WorkshopCard: View {
    let workshop: Workshop
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForWorkshop.gradient)
                    .frame(width: 60, height: 60)
                
                Image(systemName: workshop.imageName)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(workshop.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label(workshop.timeString, systemImage: "clock")
                    Text("•")
                    Label("\(workshop.duration) min", systemImage: "hourglass")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                HStack {
                    Label(workshop.ageRange, systemImage: "person.2")
                    Spacer()
                    if workshop.spotsAvailable > 0 {
                        Text("\(workshop.spotsAvailable) spots left")
                            .font(.caption)
                            .foregroundStyle(workshop.spotsAvailable < 3 ? .orange : .green)
                    } else {
                        Text("Full")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var colorForWorkshop: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo]
        return colors[abs(workshop.id.hashValue) % colors.count]
    }
}

#Preview {
    WeeklyProgramView()
}
