import 'package:flutter/foundation.dart';

class ApiBase {
  static const String _prodFallbackOrigin =
      'https://atahbracha.com';

  static String get origin {
    const configured = String.fromEnvironment('API_ORIGIN');
    if (configured.isNotEmpty) {
      if (kIsWeb && Uri.base.scheme == 'https' && configured.startsWith('http://')) {
        // Prevent mixed-content failures in production web builds.
        return Uri.base.origin;
      }
      return configured;
    }

    if (kIsWeb) {
      final current = Uri.base;
      final isLoopback = current.host == 'localhost' || current.host == '127.0.0.1';
      if (isLoopback) {
        final scheme = current.scheme.isEmpty ? 'http' : current.scheme;
        return '$scheme://${current.host}:3000';
      }
      if (current.host == 'atahbracha.com' || current.host == 'www.atahbracha.com') {
        return _prodFallbackOrigin;
      }
      return current.origin;
    }

    // Native defaults for local development.
    // - Android emulator maps host loopback to 10.0.2.2
    // - iOS simulator and desktop can usually use 127.0.0.1
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  static String get api => '$origin/api';

  static Uri uri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse('$api$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }

    final cleanQuery = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        cleanQuery[key] = value.toString();
      }
    });

    return baseUri.replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  static String absolute(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$origin$value';
    }
    return value;
  }
}