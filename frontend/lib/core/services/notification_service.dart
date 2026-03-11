import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;

  // Show success snackbar
  void showSuccess(String message, {String? title, Duration? duration}) {
    AppLogger.info('Success notification: $message', tag: 'NOTIFICATION');
    _showSnackBar(
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      title: title,
      duration: duration,
    );
  }

  // Show error snackbar
  void showError(String message, {String? title, Duration? duration}) {
    AppLogger.error('Error notification: $message', tag: 'NOTIFICATION');
    _showSnackBar(
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      title: title,
      duration: duration,
    );
  }

  // Show warning snackbar
  void showWarning(String message, {String? title, Duration? duration}) {
    AppLogger.warning('Warning notification: $message', tag: 'NOTIFICATION');
    _showSnackBar(
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      title: title,
      duration: duration,
    );
  }

  // Show info snackbar
  void showInfo(String message, {String? title, Duration? duration}) {
    AppLogger.info('Info notification: $message', tag: 'NOTIFICATION');
    _showSnackBar(
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      title: title,
      duration: duration,
    );
  }

  // Show custom snackbar
  void showCustom({
    required String message,
    required Color backgroundColor,
    IconData? icon,
    String? title,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: backgroundColor,
      icon: icon,
      title: title,
      duration: duration,
      action: action,
    );
  }

  // Show loading snackbar
  void showLoading(String message, {String? title}) {
    _showSnackBar(
      message,
      backgroundColor: Colors.blue,
      icon: Icons.hourglass_empty,
      title: title,
      duration: const Duration(seconds: 30), // Long duration for loading
    );
  }

  // Hide current snackbar
  void hideCurrent() {
    _scaffoldKey.currentState?.hideCurrentSnackBar();
  }

  // Show dialog
  Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result;
  }

  // Show info dialog
  Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Show bottom sheet
  Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
    );
  }

  // Private method to show snackbar
  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    IconData? icon,
    String? title,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    _scaffoldKey.currentState?.showSnackBar(snackBar);
  }
}
