class UserErrorMessage {
  static String fromException(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return fallback;

    final lower = raw.toLowerCase();
    if (lower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('socketexception')) {
      return 'Unable to connect right now. Please check your connection and try again.';
    }
    if (lower.contains('firebaseauthexception')) {
      return 'Authentication failed. Please try again.';
    }

    return fallback;
  }

  static String sanitizeServerMessage(String? message, {required String fallback}) {
    if (message == null) return fallback;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return fallback;

    final lower = trimmed.toLowerCase();
    final looksTechnical = lower.contains('exception') ||
        lower.contains('uri=') ||
        lower.contains('stack') ||
        lower.contains('http://') ||
        lower.contains('https://');

    return looksTechnical ? fallback : trimmed;
  }
}