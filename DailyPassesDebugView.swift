//
//  DailyPassesDebugView.swift
//  skaptoKids
//
//  Debug view for testing daily passes counter functionality
//

import SwiftUI
import RevenueCat

struct DailyPassesDebugView: View {
    @State private var currentCount: Int = 0
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    var revenueCatManager = RevenueCatManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                // Current Count Display
                Section("Current Count") {
                    HStack {
                        Image(systemName: "ticket.fill")
                            .font(.title)
                            .foregroundStyle(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Passes Purchased")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(currentCount)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Actions
                Section("Test Actions") {
                    Button {
                        Task {
                            await loadCount()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Count")
                        }
                    }
                    
                    Button {
                        Task {
                            await incrementCount()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Manually Increment (Test)")
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await resetCount()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset Count to 0")
                        }
                    }
                }
                
                // Status Section
                if !statusMessage.isEmpty {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Information
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Attribute Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("daily_passes_purchased")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("This counter increments automatically when a user purchases a single visit pass.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("View this attribute in the RevenueCat Dashboard under Customers → [Your User] → Custom Attributes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Daily Passes Debug")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .task {
                await loadCount()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadCount() async {
        isLoading = true
        statusMessage = "Loading count..."
        
        currentCount = await revenueCatManager.getDailyPassesCount()
        
        statusMessage = "Loaded successfully at \(Date().formatted(date: .omitted, time: .standard))"
        isLoading = false
    }
    
    private func incrementCount() async {
        isLoading = true
        statusMessage = "Incrementing count..."
        
        await revenueCatManager.incrementDailyPassesCount()
        await loadCount()
        
        statusMessage = "Incremented! New count: \(currentCount)"
        isLoading = false
    }
    
    private func resetCount() async {
        isLoading = true
        statusMessage = "Resetting count..."
        
        // Set count back to 0
        do {
            try await Purchases.shared.setAttributes(["daily_passes_purchased": "0"])
            await loadCount()
            statusMessage = "Reset to 0 successfully"
        } catch {
            statusMessage = "Error resetting: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    DailyPassesDebugView()
}
