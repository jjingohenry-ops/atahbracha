/// Application-wide constants following best practices
class AppConstants {
  // App Information
  static const String appName = 'SmartLivestock Manager';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Livestock Management System';
  
  // API Configuration
  static const String baseUrl = 'https://atahbracha.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String rememberMeKey = 'remember_me';
  static const String themeKey = 'theme_preference';
  static const String languageKey = 'language_preference';
  static const String onboardingCompleteKey = 'onboarding_complete';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'atahbracah';
  
  // UI Constants
  static const double defaultPadding = 16;
  static const double cardRadius = 12;
  static const double buttonRadius = 8;
  static const double dialogRadius = 16;
  static const double bottomSheetRadius = 20;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration splashScreenDuration = Duration(seconds: 2);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(days: 7);
  static const Duration shortCacheDuration = Duration(minutes: 15);
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // Network
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration networkTimeout = Duration(seconds: 30);
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];
  
  // Logging
  static const bool enableLogging = true;
  static const int maxLogSize = 1000; // Maximum log entries
  
  // Performance
  static const int maxConcurrentRequests = 5;
  static const Duration debounceDelay = Duration(milliseconds: 300);
}

/// Environment-specific constants
abstract class EnvironmentConstants {
  static const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
  static const bool isProfileMode = bool.fromEnvironment('dart.vm.profile');
  static const bool isReleaseMode = bool.fromEnvironment('dart.vm.product') == true;
  
  static String get environment {
    if (isDebugMode) {
      return 'debug';
    }
    if (isProfileMode) {
      return 'profile';
    }
    if (isReleaseMode) {
      return 'release';
    }
    return 'unknown';
  }
}

/// API Endpoints
class ApiEndpoints {
  // Base
  static String get apiBase => '${AppConstants.baseUrl}/${AppConstants.apiVersion}';
  
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
  // Users
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile/update';
  
  // Animals
  static const String animals = '/animals';
  static String animalDetails(String id) => '/animals/$id';
  static const String addAnimal = '/animals';
  static String updateAnimal(String id) => '/animals/$id';
  static String deleteAnimal(String id) => '/animals/$id';
  
  // Farms
  static const String farms = '/farms';
  static String farmDetails(String id) => '/farms/$id';
  
  // Health Records
  static const String healthRecords = '/health-records';
  static String healthRecordDetails(String id) => '/health-records/$id';
  
  // Feed Logs
  static const String feedLogs = '/feed-logs';
  static String feedLogDetails(String id) => '/feed-logs/$id';
  
  // Reports
  static const String reports = '/reports';
  static const String generateReport = '/reports/generate';
}

/// Error Messages
class ErrorMessages {
  // Network Errors
  static const String noInternet = 'No internet connection';
  static const String serverError = 'Server error occurred';
  static const String timeout = 'Request timed out';
  static const String unauthorized = 'Unauthorized access';
  static const String forbidden = 'Access forbidden';
  static const String notFound = 'Resource not found';
  
  // Validation Errors
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String invalidEmail = 'Invalid email format';
  static const String passwordTooShort = 'Password must be at least ${AppConstants.minPasswordLength} characters';
  static const String passwordTooWeak = 'Password is too weak';
  static const String usernameRequired = 'Username is required';
  static const String usernameTooLong = 'Username is too long';
  
  // Business Logic Errors
  static const String animalNotFound = 'Animal not found';
  static const String duplicateAnimal = 'Animal already exists';
  static const String invalidAnimalData = 'Invalid animal data';
  static const String farmNotFound = 'Farm not found';
  
  // General Errors
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgain = 'Please try again';
  static const String contactSupport = 'Please contact support';
  static const String operationFailed = 'Operation failed';
}

/// Success Messages
class SuccessMessages {
  // Authentication
  static const String loginSuccess = 'Login successful';
  static const String registrationSuccess = 'Registration successful';
  static const String logoutSuccess = 'Logout successful';
  static const String passwordResetSuccess = 'Password reset successful';
  
  // Profile
  static const String profileUpdated = 'Profile updated successfully';
  static const String profilePictureUpdated = 'Profile picture updated successfully';
  
  // Animals
  static const String animalAdded = 'Animal added successfully';
  static const String animalUpdated = 'Animal updated successfully';
  static const String animalDeleted = 'Animal deleted successfully';
  
  // General
  static const String operationSuccessful = 'Operation successful';
  static const String dataSaved = 'Data saved successfully';
  static const String dataLoaded = 'Data loaded successfully';
}

/// Validation Patterns
class ValidationPatterns {
  static const String email = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String password = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
  static const String phone = r'^\+?[\d\s\-\(\)]{10,}$';
  static const String username = r'^[a-zA-Z0-9_]{3,}$';
  static const String name = r'^[a-zA-Z\s]{2,}$';
  static const String alphanumeric = r'^[a-zA-Z0-9]+$';
  static const String numeric = r'^\d+$';
  static const String url = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
}
