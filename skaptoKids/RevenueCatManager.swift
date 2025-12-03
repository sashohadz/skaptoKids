//
//  RevenueCatManager.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import Foundation
import RevenueCat
import RevenueCatUI

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
    
    // Paywall presentation control
    var shouldPresentPaywall = false
    
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
        if customerInfo.entitlements["Monthly"]?.isActive == true {
            currentSubscription = UserSubscription(
                isActive: true,
                type: .monthly,
                expirationDate: customerInfo.entitlements["Monthly"]?.expirationDate,
                remainingVisits: 0
            )
        }
        // Check for one-time pass
        else if customerInfo.entitlements["singleVisit"]?.isActive == true {
            // Check if this specific purchase has been consumed
            // Get the latest transaction for this entitlement
            let transactions = customerInfo.nonSubscriptions.filter { $0.productIdentifier == "singleVisit" }
            
            if let latestTransaction = transactions.first {
                // Check if this transaction ID has been marked as consumed
                let consumedKey = "consumed_\(latestTransaction.transactionIdentifier)"
                let hasConsumed = UserDefaults.standard.bool(forKey: consumedKey)
                
                if hasConsumed {
                    // This specific purchase was already used
                    currentSubscription = UserSubscription(
                        isActive: false,
                        type: nil,
                        expirationDate: nil,
                        remainingVisits: 0
                    )
                } else {
                    // Pass is available and not consumed yet
                    currentSubscription = UserSubscription(
                        isActive: true,
                        type: .oneTime,
                        expirationDate: customerInfo.entitlements["singleVisit"]?.expirationDate,
                        remainingVisits: 1
                    )
                }
            } else {
                // Fallback - grant access if no transaction history
                currentSubscription = UserSubscription(
                    isActive: true,
                    type: .oneTime,
                    expirationDate: customerInfo.entitlements["singleVisit"]?.expirationDate,
                    remainingVisits: 1
                )
            }
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
    
    // MARK: - Consume Single Visit Pass
    func consumeSingleVisitPass() async -> Bool {
        // Only proceed if user has a single visit pass
        guard currentSubscription.type == .oneTime,
              currentSubscription.remainingVisits > 0 else {
            return false
        }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Find the single visit entitlement and transaction
            guard let entitlement = customerInfo.entitlements["singleVisit"],
                  entitlement.isActive else {
                print("No active singleVisit entitlement found")
                return false
            }
            
            // Get the transaction ID for this purchase
            let transactions = customerInfo.nonSubscriptions.filter { $0.productIdentifier == "singleVisit" }
            
            if let latestTransaction = transactions.first {
                // Mark this specific transaction as consumed in UserDefaults
                // NOTE: For production, move this to your backend server
                let consumedKey = "consumed_\(latestTransaction.transactionIdentifier)"
                UserDefaults.standard.set(true, forKey: consumedKey)
                
                print("Marked transaction \(latestTransaction.transactionIdentifier) as consumed")
            }
            
            // Update local state - mark as consumed
            currentSubscription = UserSubscription(
                isActive: false,
                type: nil,
                expirationDate: nil,
                remainingVisits: 0
            )
            
            print("Single visit pass consumed successfully")
            return true
            
        } catch {
            errorMessage = "Failed to consume pass: \(error.localizedDescription)"
            print("Error consuming single visit pass: \(error)")
            return false
        }
    }
    
    // MARK: - Check if user can book workshop
    func canBookWorkshop() -> Bool {
        guard currentSubscription.isActive else {
            return false
        }
        
        // Monthly subscribers can always book
        if currentSubscription.type == .monthly {
            return true
        }
        
        // One-time pass holders need remaining visits
        if currentSubscription.type == .oneTime {
            return currentSubscription.remainingVisits > 0
        }
        
        return false
    }
}
