import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Navigation service for centralized navigation management
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Get the singleton instance
  static NavigationService get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get navigator context
  BuildContext? get context => navigatorKey.currentContext;

  /// Get navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  /// Navigate to a named route
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    AppLogger.navigation(routeName);
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to a route and replace current
  Future<T?> navigateToAndReplace<T, TO>(String routeName, {Object? arguments}) {
    AppLogger.navigation(routeName);
    return navigator!.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  /// Navigate to a route and remove all previous routes
  Future<T?> navigateToAndRemoveUntil<T>(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    AppLogger.navigation(routeName);
    return navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Navigate back
  void goBack<T>({T? result}) {
    AppLogger.navigation('back');
    navigator!.pop<T>(result);
  }

  /// Check if can go back
  bool canGoBack() {
    return navigator!.canPop();
  }

  /// Push a new route
  Future<T?> push<T>(Route<T> route) {
    AppLogger.navigation('push');
    return navigator!.push<T>(route);
  }

  /// Push a replacement route
  Future<T?> pushReplacement<T, TO>(Route<T> route) {
    AppLogger.navigation('pushReplacement');
    return navigator!.pushReplacement<T, TO>(route);
  }

  /// Push and remove until
  Future<T?> pushAndRemoveUntil<T>(Route<T> route, RoutePredicate predicate) {
    AppLogger.navigation('pushAndRemoveUntil');
    return navigator!.pushAndRemoveUntil<T>(route, predicate);
  }

  /// Pop until specific route
  void popUntil(String routeName) {
    navigator!.popUntil(ModalRoute.withName(routeName));
  }

  /// Show dialog
  Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    assert(context != null, 'Context is null. Make sure the app is fully initialized.');
    return showGeneralDialog<T>(
      context: context!,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Show snackbar
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    assert(context != null, 'Context is null. Make sure the app is fully initialized.');
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
    );
    ScaffoldMessenger.of(context!).showSnackBar(snackBar);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
    );
  }

  /// Show warning snackbar
  void showWarningSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      textColor: Colors.white,
    );
  }

  /// Show loading dialog
  Future<void> showLoadingDialog({
    String? message,
    bool barrierDismissible = false,
  }) {
    assert(context != null, 'Context is null. Make sure the app is fully initialized.');
    return showDialog(
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    if (navigator != null && navigator!.canPop()) {
      navigator!.pop();
    }
  }

  /// Show confirmation dialog
  Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? cancelColor,
  }) {
    assert(context != null, 'Context is null. Make sure the app is fully initialized.');
    return showDialog<bool>(
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor,
            ),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet
  Future<T?> showBottomSheet<T>({
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
  }) {
    assert(context != null, 'Context is null. Make sure the app is fully initialized.');
    return showModalBottomSheet<T>(
      context: context!,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      routeSettings: routeSettings,
    );
  }
}
