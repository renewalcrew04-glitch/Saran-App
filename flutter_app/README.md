# SARAN Flutter App

Flutter mobile application for SARAN - A social wellness platform.

## 🚀 Features

- **Social Feed** - Post, like, comment, repost
- **User Profiles** - View and edit profiles
- **Direct Messaging** - Chat with other users
- **Events** - Create and attend events
- **SFrames** - Story-like temporary content
- **SOS** - Emergency location sharing
- **Wellness Tracking** - Wellness streaks and activities
- **Explore** - Discover new content and people

## 📋 Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode (for mobile builds)
- Backend API running (see backend README)

## 🛠️ Installation

1. Clone the repository:
```bash
git clone <gitlab-repo-url>
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API endpoint:
   - Update `lib/config/api_config.dart` with your backend URL
   - Set `API_BASE_URL` to your backend API endpoint

4. Run the app:
```bash
# Development
flutter run

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

## 📁 Project Structure

```
flutter_app/
├── lib/
│   ├── config/           # Configuration (API, constants)
│   ├── models/           # Data models
│   ├── services/         # API services
│   ├── providers/        # State management (Provider/GetX)
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable widgets
│   ├── routes/           # Navigation routes
│   ├── utils/            # Utilities
│   └── main.dart         # Entry point
├── assets/               # Images, icons, sounds
├── pubspec.yaml          # Dependencies
└── README.md             # This file
```

## 🔌 API Integration

The app connects to the backend API. Ensure the backend is running and configured:

- Base URL: Configured in `lib/config/api_config.dart`
- Authentication: JWT tokens stored securely
- API endpoints: Defined in `lib/services/`

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ⚠️ Web (limited support)

## 🧪 Testing

```bash
flutter test
```

## 📄 License

ISC
