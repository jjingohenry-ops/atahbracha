import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/services/navigation_service.dart';
import 'core/themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

/// Environment configuration
enum Environment { dev, staging, prod }

/// App configuration
class AppConfig {
  static late Environment _environment;
  static late String _baseUrl;
  static late bool _enableLogging;
  static late bool _enableCrashReporting;

  /// Initialize configuration
  static Future<void> initialize({
    Environment environment = Environment.dev,
  }) async {
    _environment = environment;

    switch (environment) {
      case Environment.dev:
        _baseUrl = 'https://atahbracha.com';
        _enableLogging = true;
        _enableCrashReporting = false;
        break;
      case Environment.staging:
        _baseUrl = 'https://atahbracha.com';
        _enableLogging = true;
        _enableCrashReporting = true;
        break;
      case Environment.prod:
        _baseUrl = 'https://atahbracha.com';
        _enableLogging = kDebugMode;
        _enableCrashReporting = true;
        break;
    }

    // Initialize dependency injection
    await DependencyInjection.init();
  }

  /// Get current environment
  static Environment get environment => _environment;

  /// Get base URL
  static String get baseUrl => _baseUrl;

  /// Check if logging is enabled
  static bool get enableLogging => _enableLogging;

  /// Check if crash reporting is enabled
  static bool get enableCrashReporting => _enableCrashReporting;

  /// Check if it's debug mode
  static bool get isDebug => kDebugMode;

  /// Check if it's release mode
  static bool get isRelease => kReleaseMode;

  /// Check if it's profile mode
  static bool get isProfile => kProfileMode;

  /// Get app name based on environment
  static String get appName {
    switch (_environment) {
      case Environment.dev:
        return 'SmartLivestock (Dev)';
      case Environment.staging:
        return 'SmartLivestock (Staging)';
      case Environment.prod:
        return 'SmartLivestock Manager';
    }
  }

  /// Get flavor name
  static String get flavorName => _environment.name.toUpperCase();
}

/// Main application widget
class SmartLivestockApp extends StatelessWidget {
  const SmartLivestockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => serviceLocator.get<AuthProvider>()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: AppConfig.isDebug,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: NavigationService.instance.navigatorKey,
        home: const AuthWrapper(),
        routes: _buildRoutes(),
        builder: (context, child) {
          return _AppBuilder(child: child);
        },
      ),
    );
  }

  /// Build application routes
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      // Add other routes as needed
    };
  }
}

/// App builder for global error handling and theming
class _AppBuilder extends StatelessWidget {
  final Widget? child;

  const _AppBuilder({this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (child != null) child!,
          // Add global overlay widgets here (loading indicators, etc.)
        ],
      ),
    );
  }
}

/// Authentication wrapper
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add any initialization logic here
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const _SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const _SplashScreen();
        }

        if (authProvider.user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

/// Splash screen widget
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppConfig.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error boundary for catching Flutter errors
class AppErrorBoundary extends StatelessWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Something went wrong'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.isDebug ? errorDetails.exception.toString() : 'Please restart the app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app logic
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    };

    return child;
  }
}
