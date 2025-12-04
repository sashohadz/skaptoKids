//
//  SubscriptionView.swift
//  skaptoKids
//
//  Created by Sasho Hadzhiev on 3.12.25.
//

import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @State var revenueCatManager = RevenueCatManager.shared
    @State private var showingPurchaseError = false
    @State private var showingRestoreSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status
                    currentStatusSection
                    
                    // Available Plans
                    if !revenueCatManager.currentSubscription.isActive {
                        availablePlansSection
                    }
                    
                    // Restore Purchases Button
                    restorePurchasesButton
                }
                .padding()
            }
            .navigationTitle("Membership")
            .background(Color(.systemGroupedBackground))
            .overlay {
                if revenueCatManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Purchase Error", isPresented: $showingPurchaseError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(revenueCatManager.errorMessage ?? "An error occurred")
            }
            .alert("Purchases Restored", isPresented: $showingRestoreSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your purchases have been successfully restored!")
            }
        }
    }
    
    private var currentStatusSection: some View {
        VStack(spacing: 16) {
            // Status Badge
            ZStack {
                Circle()
                    .fill(revenueCatManager.currentSubscription.isActive ? Color.green.gradient : Color.gray.gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: revenueCatManager.currentSubscription.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            
            Text(revenueCatManager.currentSubscription.statusText)
                .font(.title2)
                .fontWeight(.bold)
            
            if let expirationDate = revenueCatManager.currentSubscription.expirationDate,
               revenueCatManager.currentSubscription.isActive {
                Text("Valid until \(expirationDate.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Benefits if active
            if revenueCatManager.currentSubscription.isActive,
               let type = revenueCatManager.currentSubscription.type {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Benefits")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(type.benefits, id: \.self) { benefit in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(benefit)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var availablePlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
            
            // If RevenueCat packages are available
            if !revenueCatManager.availablePackages.isEmpty {
                ForEach(revenueCatManager.availablePackages, id: \.identifier) { package in
                    RevenueCatPlanCard(package: package) {
                        Task {
                            let success = await revenueCatManager.purchase(package: package)
                            if success {
                                // Explicitly refresh subscription status after successful purchase
                                await revenueCatManager.checkSubscriptionStatus()
                            } else {
                                showingPurchaseError = true
                            }
                        }
                    }
                }
            } else {
                // Fallback to manual subscription types
                ForEach(SubscriptionType.allCases, id: \.self) { type in
                    SubscriptionCard(type: type) {
                        // This would need to map to the actual RevenueCat package
                        // For now, show an error
                        revenueCatManager.errorMessage = "Unable to load subscription options. Please try again."
                        showingPurchaseError = true
                    }
                }
            }
        }
    }
    
    private var restorePurchasesButton: some View {
        Button {
            Task {
                let success = await revenueCatManager.restorePurchases()
                if success {
                    showingRestoreSuccess = true
                } else {
                    showingPurchaseError = true
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.top)
    }
}

struct SubscriptionCard: View {
    let type: SubscriptionType
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundStyle(type == .monthly ? .blue : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Benefits
            VStack(alignment: .leading, spacing: 8) {
                ForEach(type.benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(benefit)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            
            // Subscribe Button
            Button(action: action) {
                Text("Select Plan")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(type == .monthly ? Color.blue : Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type == .monthly ? Color.blue.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RevenueCatPlanCard: View {
    let package: Package
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: packageIcon)
                    .font(.title)
                    .foregroundStyle(packageColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Price
            HStack {
                Text(package.storeProduct.localizedPriceString)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if package.packageType == .monthly {
                    Text("/ month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Subscribe Button
            Button(action: action) {
                Text("Subscribe")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(packageColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(packageColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var packageIcon: String {
        switch package.packageType {
        case .monthly:
            return "calendar.badge.plus"
        default:
            return "ticket.fill"
        }
    }
    
    private var packageColor: Color {
        switch package.packageType {
        case .monthly:
            return .blue
        default:
            return .orange
        }
    }
}

#Preview {
    SubscriptionView()
}
