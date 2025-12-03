//
//  PaywallView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// A wrapper view for presenting RevenueCat paywalls
/// This provides more control over the paywall presentation
struct CustomRevenueCatPaywallView: View {
    @Environment(\.dismiss) var dismiss
    var revenueCatManager = RevenueCatManager.shared
    
    // Optional: Specify which offering to display
    var offeringIdentifier: String? = nil
    
    // Callbacks
    var onPurchaseCompleted: ((CustomerInfo) -> Void)?
    var onRestoreCompleted: ((CustomerInfo) -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        RevenueCatUI.PaywallView(
            offering: nil, // Use current offering, or specify one
            customerInfo: nil // Let RevenueCat fetch it
        )
        .onPurchaseCompleted { customerInfo in
            // Handle successful purchase
            Task {
                print("🎯 Purchase completed in PaywallView")
                
                // Check what was purchased and track it
                if customerInfo.entitlements["singleVisit"]?.isActive == true {
                    print("🎫 Single visit pass detected, tracking purchase...")
                    await revenueCatManager.incrementDailyPassesCount()
                }
                
                await revenueCatManager.checkSubscriptionStatus()
                onPurchaseCompleted?(customerInfo)
                dismiss()
            }
        }
        .onRestoreCompleted { customerInfo in
            // Handle successful restore
            Task {
                await revenueCatManager.checkSubscriptionStatus()
                onRestoreCompleted?(customerInfo)
                dismiss()
            }
        }
        .onDismiss {
            // Handle dismissal
            onDismiss?()
            dismiss()
        }
    }
}

/// Alternative: A custom paywall view if you want to style it yourself
/// This gives you full control over the UI while using RevenueCat for purchases
struct CustomPaywallView: View {
    @Environment(\.dismiss) var dismiss
    var revenueCatManager = RevenueCatManager.shared
    
    @State private var selectedPackage: Package?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var onPurchaseCompleted: ((CustomerInfo) -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Benefits
                    benefitsSection
                    
                    // Packages
                    if revenueCatManager.availablePackages.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        packagesSection
                    }
                    
                    // Purchase Button
                    if selectedPackage != nil {
                        purchaseButton
                    }
                    
                    // Restore Button
                    restoreButton
                    
                    // Terms and Privacy
                    termsSection
                }
                .padding()
            }
            .navigationTitle("Choose Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            await revenueCatManager.loadOfferings()
            // Select the first package by default
            selectedPackage = revenueCatManager.availablePackages.first
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            Text("Unlock Full Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Choose the perfect plan for your family")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitRow(icon: "calendar.badge.checkmark", title: "Unlimited Workshop Access", description: "Attend as many workshops as you like")
            BenefitRow(icon: "clock.arrow.2.circlepath", title: "Priority Booking", description: "Book your spot before everyone else")
            BenefitRow(icon: "star.circle.fill", title: "Exclusive Events", description: "Access to special members-only events")
            BenefitRow(icon: "percent", title: "Member Discounts", description: "10% off all materials and merchandise")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var packagesSection: some View {
        VStack(spacing: 12) {
            ForEach(revenueCatManager.availablePackages, id: \.identifier) { package in
                PackageSelectionCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier
                ) {
                    selectedPackage = package
                }
            }
        }
    }
    
    private var purchaseButton: some View {
        Button {
            guard let package = selectedPackage else { return }
            Task {
                isProcessing = true
                defer { isProcessing = false }
                
                let success = await revenueCatManager.purchase(package: package)
                if success {
                    // Get updated customer info
                    do {
                        let customerInfo = try await Purchases.shared.customerInfo()
                        onPurchaseCompleted?(customerInfo)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = revenueCatManager.errorMessage
                }
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Subscribe Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var restoreButton: some View {
        Button {
            Task {
                isProcessing = true
                defer { isProcessing = false }
                
                let success = await revenueCatManager.restorePurchases()
                if success && revenueCatManager.currentSubscription.isActive {
                    dismiss()
                } else if !success {
                    errorMessage = revenueCatManager.errorMessage ?? "No purchases to restore"
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.top, 8)
    }
    
    private var termsSection: some View {
        HStack(spacing: 16) {
            Link("Terms of Service", destination: URL(string: "https://your-website.com/terms")!)
            Text("•")
                .foregroundStyle(.secondary)
            Link("Privacy Policy", destination: URL(string: "https://your-website.com/privacy")!)
        }
        .font(.caption)
        .foregroundStyle(.blue)
        .padding(.top)
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PackageSelectionCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if package.packageType == .monthly {
                        Text("per month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomPaywallView()
}
