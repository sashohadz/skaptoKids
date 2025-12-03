# RevenueCat Paywall Implementation Guide

## Overview

The app now includes **RevenueCat Paywall** integration that displays when users try to book a workshop that requires a membership. There are **two implementation options** available.

## Setup Required

### 1. Add RevenueCat Packages

Add both packages via Swift Package Manager:
1. File → Add Package Dependencies
2. URL: `https://github.com/RevenueCat/purchases-ios`
3. Add **BOTH** packages to your target:
   - ✅ **RevenueCat** (core SDK)
   - ✅ **RevenueCatUI** (for paywall support)

### 2. Configure RevenueCat Dashboard

1. **Create Paywall in RevenueCat Dashboard:**
   - Go to [RevenueCat Dashboard](https://app.revenuecat.com)
   - Navigate to **Paywalls** section
   - Click **Create New Paywall**
   - Design your paywall using the visual editor
   - Configure packages, copy, images, and colors
   - Save and publish your paywall

2. **Set Up Entitlements:**
   - Create entitlement: `monthly_membership`
   - Create entitlement: `single_visit` (optional, for one-time passes)
   - Attach products to these entitlements

3. **Configure Products:**
   - Monthly subscription product
   - One-time purchase product (optional)
   - Link to App Store Connect products

### 3. Update API Key

In `skaptoKidsApp.swift`, replace:
```swift
RevenueCatManager.shared.configure(apiKey: "YOUR_REVENUECAT_API_KEY")
```

Get your API key from: RevenueCat Dashboard → Project Settings → API Keys

## Implementation Options

### Option 1: Automatic Paywall (Recommended for Most Cases)

Uses RevenueCat's `presentPaywallIfNeeded` modifier with the paywall you designed in the dashboard.

**Pros:**
- Uses your custom-designed paywall from RevenueCat Dashboard
- Minimal code required
- Automatic updates when you change paywall in dashboard
- Handles all purchase logic automatically

**Configuration:**
In `WorkshopDetailView.swift`, set:
```swift
private let useCustomPaywallSheet = false
```

This will use the `.presentPaywallIfNeeded()` modifier which automatically:
- Checks if user has the required entitlement
- Shows paywall if they don't
- Processes purchases
- Handles restore purchases
- Dismisses when complete

### Option 2: Custom Sheet-Based Paywall

Uses `CustomPaywallView` which gives you full control over the UI.

**Pros:**
- Full control over UI and styling
- Can customize behavior and flow
- Better for unique user experiences
- Can add custom analytics or logic

**Configuration:**
In `WorkshopDetailView.swift`, set:
```swift
private let useCustomPaywallSheet = true
```

This presents a sheet with a fully customizable paywall UI defined in `PaywallView.swift`.

## How It Works

### User Flow

1. User browses workshops in `WeeklyProgramView`
2. User taps on a workshop to see details
3. User taps "Book This Workshop" button
4. **If workshop requires membership AND user doesn't have one:**
   - Paywall is presented (either RevenueCat's or custom)
   - User can purchase or restore
   - On success, workshop is booked automatically
5. **If user has membership OR workshop doesn't require one:**
   - Workshop is booked immediately

### Code Flow

```swift
Button("Book This Workshop") {
    if workshop.requiresMembership && !revenueCatManager.currentSubscription.isActive {
        // Show paywall (chosen method)
        if useCustomPaywallSheet {
            showCustomPaywall = true  // Shows custom sheet
        } else {
            displayPaywall = true     // Triggers presentPaywallIfNeeded
        }
    } else {
        // Book immediately
        showingBookingConfirmation = true
    }
}
```

## Files Created/Modified

### New Files:
- ✅ **PaywallView.swift** - Contains `CustomPaywallView` and supporting views
  - `CustomPaywallView`: Main custom paywall interface
  - `BenefitRow`: Displays subscription benefits
  - `PackageSelectionCard`: Shows subscription packages

### Modified Files:
- ✅ **RevenueCatManager.swift** - Added `RevenueCatUI` import
- ✅ **WorkshopDetailView.swift** - Added paywall presentation logic
  - Both `.presentPaywallIfNeeded()` and `.sheet()` implementations
  - Toggle to switch between them

## Customization

### Customize RevenueCat Dashboard Paywall
1. Go to RevenueCat Dashboard → Paywalls
2. Edit your paywall:
   - Change colors and fonts
   - Update copy and descriptions
   - Add/remove benefit highlights
   - Adjust package display order
   - Upload custom images
3. Changes appear immediately in the app (no code changes needed)

### Customize the Custom Paywall

Edit `CustomPaywallView` in `PaywallView.swift`:

```swift
// Change header
private var headerSection: some View {
    VStack(spacing: 16) {
        Image(systemName: "star.fill") // ← Change icon
        Text("Unlock Full Access")     // ← Change title
        Text("Choose the perfect plan")// ← Change subtitle
    }
}

// Add/remove benefits
private var benefitsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        BenefitRow(icon: "...", title: "...", description: "...")
        // Add more benefits here
    }
}
```

### Change Entitlement Check

Currently checks for `"monthly_membership"`. To change:

```swift
// In WorkshopDetailView.swift
.presentPaywallIfNeeded(
    requiredEntitlementIdentifier: "your_entitlement_id", // ← Change this
    purchaseCompleted: { customerInfo in
        // ...
    }
)
```

## Testing

### 1. Test Without Real Purchases

Use RevenueCat's test mode:
- No real charges occur during development
- Test mode is active when using debug API key

### 2. Test Paywall Flow

1. Make sure a workshop has `requiresMembership = true`
2. Ensure user doesn't have an active subscription
3. Tap "Book This Workshop"
4. Paywall should appear
5. Test purchase flow (use sandbox Apple ID)
6. Verify workshop books after successful purchase

### 3. Test Restore Purchases

1. Make a test purchase
2. Delete and reinstall app
3. Try to book a workshop requiring membership
4. Tap "Restore Purchases" in paywall
5. Verify subscription is restored

### 4. Switching Between Implementations

To test both paywall types:

```swift
// In WorkshopDetailView.swift
private let useCustomPaywallSheet = true  // Custom UI
private let useCustomPaywallSheet = false // RevenueCat Dashboard UI
```

## Common Issues & Solutions

### Issue: Paywall doesn't appear
**Solution:**
- Check that RevenueCatUI package is added
- Verify API key is configured
- Check that entitlement identifier matches dashboard
- Ensure workshop has `requiresMembership = true`

### Issue: "No offerings found"
**Solution:**
- Configure offerings in RevenueCat Dashboard
- Check API key is correct
- Verify products are linked to entitlements
- Wait a few minutes for dashboard changes to sync

### Issue: Purchase doesn't unlock content
**Solution:**
- Verify entitlement identifiers match everywhere
- Check `RevenueCatManager.updateSubscriptionStatus()` logic
- Ensure `checkSubscriptionStatus()` is called after purchase

### Issue: Custom paywall looks different than expected
**Solution:**
- Check that you're using `useCustomPaywallSheet = true`
- Verify packages are loading in `RevenueCatManager`
- Review `CustomPaywallView` in `PaywallView.swift`

## Best Practices

1. **Design paywall first in RevenueCat Dashboard** - Preview it there before implementing
2. **Test both purchase and restore flows** - Many users need restore
3. **Handle errors gracefully** - Show user-friendly error messages
4. **Check subscription status on app launch** - Update `RevenueCatManager` early
5. **Don't block free content** - Only require membership for premium workshops
6. **Make benefits clear** - Users should understand value before purchasing

## Next Steps

1. ✅ Add RevenueCat and RevenueCatUI packages
2. ✅ Configure API key in `skaptoKidsApp.swift`
3. ✅ Create and design paywall in RevenueCat Dashboard
4. ✅ Set up products in App Store Connect
5. ✅ Link products to entitlements in RevenueCat
6. ✅ Choose which paywall implementation to use
7. ✅ Test with sandbox Apple ID
8. ✅ Submit for App Store review with subscription features

## Additional Resources

- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [Displaying Paywalls Guide](https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls)
- [RevenueCatUI Documentation](https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls#ios)
- [Testing Subscriptions](https://www.revenuecat.com/docs/test-and-launch/sandbox-testing)

---

**You're all set!** The paywall will automatically appear when users try to book workshops that require membership. 🎉
