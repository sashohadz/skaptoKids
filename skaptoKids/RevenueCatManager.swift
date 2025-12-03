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
    
    // Custom attribute key for tracking daily passes
    private let dailyPassesAttributeKey = "daily_passes_purchased"
    
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
            
            // Check if this is a single visit pass purchase
            // Common identifiers: "single", "visit", "pass", "oneTime", "daily"
            let productId = package.storeProduct.productIdentifier.lowercased()
            print("🔍 Purchased product ID: '\(productId)'")
            
            let isSingleVisitPass = productId.contains("single") || 
                                   productId.contains("visit") || 
                                   productId.contains("pass") ||
                                   productId.contains("daily") ||
                                   productId.contains("onetime")
            
            print("🔍 Is single visit pass: \(isSingleVisitPass)")
            
            // Increment the daily passes counter for single visit purchases
            if isSingleVisitPass {
                print("🎫 Incrementing daily passes count...")
                await incrementDailyPassesCount()
            } else {
                print("⏭️ Skipping daily passes increment for product: \(productId)")
            }
            
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
    
    // MARK: - Daily Passes Tracking
    
    /// Get the current count of daily passes purchased by counting transactions
    func getDailyPassesCount() async -> Int {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Count all non-subscription transactions for single visit passes
            let singleVisitTransactions = customerInfo.nonSubscriptions.filter { 
                $0.productIdentifier == "singleVisit" 
            }
            
            return singleVisitTransactions.count
        } catch {
            print("Error getting daily passes count: \(error)")
            return 0
        }
    }
    
    /// Set subscriber attributes for analytics (optional, for RevenueCat dashboard)
    private func setDailyPassesAttribute(_ count: Int) async {
        do {
            try await Purchases.shared.setAttributes([dailyPassesAttributeKey: String(count)])
            print("✅ Successfully set daily passes attribute to \(count)")
        } catch {
            print("❌ Error setting daily passes attribute: \(error)")
            // Don't set errorMessage here as this is just for analytics
        }
    }
    
    /// Increment the daily passes counter (for analytics tracking)
    func incrementDailyPassesCount() async {
        print("📊 incrementDailyPassesCount() called")
        let currentCount = await getDailyPassesCount()
        print("📊 User has purchased \(currentCount) daily passes total")
        
        // Optionally set this as a subscriber attribute for analytics in RevenueCat dashboard
        await setDailyPassesAttribute(currentCount)
        print("📊 Finished setting daily passes attribute")
    }
}
