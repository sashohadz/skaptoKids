//
//  WorkshopViewModel.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import Foundation

@MainActor
@Observable
class WorkshopViewModel {
    var workshops: [Workshop] = []
    var selectedWeekOffset: Int = 0 // 0 = current week, 1 = next week, etc.
    
    init() {
        loadWorkshops()
    }
    
    var currentWeekStart: Date {
        Calendar.current.date(
            byAdding: .weekOfYear,
            value: selectedWeekOffset,
            to: Date().startOfWeek
        ) ?? Date()
    }
    
    var currentWeekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? Date()
    }
    
    var weekTitle: String {
        if selectedWeekOffset == 0 {
            return "This Week"
        } else if selectedWeekOffset == 1 {
            return "Next Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: currentWeekEnd))"
        }
    }
    
    var workshopsThisWeek: [Workshop] {
        workshops.filter { workshop in
            workshop.date >= currentWeekStart && workshop.date <= currentWeekEnd
        }.sorted { $0.date < $1.date }
    }
    
    var workshopsByDay: [String: [Workshop]] {
        Dictionary(grouping: workshopsThisWeek) { $0.dayOfWeek }
    }
    
    func loadWorkshops() {
        // In a real app, this would load from your backend
        workshops = generateSampleWorkshops()
    }
    
    func bookWorkshop(_ workshop: Workshop) {
        // Implement booking logic with your backend
        print("Booking workshop: \(workshop.title)")
    }
    
    // MARK: - Sample Data
    private func generateSampleWorkshops() -> [Workshop] {
        let today = Date()
        let calendar = Calendar.current
        
        let workshopTemplates: [(title: String, description: String, age: String, duration: Int, instructor: String, image: String)] = [
            ("Creative Painting", "Express yourself through colors and imagination", "5-8 years", 90, "Maria Thompson", "paintbrush.fill"),
            ("Robotics Basics", "Build and program your first robot", "8-12 years", 120, "John Smith", "cpu.fill"),
            ("Music & Movement", "Dance, rhythm, and musical exploration", "3-6 years", 60, "Sarah Johnson", "music.note"),
            ("Science Experiments", "Hands-on chemistry and physics fun", "7-10 years", 90, "Dr. Alex Chen", "flask.fill"),
            ("Storytelling & Drama", "Create and perform your own stories", "6-9 years", 75, "Emma Davis", "theatermasks.fill"),
            ("Cooking Class", "Make delicious and healthy snacks", "5-10 years", 90, "Chef Marco", "fork.knife"),
            ("Yoga for Kids", "Mindfulness and gentle movement", "4-8 years", 45, "Lisa Brown", "figure.mind.and.body"),
            ("Clay Sculpting", "Shape and create with clay", "6-11 years", 90, "David Lee", "cube.fill")
        ]
        
        var workshops: [Workshop] = []
        
        // Generate workshops for the next 3 weeks
        for weekOffset in 0...2 {
            for dayOffset in 1...5 { // Monday to Friday
                guard let workshopDate = calendar.date(
                    byAdding: .day,
                    value: dayOffset + (weekOffset * 7),
                    to: today.startOfWeek
                ) else { continue }
                
                // 2-3 workshops per day
                let workshopsPerDay = Int.random(in: 2...3)
                for slot in 0..<workshopsPerDay {
                    let template = workshopTemplates[Int.random(in: 0..<workshopTemplates.count)]
                    let hour = 10 + (slot * 3) // 10 AM, 1 PM, 4 PM
                    
                    guard let date = calendar.date(
                        bySettingHour: hour,
                        minute: 0,
                        second: 0,
                        of: workshopDate
                    ) else { continue }
                    
                    let maxParticipants = Int.random(in: 8...15)
                    let spotsAvailable = Int.random(in: 0...maxParticipants)
                    
                    workshops.append(Workshop(
                        id: UUID(),
                        title: template.title,
                        description: template.description,
                        imageName: template.image,
                        ageRange: template.age,
                        duration: template.duration,
                        instructor: template.instructor,
                        date: date,
                        maxParticipants: maxParticipants,
                        spotsAvailable: spotsAvailable,
                        requiresMembership: Bool.random()
                    ))
                }
            }
        }
        
        return workshops.sorted { $0.date < $1.date }
    }
}

// MARK: - Date Extension
extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}
