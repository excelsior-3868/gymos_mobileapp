# GymOS Member — Flutter Mobile App

The official GymOS Member mobile app, converted from React Native to native **Flutter (Dart)**.

## Features

- **Authentication & Security**:
  - SMS OTP login with Nepal phone number (+977) verification.
  - Automatic dev-mode code population and 30s resend cooldown.
  - Persistent Bearer token storage via `SharedPreferences`.
  - Global 401 unauthorized interceptor with seamless logout.
- **Home / Dashboard**:
  - Member greeting and profile avatar.
  - Dynamic Membership Hero banner (status, progress bar, days remaining, validity dates).
  - Outstanding invoice alerts.
  - Stat tiles (Streak, Monthly visits, Today's check-in status).
  - Today's workout plan overview / rest day card.
  - Upcoming booked classes.
  - Quick action grid (Billing, Membership, Refer & earn, Gym pass).
- **Train (Workout & Nutrition)**:
  - Interactive weekday selector (Mon–Sun).
  - Daily routine with sets, reps, rest seconds, and notes.
  - On-device daily exercise check-off with persistent state and haptics.
  - Nutrition plan with daily calorie target and meal guide.
- **Classes & Bookings**:
  - 14-day horizontal schedule strip.
  - Filter classes by "All classes" vs "My bookings".
  - Capacity progress bar and spots remaining.
  - Book class & Cancel booking with confirmation dialog.
- **Activity & Attendance**:
  - 15-week GitHub-style visit consistency heatmap.
  - Streak and 120-day attendance metrics.
  - Check-in/check-out logs with RFID / Biometric / QR method indicators.
- **Gym Pass (Gate Access)**:
  - High-contrast QR code generated from member registration number.
  - Instant front desk and turnstile scanner validation.
- **Billing & Payments**:
  - Invoices tab with expandable items, discount, tax, total, and balance.
  - Payment receipt history (Cash, eSewa, Khalti, Card).
- **Refer & Earn**:
  - Referral code sharing via native OS share sheet.
  - Milestone progress bar and reward codes.
  - Referral status tracking.
- **Profile & Settings**:
  - Personal details editor (Email, Address, Emergency contact, Health conditions, Goals).
  - Gym-managed read-only fields.

## Project Structure

```
lib/
├── main.dart                      # App entry point, Provider setup, Theme
├── theme/
│   └── app_theme.dart             # GymOS design tokens, Material 3 theme & Outfit typography
├── models/
│   └── models.dart                # Dart models with JSON serialization
├── services/
│   ├── config.dart                # API origin and media resolver (10.0.2.2 / LAN / localhost)
│   ├── api_service.dart           # HTTP client with Bearer auth, timeouts & error handling
│   └── storage_service.dart       # SharedPreferences wrapper
├── utils/
│   └── format.dart                # Nepal UTC+5:45 time formatting, currency (Rs.), dates
├── providers/
│   ├── auth_provider.dart         # Authentication state & OTP flow
│   ├── branding_provider.dart     # Public gym branding (name, logo, address, phone)
│   └── gym_provider.dart          # Member portal state, bookings, notifications, profile
├── widgets/
│   └── ui_components.dart         # Design system (Cards, Badges, Buttons, Progress, Avatars, etc.)
└── screens/
    ├── login_screen.dart          # Phone number + OTP code verification
    ├── main_navigation.dart       # Bottom navigation tab controller
    ├── tabs/
    │   ├── home_tab.dart          # Dashboard
    │   ├── train_tab.dart         # Workout & Diet routines
    │   ├── classes_tab.dart       # Classes schedule & bookings
    │   ├── activity_tab.dart      # Heatmap & attendance logs
    │   └── profile_tab.dart       # Member profile & settings
    └── sub_screens/
        ├── pass_screen.dart       # Fullscreen QR gym pass
        ├── membership_screen.dart # Membership details & catalog
        ├── billing_screen.dart    # Invoices & payment receipts
        ├── notifications_screen.dart # Notification center
        ├── referrals_screen.dart  # Refer & earn program
        └── edit_profile_screen.dart # Profile editor
```

## Running the App

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected device or emulator
flutter run
```

### Environments (local / staging / production)

Per-environment settings live in `env/*.json` (`APP_ENV`, `API_ORIGIN`). Edit the URLs, then:

```bash
flutter run --dart-define-from-file=env/local.json
flutter build apk --dart-define-from-file=env/staging.json
flutter build appbundle --release --dart-define-from-file=env/production.json
```

Production builds (`APP_ENV=production`) ignore the in-app server-URL override. Backend env profiles are in the GymOS repo under `env/` (`local.env.example`, `production.env.example`).

> **Legacy note**: By default, the app connects to port `5001` (`http://10.0.2.2:5001` for Android emulator and `http://localhost:5001` for iOS/desktop). To customize, update `AppConfig.customOrigin` in `lib/services/config.dart`.
