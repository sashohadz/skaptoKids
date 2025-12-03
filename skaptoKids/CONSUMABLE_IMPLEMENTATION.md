# RevenueCat Consumable Implementation Guide

## Overview
This implementation handles RevenueCat consumable products (single visit passes) by tracking consumption using transaction identifiers. When a user books a workshop with a single visit pass, that specific transaction is marked as consumed and won't grant access again.

## RevenueCat Product Configuration

### Single Visit Pass
- **Identifier**: `singleVisit`
- **Product Type**: Consumable
- **Store**: Test Store (or your production store)
- **Display Name**: Single Visit Pass
- **Entitlement**: `singleVisit`

## How It Works

### 1. Purchase Flow
```swift
// User purchases single visit pass
// RevenueCat creates a transaction with a unique transactionIdentifier
// The "singleVisit" entitlement becomes active
```

### 2. Checking Subscription Status
When `checkSubscriptionStatus()` is called:

```swift
// 1. Fetch customer info from RevenueCat
let customerInfo = try await Purchases.shared.customerInfo()

// 2. Check if singleVisit entitlement is active
if customerInfo.entitlements["singleVisit"]?.isActive == true {
    
    // 3. Get the transaction from nonSubscriptions
    let transactions = customerInfo.nonSubscriptions.filter { 
        $0.productIdentifier == "singleVisit" 
    }
    
    // 4. Check if this specific transaction has been consumed
    let consumedKey = "consumed_\(transaction.transactionIdentifier)"
    let hasConsumed = UserDefaults.standard.bool(forKey: consumedKey)
    
    // 5. Grant access only if not consumed
    if !hasConsumed {
        // User can book a workshop
    }
}
```

### 3. Booking a Workshop
When user books a workshop:

```swift
func bookWorkshop() {
    Task {
        // If single visit pass, consume it
        if revenueCatManager.currentSubscription.type == .oneTime {
            await revenueCatManager.consumeSingleVisitPass()
        }
        showingBookingConfirmation = true
    }
}
```

### 4. Consuming the Pass
```swift
func consumeSingleVisitPass() async -> Bool {
    // Get the transaction identifier
    let transactions = customerInfo.nonSubscriptions.filter { 
        $0.productIdentifier == "singleVisit" 
    }
    
    // Mark this specific transaction as consumed
    let consumedKey = "consumed_\(transaction.transactionIdentifier)"
    UserDefaults.standard.set(true, forKey: consumedKey)
    
    // Deactivate local subscription
    currentSubscription.isActive = false
    currentSubscription.remainingVisits = 0
}
```

## Key Features

### ✅ Transaction-Based Tracking
- Each purchase has a unique `transactionIdentifier`
- Consumption is tied to specific transactions
- Multiple purchases create multiple transactions
- Each transaction can only be consumed once

### ✅ Persistent Across App Sessions
- Consumption state stored in UserDefaults
- Survives app restarts
- Checked on every subscription status update

### ✅ Works with RevenueCat Entitlements
- Leverages RevenueCat's `nonSubscriptions` array
- Uses actual transaction data from the store
- No manual receipt parsing needed

## User Experience

### Scenario 1: First-time Purchase
1. User purchases single visit pass → `isActive = true`, `remainingVisits = 1`
2. User books workshop → Pass consumed, `isActive = false`, `remainingVisits = 0`
3. User tries to book another → Paywall appears

### Scenario 2: Multiple Purchases
1. User purchases single visit pass #1 → Transaction A created
2. User books workshop → Transaction A marked as consumed
3. User purchases single visit pass #2 → Transaction B created
4. User can book another workshop → Transaction B not yet consumed

### Scenario 3: Restore Purchases
1. User deletes app or gets new device
2. User restores purchases
3. RevenueCat returns all transactions
4. App checks consumption status for each transaction
5. Only unconsumed passes grant access

## Testing

### Test Case 1: Single Visit Pass Consumption
```swift
// 1. Purchase single visit pass
// Expected: isActive = true, remainingVisits = 1

// 2. Book a workshop  
await revenueCatManager.consumeSingleVisitPass()
// Expected: isActive = false, remainingVisits = 0

// 3. Restart app and check status
await revenueCatManager.checkSubscriptionStatus()
// Expected: Still inactive (consumption persisted)

// 4. Try to book another workshop
let canBook = revenueCatManager.canBookWorkshop()
// Expected: false - paywall should appear
```

### Test Case 2: Monthly Subscription
```swift
// 1. Purchase monthly subscription
// Expected: isActive = true, type = .monthly

// 2. Book multiple workshops
bookWorkshop() // Should succeed
bookWorkshop() // Should succeed
bookWorkshop() // Should succeed
// Expected: Subscription remains active

// 3. Check status
// Expected: Still active, unlimited bookings
```

### Test Case 3: Multiple Single Visits
```swift
// 1. Purchase first single visit
// Transaction ID: "123"
// Expected: Can book 1 workshop

// 2. Book workshop
// Expected: Transaction "123" marked consumed

// 3. Purchase second single visit
// Transaction ID: "456"
// Expected: Can book another workshop

// 4. Check status
// Expected: Transaction "456" not consumed, access granted
```

## Important Notes

### ⚠️ Current Implementation (UserDefaults)
**Pros:**
- Simple and fast
- Works for testing and development
- No backend required

**Cons:**
- Stored locally on device
- Lost if user reinstalls app without restore
- Can be cleared if user resets app data
- Not synchronized across devices

### 🚀 Production Recommendations

For production, you should implement server-side tracking:

```swift
func consumeSingleVisitPass() async -> Bool {
    // ... existing code ...
    
    // Instead of UserDefaults, call your backend:
    try await YourBackendAPI.markTransactionConsumed(
        userId: customerInfo.originalAppUserId,
        transactionId: latestTransaction.transactionIdentifier,
        productId: "singleVisit"
    )
    
    // ... rest of code ...
}

func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
    // ... existing code ...
    
    // Instead of UserDefaults, check your backend:
    let hasConsumed = try await YourBackendAPI.isTransactionConsumed(
        userId: customerInfo.originalAppUserId,
        transactionId: transaction.transactionIdentifier
    )
    
    // ... rest of code ...
}
```

### Backend Implementation Example
```python
# Python/Flask example
@app.route('/api/consume-transaction', methods=['POST'])
def consume_transaction():
    user_id = request.json['user_id']
    transaction_id = request.json['transaction_id']
    product_id = request.json['product_id']
    
    # Store in database
    db.consumed_transactions.insert({
        'user_id': user_id,
        'transaction_id': transaction_id,
        'product_id': product_id,
        'consumed_at': datetime.utcnow(),
        'workshop_id': request.json.get('workshop_id')
    })
    
    return {'success': True}

@app.route('/api/check-transaction/<transaction_id>', methods=['GET'])
def check_transaction(transaction_id):
    consumed = db.consumed_transactions.find_one({
        'transaction_id': transaction_id
    })
    return {'is_consumed': consumed is not None}
```

## Troubleshooting

### Issue: Pass shows as available after consuming
**Solution**: Check that `checkSubscriptionStatus()` is being called after consumption:
```swift
await revenueCatManager.consumeSingleVisitPass()
await revenueCatManager.checkSubscriptionStatus() // Add this
```

### Issue: Multiple workshops can be booked with one pass
**Solution**: Verify `consumeSingleVisitPass()` is being called in `bookWorkshop()`:
```swift
private func bookWorkshop() {
    Task {
        if revenueCatManager.currentSubscription.type == .oneTime {
            await revenueCatManager.consumeSingleVisitPass() // Must be here
        }
        showingBookingConfirmation = true
    }
}
```

### Issue: Restored purchases don't show consumed state
**Cause**: Using UserDefaults instead of server-side tracking
**Solution**: Implement backend tracking (see Production Recommendations above)

## Migration Path

### Phase 1: Current (UserDefaults)
- ✅ Quick testing and development
- ✅ Proves the concept works
- ⚠️ Not suitable for production

### Phase 2: Backend Integration
- Move consumption tracking to server
- Add API endpoints for consume/check
- Update app to call backend
- Keep UserDefaults as fallback

### Phase 3: RevenueCat Webhooks
- Set up RevenueCat webhooks
- Track all purchases server-side
- Implement admin dashboard
- Add analytics and reporting

## Additional Features to Consider

### 1. Expiring Passes
Add expiration dates to single visit passes:
```swift
// In Models.swift
struct UserSubscription {
    // ... existing properties ...
    var passExpiresAt: Date?
    
    var isPassExpired: Bool {
        guard let expiresAt = passExpiresAt else { return false }
        return Date() > expiresAt
    }
}
```

### 2. Multi-Visit Packs
Support 3-visit, 5-visit, 10-visit packs:
```swift
// Create multiple consumable products
// "threeVisit" - grants 3 bookings
// "fiveVisit" - grants 5 bookings
// Track remaining count in your backend
```

### 3. Pass History
Track which workshops were booked with which pass:
```swift
struct PassUsageRecord {
    let transactionId: String
    let workshopId: UUID
    let workshopTitle: String
    let usedAt: Date
}
```

### 4. Refund Handling
Handle cases where users get refunds:
```swift
// Check if transaction was refunded
if transaction.isRefunded {
    // Don't grant access even if not marked consumed
}
```

## Summary

This implementation provides a robust foundation for handling RevenueCat consumable products. The current UserDefaults-based approach is perfect for development and testing. For production, follow the backend integration recommendations to ensure consumption state is properly synchronized across devices and survives app reinstalls.

Key takeaways:
- ✅ Each transaction has a unique ID
- ✅ Consumption is tracked per transaction
- ✅ Works seamlessly with RevenueCat's entitlement system
- ⚠️ Remember to implement server-side tracking for production
