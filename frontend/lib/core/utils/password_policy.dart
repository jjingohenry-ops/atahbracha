class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 64;

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');

  static final Set<String> _commonPasswords = {
    'password',
    'password123',
    'qwerty',
    'qwerty123',
    '12345678',
    'letmein',
    'admin123',
    'welcome123',
  };

  static String sanitize(String value) {
    return value.trim();
  }

  static String? validate(
    String? value, {
    String? email,
    String? firstName,
    String? lastName,
    bool requireStrong = true,
  }) {
    final password = sanitize(value ?? '');
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (password.length > maxLength) {
      return 'Password cannot exceed $maxLength characters';
    }
    if (password.contains(RegExp(r'\s'))) {
      return 'Password cannot contain spaces';
    }

    final lowered = password.toLowerCase();
    if (_commonPasswords.contains(lowered)) {
      return 'Choose a less common password';
    }

    if (email != null && email.trim().isNotEmpty) {
      final localPart = email.trim().split('@').first.toLowerCase();
      if (localPart.isNotEmpty && lowered.contains(localPart)) {
        return 'Password should not include your email name';
      }
    }

    for (final part in [firstName, lastName]) {
      final token = (part ?? '').trim().toLowerCase();
      if (token.length >= 3 && lowered.contains(token)) {
        return 'Password should not include personal names';
      }
    }

    if (requireStrong) {
      if (!_upper.hasMatch(password)) return 'Include at least one uppercase letter';
      if (!_lower.hasMatch(password)) return 'Include at least one lowercase letter';
      if (!_digit.hasMatch(password)) return 'Include at least one number';
      if (!_special.hasMatch(password)) return 'Include at least one special character';
    }

    return null;
  }
}