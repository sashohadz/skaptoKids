# skaptoKids Workshop App

A SwiftUI app for managing a kids workshop space where users can view the weekly program and subscribe for monthly memberships or one-time visits using RevenueCat.

## 🔧 Initial Setup

### 1. Configure API Keys (IMPORTANT - First Time Setup)
This project uses sensitive API keys that should NOT be committed to git.

1. **Copy the configuration template:**
   ```bash
   cp Config.swift.template Config.swift
   ```

2. **Add your RevenueCat API key:**
   Open `Config.swift` and replace `YOUR_REVENUECAT_API_KEY_HERE` with your actual RevenueCat API key from the [RevenueCat Dashboard](https://app.revenuecat.com).

3. **The file is already in .gitignore** so it won't be committed accidentally.

⚠️ **NEVER commit `Config.swift` to git** - it contains your private API keys!

### 2. Add RevenueCat to Your Project
```bash
# Using Swift Package Manager in Xcode:
# 1. File → Add Package Dependencies
# 2. Enter: https://github.com/RevenueCat/purchases-ios
# 3. Select the latest version
```

## ✅ What's Been Fixed

### 1. **Main Navigation Structure**
- Created a TabView-based navigation in `ContentView.swift`
- Three main tabs:
  - 📅 Workshops (WeeklyProgramView)
  - ⭐ Membership (SubscriptionView)
  - 👤 Profile (ProfileView)

### 2. **Subscription Management**
- Created `SubscriptionView.swift` with full RevenueCat integration
- Displays current subscription status
- Shows available subscription plans
- Supports both RevenueCat packages and fallback manual plans
- Restore purchases functionality
- Error handling for failed purchases

### 3. **Profile & Settings**
- Created `ProfileView.swift` with:
  - User info section
  - Subscription management
  - Bookings section (upcoming & history)
  - Settings (notifications)
  - Help & support links

### 4. **Workshop Detail Improvements**
- Added navigation to subscription view when membership is required
- Uses sheet presentation for subscription view

### 5. **RevenueCat Initialization**
- Updated `skaptoKidsApp.swift` to configure RevenueCat on app launch

## 🚀 Next Steps to Complete Integration

### 1. Configure RevenueCat Dashboard
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create a new project
3. Add your iOS app with Bundle ID
4. Configure Products:
   - **Monthly Membership**: Create a monthly subscription product
     - Entitlement ID: `monthly_membership`
   - **Single Visit Pass**: Create a non-consumable or consumable product
     - Entitlement ID: `single_visit`

### 2. Configure In-App Purchases in App Store Connect
1. Create your subscription and one-time purchase products
2. Match the product IDs with your RevenueCat configuration
3. Configure pricing and availability

## 📋 Features

### Workshop Management
- ✅ View weekly workshop schedule
- ✅ Browse workshops by day
- ✅ See workshop details (time, instructor, spots available)
- ✅ Filter by week (current, next, etc.)
- ✅ Navigate to workshop detail pages

### Subscription System
- ✅ Two subscription types:
  - **Monthly Membership**: Unlimited workshop access
  - **Single Visit Pass**: One-time workshop access
- ✅ View current subscription status
- ✅ See subscription benefits
- ✅ Purchase subscriptions via RevenueCat
- ✅ Restore purchases
- ✅ Expiration date tracking

### User Profile
- ✅ View subscription status
- ✅ Manage bookings (placeholder for implementation)
- ✅ Configure notifications
- ✅ Access help and support

## 🏗️ Architecture

### Models (`Models.swift`)
- `Workshop`: Workshop information and schedule
- `SubscriptionType`: Enum for subscription types
- `UserSubscription`: User's current subscription status

### ViewModels
- `WorkshopViewModel`: Manages workshop data and week navigation
- `RevenueCatManager`: Singleton managing RevenueCat integration

### Views
- `ContentView`: Main tab navigation
- `WeeklyProgramView`: Weekly workshop schedule
- `WorkshopDetailView`: Individual workshop details
- `SubscriptionView`: Subscription management and purchase
- `ProfileView`: User profile and settings

## 🔐 Privacy & Security

Remember to add these to your `Info.plist`:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this to provide you with personalized workshop recommendations.</string>
```

## 🎨 Design Features

- Modern SwiftUI design
- Adaptive dark/light mode support
- Color-coded workshops
- SF Symbols icons throughout
- Smooth animations and transitions
- Loading states and error handling

## 📝 Notes

- Sample workshop data is generated for testing
- In production, connect to your backend API
- Implement actual booking logic with your backend
- Add push notification support for workshop reminders
- Consider adding user authentication

## 🐛 Testing

To test subscriptions:
1. Use a Sandbox Apple ID in Settings → App Store
2. RevenueCat provides test mode for development
3. Test purchase flows without actual charges

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- RevenueCat SDK

---

**Ready to go!** Just add the RevenueCat package, configure your API key, and you're all set! 🎉
