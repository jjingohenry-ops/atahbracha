# Atahbracah - Flutter App

A comprehensive animal management application built with Flutter, featuring Firebase authentication, real-time data synchronization, and a modern, responsive UI.

## 🚀 Features

### Authentication & Security
- **Firebase Authentication** with multiple sign-in methods:
  - Email/Password
  - Google Sign-In
  - Phone Authentication
- Secure token-based authentication
- User profile management
- Password reset functionality

### Livestock Management
- **Animal Records Management**
  - Add, edit, and delete animal records
  - Track animal health status
  - Monitor growth and development
- **Feed Management**
  - Feed logging and scheduling
  - Feed inventory tracking
  - Nutrition monitoring
- **Health Records**
  - Veterinary visits tracking
  - Vaccination schedules
  - Medical history management
- **Farm Analytics**
  - Dashboard with key metrics
  - Performance reports
  - Data visualization

### Technical Features
- **Offline Support** - Works without internet connection
- **Real-time Sync** - Automatic data synchronization
- **Cross-platform** - Runs on iOS, Android, and Web
- **Responsive Design** - Optimized for all screen sizes
- **Dark/Light Theme** - Customizable user experience

## 📱 Screenshots

*(Add screenshots of your app here)*

## 🛠 Technology Stack

### Frontend (Flutter)
- **Flutter 3.11.1+** - Cross-platform UI framework
- **Provider** - State management
- **Firebase SDK** - Authentication and real-time database
- **Dio** - HTTP client for API calls
- **Shared Preferences** - Local storage

### Backend Integration
- **Node.js/Express** - REST API backend
- **Firebase Admin SDK** - Server-side authentication
- **PostgreSQL (Aurora)** - Primary database
- **JWT** - Token-based authentication

## 📁 Project Structure

```
lib/
├── core/                          # Core application components
│   ├── constants/                 # App constants and configuration
│   │   └── app_constants.dart
│   ├── routes/                    # Navigation and routing
│   │   └── app_routes.dart
│   ├── services/                 # Core services
│   │   ├── notification_service.dart
│   │   └── storage_service.dart
│   ├── themes/                    # App themes and styling
│   │   └── app_theme.dart
│   ├── utils/                     # Utility functions
│   │   ├── app_logger.dart
│   │   └── validators.dart
│   └── widgets/                   # Reusable UI components
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── loading_widget.dart
├── models/                        # Data models
│   └── user.dart
├── providers/                     # State management
│   └── auth_provider.dart
├── screens/                       # UI screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   └── splash/
│       └── splash_screen.dart
└── services/                      # API and external services
    ├── api_service.dart
    └── auth_service.dart
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK 3.11.1 or higher**
- **Dart SDK**
- **Android Studio** (for Android development)
- **Xcode** (for iOS development - macOS only)
- **VS Code** or **Android Studio** (IDE)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smartlivestock_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email, Google, Phone)
   - Download the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
   - Place them in the appropriate directories:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. **Configure Firebase**
   - Update `lib/firebase_options.dart` with your Firebase configuration
   - Follow the platform-specific setup instructions below

5. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android Setup
1. **Minimum SDK**: Set `minSdkVersion 21` in `android/app/build.gradle`
2. **Permissions**: Add required permissions in `android/app/src/main/AndroidManifest.xml`
3. **Firebase**: Follow [Firebase Android setup guide](https://firebase.google.com/docs/android/setup)

#### iOS Setup
1. **Minimum iOS Version**: Set `IPHONEOS_DEPLOYMENT_TARGET = 12.0` in `ios/Podfile`
2. **Firebase**: Follow [Firebase iOS setup guide](https://firebase.google.com/docs/ios/setup)
3. **Permissions**: Add required permissions in `ios/Runner/Info.plist`

#### Web Setup
1. **Firebase**: Add web app configuration in Firebase Console
2. **Update**: Modify `web/index.html` with Firebase SDK initialization

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:

```env
# Firebase Configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# API Configuration
API_BASE_URL=http://localhost:3000
```

### Firebase Configuration
Update `lib/firebase_options.dart` with your Firebase project settings:

```dart
const FirebaseOptions options = FirebaseOptions(
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id",
  measurementId: "your-measurement-id",
);
```

## 📱 Usage

### Authentication Flow
1. **Launch App** → Splash Screen
2. **Login/Register** → Choose authentication method
3. **Dashboard** → View livestock overview
4. **Manage Animals** → Add/edit/delete animals
5. **Track Activities** → Feed logs, health records

### Key Features
- **Dashboard**: Real-time overview of farm statistics
- **Animal Management**: Complete CRUD operations for animal records
- **Feed Tracking**: Log and monitor feeding schedules
- **Health Monitoring**: Track veterinary visits and treatments
- **Reports**: Generate performance and health reports

## 🧪 Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Testing Strategy
- **Unit Tests**: Test business logic and utilities
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows

## 📦 Build & Deployment

### Development Build
```bash
# Debug build
flutter run --debug

# Profile build
flutter run --profile
```

### Production Build

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build iOS app
flutter build ios --release
```

#### Web
```bash
# Build web app
flutter build web --release
```

## 🔍 Code Quality

### Linting
```bash
# Run Flutter analyzer
flutter analyze

# Fix issues automatically
dart fix --apply
```

### Formatting
```bash
# Format code
dart format .
```

### Best Practices
- **State Management**: Use Provider for global state
- **Architecture**: Follow clean architecture principles
- **Code Style**: Follow Dart/Flutter conventions
- **Error Handling**: Implement proper error boundaries
- **Logging**: Use AppLogger for consistent logging

## 🐛 Troubleshooting

### Common Issues

#### Firebase Authentication Issues
- **Solution**: Verify Firebase configuration and enable required authentication methods
- **Check**: Firebase console settings and API keys

#### Build Issues
- **Android**: Check `minSdkVersion` and dependencies
- **iOS**: Verify Xcode setup and provisioning profiles
- **Web**: Ensure CORS configuration on backend

#### Performance Issues
- **Solution**: Use Flutter Inspector to identify performance bottlenecks
- **Optimize**: Implement lazy loading and proper state management

### Debug Mode
```bash
# Enable debug logging
flutter run --debug

# Check logs
flutter logs
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Review Guidelines
- Follow existing code style
- Add tests for new features
- Update documentation
- Ensure all tests pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- **Email**: support@smartlivestock.com
- **Documentation**: [Project Wiki](https://github.com/your-repo/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)

## 🗺️ Roadmap

### Upcoming Features
- [ ] **Offline Mode Enhancements** - Improved offline functionality
- [ ] **Push Notifications** - Real-time alerts and reminders
- [ ] **Advanced Analytics** - AI-powered insights
- [ ] **Multi-language Support** - Internationalization
- [ ] **Export/Import** - Data backup and restore
- [ ] **Integration APIs** - Third-party service integrations

### Version History
- **v1.0.0** - Initial release with core features
- **v1.1.0** - Enhanced offline support and UI improvements
- **v1.2.0** - Advanced analytics and reporting

---

**Built with ❤️ using Flutter**
