# Single Visit Pass Implementation

## Overview
This implementation ensures that single visit passes are consumed after booking a workshop, requiring users to purchase again for their next booking.

## Changes Made

### 1. RevenueCatManager.swift
Added three new methods to handle single visit pass consumption:

#### `consumeSingleVisitPass() async -> Bool`
- Decrements the remaining visits count
- Deactivates the subscription when visits reach 0
- Returns `true` if consumption was successful

#### `canBookWorkshop() -> Bool`
- Checks if the user can currently book a workshop
- Monthly subscribers always return `true`
- Single visit pass holders need `remainingVisits > 0`
- Inactive subscriptions return `false`

### 2. WorkshopDetailView.swift
Updated the booking flow to consume passes:

#### `bookWorkshop()` (New Method)
- Called when user confirms booking
- Consumes single visit pass if applicable
- Shows booking confirmation after consumption

#### Updated Booking Button Logic
- Uses `canBookWorkshop()` instead of just checking `isActive`
- Shows different text based on subscription state
- Button text changes to "Get Access to Book" when no valid pass

## User Experience Flow

### Monthly Subscription Holder
1. User clicks "Book This Workshop"
2. Workshop is booked immediately
3. Can book unlimited workshops

### Single Visit Pass Holder
1. User clicks "Book This Workshop"
2. Workshop is booked
3. Single visit pass is consumed
4. `remainingVisits` decrements to 0
5. Subscription is deactivated
6. Next workshop booking will show paywall again

### No Active Subscription
1. User clicks "Get Access to Book"
2. Paywall is presented
3. After purchase, booking proceeds normally

## Important Notes

### Production Considerations
For a production app, you should:

1. **Backend Integration**
   - Track remaining visits on your server
   - Sync with RevenueCat server-side
   - Prevent client-side manipulation

2. **RevenueCat Consumables**
   - Consider using RevenueCat's consumable products feature
   - This provides built-in server-side tracking
   - See: https://www.revenuecat.com/docs/consumables

3. **Preventing Abuse**
   - Current implementation is client-side only
   - Users could reinstall to restore passes
   - Implement server-side validation

### Example Server Integration
```swift
// In RevenueCatManager
func consumeSingleVisitPass() async -> Bool {
    guard currentSubscription.type == .oneTime,
          currentSubscription.remainingVisits > 0 else {
        return false
    }
    
    // Call your backend API
    do {
        try await YourBackendAPI.consumeVisit(userId: currentUserId)
        
        // Update local state
        currentSubscription.remainingVisits -= 1
        
        if currentSubscription.remainingVisits <= 0 {
            currentSubscription = UserSubscription(
                isActive: false,
                type: nil,
                expirationDate: nil,
                remainingVisits: 0
            )
        }
        
        return true
    } catch {
        errorMessage = "Failed to consume visit: \(error.localizedDescription)"
        return false
    }
}
```

## Testing

### Test Scenarios
1. **Purchase single visit pass**
   - Verify `remainingVisits = 1`
   - Verify `isActive = true`

2. **Book a workshop with single visit**
   - Verify booking succeeds
   - Verify `remainingVisits = 0`
   - Verify `isActive = false`

3. **Try to book another workshop**
   - Verify paywall is presented
   - Verify button text is "Get Access to Book"

4. **Purchase monthly subscription**
   - Book multiple workshops
   - Verify subscription remains active
   - Verify unlimited bookings

## Future Enhancements

### Multi-Visit Passes
To support 3-pack, 5-pack, etc.:

```swift
// In updateSubscriptionStatus
else if customerInfo.entitlements["threeVisit"]?.isActive == true {
    currentSubscription = UserSubscription(
        isActive: true,
        type: .threeVisit, // Add to SubscriptionType enum
        expirationDate: customerInfo.entitlements["threeVisit"]?.expirationDate,
        remainingVisits: 3 // Load from backend for accurate count
    )
}
```

### Visit History
Track which workshops were booked with which pass:

```swift
struct BookingRecord {
    let workshopId: UUID
    let bookedDate: Date
    let passType: SubscriptionType
    let passId: String
}
```

### Expiring Passes
Add expiration dates for single visit passes:

```swift
func isPassExpired() -> Bool {
    guard let expirationDate = currentSubscription.expirationDate else {
        return false
    }
    return Date() > expirationDate
}
```
