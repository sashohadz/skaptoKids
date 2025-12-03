//
//  RevenueCatManager.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import Foundation
import RevenueCat

@MainActor
@Observable
class RevenueCatManager {
    static let shared = RevenueCatManager()
    
    var currentSubscription: UserSubscription = UserSubscription(
        isActive: false,
        type: nil,
        expirationDate: nil,
        remainingVisits: 0
    )
    
    var availablePackages: [Package] = []
    var isLoading = false
    var errorMessage: String?
    
    private init() {}
    
    // MARK: - Configuration
    func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        Task {
            await checkSubscriptionStatus()
            await loadOfferings()
        }
    }
    
    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            errorMessage = "Failed to check subscription: \(error.localizedDescription)"
            print("Error checking subscription: \(error)")
        }
    }
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        // Check for monthly subscription
        if customerInfo.entitlements["monthly_membership"]?.isActive == true {
            currentSubscription = UserSubscription(
                isActive: true,
                type: .monthly,
                expirationDate: customerInfo.entitlements["monthly_membership"]?.expirationDate,
                remainingVisits: 0
            )
        }
        // Check for one-time pass
        else if customerInfo.entitlements["single_visit"]?.isActive == true {
            // In a real app, you'd track remaining visits in your backend
            currentSubscription = UserSubscription(
                isActive: true,
                type: .oneTime,
                expirationDate: customerInfo.entitlements["single_visit"]?.expirationDate,
                remainingVisits: 1
            )
        }
        else {
            currentSubscription = UserSubscription(
                isActive: false,
                type: nil,
                expirationDate: nil,
                remainingVisits: 0
            )
        }
    }
    
    // MARK: - Load Offerings
    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            if let currentOffering = offerings.current {
                availablePackages = currentOffering.availablePackages
            }
        } catch {
            errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            print("Error loading offerings: \(error)")
        }
    }
    
    // MARK: - Purchase
    func purchase(package: Package) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            updateSubscriptionStatus(from: result.customerInfo)
            return true
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("Error purchasing: \(error)")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(from: customerInfo)
            return true
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            print("Error restoring: \(error)")
            return false
        }
    }
}
