//
//  Models.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import Foundation

// MARK: - Workshop Model
struct Workshop: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let imageName: String
    let ageRange: String
    let duration: Int // minutes
    let instructor: String
    let date: Date
    let maxParticipants: Int
    let spotsAvailable: Int
    let requiresMembership: Bool
    
    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }
    
    var timeString: String {
        date.formatted(date: .omitted, time: .shortened)
    }
    
    var dateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Subscription Type
enum SubscriptionType: String, CaseIterable {
    case monthly = "Monthly Membership"
    case oneTime = "Single Visit Pass"
    
    var description: String {
        switch self {
        case .monthly:
            return "Unlimited access to all workshops for one month"
        case .oneTime:
            return "Access to any single workshop"
        }
    }
    
    var benefits: [String] {
        switch self {
        case .monthly:
            return [
                "Unlimited workshop access",
                "Priority booking",
                "10% discount on materials",
                "Special events access",
                "Cancel anytime"
            ]
        case .oneTime:
            return [
                "Access to one workshop",
                "All materials included",
                "No commitment",
                "Valid for 30 days"
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .monthly:
            return "calendar.badge.plus"
        case .oneTime:
            return "ticket.fill"
        }
    }
}

// MARK: - User Subscription Status
struct UserSubscription {
    var isActive: Bool
    var type: SubscriptionType?
    var expirationDate: Date?
    var remainingVisits: Int // For one-time passes
    
    var statusText: String {
        if isActive, let type = type {
            switch type {
            case .monthly:
                return "Active Member"
            case .oneTime:
                return "\(remainingVisits) visit\(remainingVisits == 1 ? "" : "s") remaining"
            }
        } else {
            return "No Active Subscription"
        }
    }
}
