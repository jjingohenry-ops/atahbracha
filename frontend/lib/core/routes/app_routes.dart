import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/reminders/reminders_screen.dart';
import '../../screens/animals/animals_screen.dart';
import '../../screens/marketing/marketing_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String splash = '/splash';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String reminders = '/reminders';
  static const String animals = '/animals';
  static const String marketing = '/marketing';
  static const String addAnimal = '/add-animal';
  static const String editAnimal = '/edit-animal';
  static const String feedLogs = '/feed-logs';
  static const String healthRecords = '/health-records';
  static const String reports = '/reports';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case '/reminders':
        return MaterialPageRoute(
          builder: (_) => const RemindersScreen(),
          settings: settings,
        );
      case '/animals':
        return MaterialPageRoute(
          builder: (_) => const AnimalsScreen(),
          settings: settings,
        );
      case '/marketing':
        return MaterialPageRoute(
          builder: (_) => const MarketingScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (_) => const LoginScreen(),
      home: (_) => const HomeScreen(),
      '/settings': (_) => const SettingsScreen(),
      '/reminders': (_) => const RemindersScreen(),
      '/animals': (_) => const AnimalsScreen(),
      '/marketing': (_) => const MarketingScreen(),
    };
  }
}

class RouteArguments {
  final String? animalId;
  final String? userId;
  final Map<String, dynamic>? data;

  RouteArguments({
    this.animalId,
    this.userId,
    this.data,
  });

  static RouteArguments? fromRouteSettings(RouteSettings settings) {
    if (settings.arguments is RouteArguments) {
      return settings.arguments as RouteArguments;
    }
    return null;
  }
}
