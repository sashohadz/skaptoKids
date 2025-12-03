# Quick Reference: RevenueCat Paywall

## 🎯 Quick Start (5 Steps)

1. **Add Packages**
   ```
   https://github.com/RevenueCat/purchases-ios
   ```
   Add: RevenueCat + RevenueCatUI

2. **Set API Key**
   ```swift
   // skaptoKidsApp.swift
   RevenueCatManager.shared.configure(apiKey: "pk_xxxxx")
   ```

3. **Create Paywall**
   - RevenueCat Dashboard → Paywalls → Create New

4. **Configure Entitlements**
   - Dashboard: `monthly_membership`, `single_visit`

5. **Test**
   - Book workshop requiring membership
   - Paywall should appear!

## 📱 Paywall Behavior

| Scenario | What Happens |
|----------|-------------|
| User has membership | Workshop books immediately |
| User lacks membership + workshop requires it | Paywall appears |
| User completes purchase | Paywall dismisses, workshop books |
| User cancels paywall | Returns to workshop detail |
| User restores purchase | Subscription restored, can book |

## 🎨 Choose Implementation

### Option 1: Dashboard Paywall (Recommended)
```swift
// WorkshopDetailView.swift
private let useCustomPaywallSheet = false
```
✅ Uses RevenueCat Dashboard design  
✅ Update design without code changes  
✅ A/B testing support  

### Option 2: Custom Paywall
```swift
// WorkshopDetailView.swift
private let useCustomPaywallSheet = true
```
✅ Full UI control  
✅ Custom logic & analytics  
✅ Unique branding  

## 🔑 Key Files

| File | Purpose |
|------|---------|
| `WorkshopDetailView.swift` | Triggers paywall on booking |
| `PaywallView.swift` | Custom paywall UI |
| `RevenueCatManager.swift` | Subscription management |
| `Models.swift` | UserSubscription model |

## 🎯 Entitlement IDs

Must match everywhere:

```swift
// In Code
"monthly_membership"
"single_visit"

// In Dashboard
monthly_membership → Monthly Product
single_visit → One-time Product

// In App Store Connect
com.yourapp.monthly
com.yourapp.singlevisit
```

## 🧪 Testing

1. **Simulator/Device**
   - Use Sandbox Apple ID
   - Settings → App Store → Sandbox Account

2. **Test Flow**
   ```
   Browse workshops
   → Select workshop with requiresMembership = true
   → Tap "Book This Workshop"
   → Paywall appears ✓
   → Complete test purchase
   → Workshop books ✓
   ```

3. **Test Restore**
   ```
   Delete app
   → Reinstall
   → Try booking
   → Tap "Restore Purchases"
   → Subscription restored ✓
   ```

## 🛠️ Common Fixes

| Issue | Solution |
|-------|----------|
| Paywall doesn't show | Check RevenueCatUI is added |
| "No offerings" error | Configure offerings in dashboard |
| Purchase doesn't unlock | Verify entitlement IDs match |
| Wrong paywall shows | Check offering identifier |

## 📊 Where to Check Things

| What | Where |
|------|-------|
| Subscription status | `RevenueCatManager.currentSubscription` |
| Available packages | `RevenueCatManager.availablePackages` |
| User entitlements | RevenueCat Dashboard → Customers |
| Purchase analytics | RevenueCat Dashboard → Charts |
| Paywall design | RevenueCat Dashboard → Paywalls |

## 🎨 Customize Custom Paywall

```swift
// PaywallView.swift → CustomPaywallView

// Header
Text("Unlock Full Access")        // Title
Image(systemName: "star.fill")    // Icon

// Benefits
BenefitRow(
    icon: "calendar.badge.checkmark",
    title: "Unlimited Access",
    description: "Attend all workshops"
)

// Colors
.background(Color.blue)           // Button color
.foregroundStyle(.white)          // Text color
```

## 🔄 Update Flow

```
User Action
    ↓
Check Subscription
    ↓
Has Membership? → YES → Book Workshop ✓
    ↓ NO
Show Paywall
    ↓
Purchase or Cancel?
    ↓ Purchase
Process Payment
    ↓
Update Subscription
    ↓
Book Workshop ✓
```

## 🎯 Workshop Configuration

```swift
// Models.swift
Workshop(
    id: UUID(),
    title: "Creative Painting",
    // ... other properties
    requiresMembership: true  // ← Set to true for premium workshops
)
```

## 📦 Package Dependencies

```swift
// Package.swift or SPM
dependencies: [
    .package(
        url: "https://github.com/RevenueCat/purchases-ios",
        from: "5.0.0"
    )
]

targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "RevenueCat", package: "purchases-ios"),
            .product(name: "RevenueCatUI", package: "purchases-ios")
        ]
    )
]
```

## 🚀 Production Checklist

- [ ] Production API key configured
- [ ] Products created in App Store Connect
- [ ] Products linked in RevenueCat
- [ ] Paywall designed and published
- [ ] Entitlement IDs match everywhere
- [ ] End-to-end testing complete
- [ ] Sandbox testing passed
- [ ] Privacy policy updated
- [ ] App Store screenshots show paywall
- [ ] Review guidelines followed

## 📞 Help & Resources

- Full guide: `PAYWALL_IMPLEMENTATION.md`
- Summary: `PAYWALL_SUMMARY.md`
- RevenueCat Docs: https://docs.revenuecat.com/
- Support: https://community.revenuecat.com/

---

**Quick Tip:** Start with Dashboard paywall (Option 1). It's the fastest way to get running and you can always switch to custom later!
