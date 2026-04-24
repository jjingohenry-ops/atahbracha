import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/password_policy.dart';
import '../../core/utils/user_error_message.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialSignUp = false});

  final bool initialSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isSignUp = widget.initialSignUp;
    _tabController.index = widget.initialSignUp ? 1 : 0;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: colorScheme.onSurface,
                  ),
                  Expanded(
                    child: Text(
                      'Atahbracha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.green.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF13EC5B),
                        labelColor: colorScheme.onSurface,
                        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        onTap: (index) {
                          setState(() {
                            _isSignUp = index == 1;
                            _errorMessage = null;
                          });
                        },
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: _fieldDecoration(
                                context,
                                isDark: isDark,
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _fieldDecoration(
                                context,
                                isDark: isDark,
                                labelText: 'Password',
                                hintText: 'Your password',
                                prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (!_isSignUp) {
                                  if (PasswordPolicy.sanitize(value ?? '').isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                }
                                return PasswordPolicy.validate(
                                  value,
                                  email: _emailController.text.trim(),
                                  firstName: _firstNameController.text.trim(),
                                  lastName: _lastNameController.text.trim(),
                                );
                              },
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: _fieldDecoration(
                                  context,
                                  isDark: isDark,
                                  labelText: 'Confirm Password',
                                  hintText: 'Re-enter your password',
                                  prefixIcon: const Icon(Icons.verified_user, color: Colors.grey),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (PasswordPolicy.sanitize(value ?? '').isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (PasswordPolicy.sanitize(value ?? '') !=
                                      PasswordPolicy.sanitize(_passwordController.text)) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (!_isSignUp)
                              Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.of(context).pushNamed('/reset-password'),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Color(0xFF13EC5B),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _firstNameController,
                                decoration: _fieldDecoration(
                                  context,
                                  isDark: isDark,
                                  labelText: 'First Name',
                                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: _fieldDecoration(
                                  context,
                                  isDark: isDark,
                                  labelText: 'Last Name',
                                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF13EC5B),
                                  foregroundColor: const Color(0xFF102216),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF13EC5B).withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF102216)),
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xFFE8F5E8), thickness: 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xFFE8F5E8), thickness: 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.withOpacity(0.2)),
                                  backgroundColor: isDark
                                      ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _showPhoneAuthDialog,
                                icon: const Icon(Icons.phone, color: Colors.grey),
                                label: Text(
                                  _isSignUp ? 'Sign Up with Phone' : 'Sign In with Phone',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.withOpacity(0.2)),
                                  backgroundColor: isDark
                                      ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'By continuing, you agree to our ',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pushNamed('/terms-of-service'),
                                    child: const Text(
                                      'Terms of Service',
                                      style: TextStyle(
                                        color: Color(0xFF13EC5B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pushNamed('/privacy-policy'),
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF13EC5B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Live Build: V(${AppConstants.buildLabel})',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 10,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required bool isDark,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF13EC5B), width: 2),
      ),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.45) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final inputEmail = _emailController.text.trim();
      final inputPassword = PasswordPolicy.sanitize(_passwordController.text);

      if (_isSignUp) {
        final success = await authProvider.signUp(
          inputEmail,
          inputPassword,
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
        );
        if (!success) throw Exception(authProvider.errorMessage ?? 'Sign up failed');

        final sent = await authProvider.sendEmailVerification();
        if (!sent) {
          throw Exception(authProvider.errorMessage ?? 'Failed to send verification email');
        }
      } else {
        final success = await authProvider.signIn(inputEmail, inputPassword);
        if (!success) throw Exception(authProvider.errorMessage ?? 'Sign in failed');
      }

      if (!mounted) return;
      if (authProvider.requiresEmailVerification) {
        Navigator.of(context).pushReplacementNamed('/verify-email');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = UserErrorMessage.fromException(
          e,
          fallback: 'Authentication failed. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      if (!success) throw Exception(authProvider.errorMessage ?? 'Google sign-in failed');

      if (!mounted) return;
      if (authProvider.requiresEmailVerification) {
        Navigator.of(context).pushReplacementNamed('/verify-email');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPhoneAuthDialog() async {
    final submission = await showDialog<PhoneAuthSubmission>(
      context: context,
      builder: (context) => PhoneAuthDialog(isSignUp: _isSignUp),
    );

    if (submission == null || !mounted) return;
    await _handlePhoneAuth(submission);
  }

  Future<void> _handlePhoneAuth(PhoneAuthSubmission submission) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (!submission.isSignUp) {
        final success = await authProvider.signInWithPhonePassword(
          submission.phoneNumber,
          submission.password,
        );
        if (!success) throw Exception(authProvider.errorMessage ?? 'Phone sign-in failed');
      } else {
        if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
          throw Exception('For phone sign-up, enter first and last name on the form first.');
        }

        final verificationId =
            await authProvider.requestPhoneVerificationCode(submission.phoneNumber);

        if (verificationId == null || verificationId.isEmpty) {
          throw Exception(authProvider.errorMessage ?? 'Unable to send verification code.');
        }

        if (!mounted) return;
        final verified = await showDialog<bool>(
          context: context,
          builder: (context) => CodeVerificationDialog(
            phoneNumber: submission.phoneNumber,
            onVerify: (code) async {
              return authProvider.verifyPhoneCode(verificationId, code);
            },
          ),
        );

        if (verified != true) {
          throw Exception(authProvider.errorMessage ?? 'Phone verification failed.');
        }

        final completed = await authProvider.completePhoneSignUp(
          phoneNumber: submission.phoneNumber,
          password: submission.password,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

        if (!completed) {
          throw Exception(authProvider.errorMessage ?? 'Phone sign-up failed.');
        }
      }

      if (!mounted) return;
      if (authProvider.requiresEmailVerification) {
        Navigator.of(context).pushReplacementNamed('/verify-email');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = UserErrorMessage.fromException(
          e,
          fallback: submission.isSignUp
              ? 'Phone sign-up failed. Please try again.'
              : 'Phone sign-in failed. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class PhoneAuthSubmission {
  const PhoneAuthSubmission({
    required this.phoneNumber,
    required this.password,
    required this.isSignUp,
  });

  final String phoneNumber;
  final String password;
  final bool isSignUp;
}

class PhoneAuthDialog extends StatefulWidget {
  const PhoneAuthDialog({super.key, required this.isSignUp});

  final bool isSignUp;

  @override
  State<PhoneAuthDialog> createState() => _PhoneAuthDialogState();
}

class _PhoneAuthDialogState extends State<PhoneAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSignUp ? 'Phone Sign Up' : 'Phone Sign In'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+2567XXXXXXXX',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final normalized = value?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
                if (normalized.isEmpty) return 'Enter phone number';
                if (!RegExp(r'^\+?[1-9][0-9]{7,14}$').hasMatch(normalized)) {
                  return 'Enter a valid international phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) => PasswordPolicy.validate(value),
            ),
            if (widget.isSignUp) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (value) {
                  if (PasswordPolicy.sanitize(value ?? '').isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (PasswordPolicy.sanitize(value ?? '') !=
                      PasswordPolicy.sanitize(_passwordController.text)) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            if (widget.isSignUp)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'An OTP will be sent from Firebase to verify your phone number.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              PhoneAuthSubmission(
                phoneNumber: _phoneController.text.trim(),
                password: PasswordPolicy.sanitize(_passwordController.text),
                isSignUp: widget.isSignUp,
              ),
            );
          },
          child: Text(widget.isSignUp ? 'Continue' : 'Sign In'),
        ),
      ],
    );
  }
}

class CodeVerificationDialog extends StatefulWidget {
  const CodeVerificationDialog({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
  });

  final String phoneNumber;
  final Future<bool> Function(String code) onVerify;

  @override
  State<CodeVerificationDialog> createState() => _CodeVerificationDialogState();
}

class _CodeVerificationDialogState extends State<CodeVerificationDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter the OTP sent to ${widget.phoneNumber}'),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verify,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.onVerify(code);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isLoading = false;
      _error = 'Verification failed. Please try again.';
    });
  }
}
