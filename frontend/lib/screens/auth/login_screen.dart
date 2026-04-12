import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
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
            // Header
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
                      'Atahbracah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    
                    // Tabs
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
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                    
                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF2A2E2B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF13EC5B),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? colorScheme.surfaceContainerHighest.withOpacity(0.45)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email address';
                                }

                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }

                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF2A2E2B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                hintText: 'Your password',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF13EC5B),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? colorScheme.surfaceContainerHighest.withOpacity(0.45)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            // Forgot Password
                            if (!_isSignUp)
                              Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
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
                            
                            // Sign Up Additional Fields
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF13EC5B),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colorScheme.surfaceContainerHighest.withOpacity(0.45)
                                      : Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF13EC5B),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colorScheme.surfaceContainerHighest.withOpacity(0.45)
                                      : Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                              
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Error Message
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
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            
                            // Primary Action Button
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFFE8F5E8),
                                    thickness: 1,
                                  ),
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
                                  child: Divider(
                                    color: Color(0xFFE8F5E8),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Google Sign In
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                child: Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                  backgroundColor: isDark
                                      ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Phone Sign In
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _showPhoneSignIn,
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  'Continue with Phone',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.green.withOpacity(0.2),
                                  ),
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
                    
                    // Footer
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
                                    onTap: () {
                                      // TODO: Implement terms of service
                                    },
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
                                    onTap: () {
                                      // TODO: Implement privacy policy
                                    },
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

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final inputEmail = _emailController.text.trim();
      
      if (_isSignUp) {
        final success = await authProvider.signUp(
          inputEmail,
          _passwordController.text,
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
        );
        if (!success) throw Exception(authProvider.errorMessage ?? 'Sign up failed');

        final sent = await authProvider.sendEmailVerification();
        if (!sent) {
          throw Exception(authProvider.errorMessage ?? 'Failed to send verification email');
        }
      } else {
        final success = await authProvider.signIn(
          inputEmail,
          _passwordController.text,
        );
        if (!success) throw Exception(authProvider.errorMessage ?? 'Sign in failed');
      }
      
      if (mounted) {
        if (authProvider.requiresEmailVerification) {
          Navigator.of(context).pushReplacementNamed('/verify-email');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
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
      
      if (mounted) {
        if (authProvider.requiresEmailVerification) {
          Navigator.of(context).pushReplacementNamed('/verify-email');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPhoneSignIn() {
    showDialog(
      context: context,
      builder: (context) => PhoneSignInDialog(
        onSendCode: (phoneNumber) async {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final verificationId = await authProvider.requestPhoneVerificationCode(phoneNumber);

            if (verificationId != null && verificationId.isNotEmpty) {
              if (!mounted) return;
              _showCodeVerificationDialog(phoneNumber, verificationId);
            } else {
              if (!mounted) return;
              setState(() {
                _errorMessage = authProvider.errorMessage ?? 'Unable to send verification code.';
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Phone sign-in failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCodeVerificationDialog(String phoneNumber, String verificationId) {
    showDialog(
      context: context,
      builder: (context) => CodeVerificationDialog(
        phoneNumber: phoneNumber,
        onVerify: (code) async {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final success = await authProvider.verifyPhoneCode(verificationId, code);
            if (success && mounted) {
              if (authProvider.requiresEmailVerification) {
                Navigator.of(context).pushReplacementNamed('/verify-email');
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// Phone Sign In Dialog
class PhoneSignInDialog extends StatefulWidget {
  final Future<void> Function(String phoneNumber) onSendCode;

  const PhoneSignInDialog({super.key, required this.onSendCode});

  @override
  State<PhoneSignInDialog> createState() => _PhoneSignInDialogState();
}

class _PhoneSignInDialogState extends State<PhoneSignInDialog> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Phone Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your phone number'),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1234567890',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Code'),
        ),
      ],
    );
  }

  void _sendCode() {
    if (_phoneController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      widget.onSendCode(_phoneController.text.trim()).whenComplete(() {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

// Code Verification Dialog
class CodeVerificationDialog extends StatefulWidget {
  final String phoneNumber;
  final Function(String code) onVerify;

  const CodeVerificationDialog({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
  });

  @override
  State<CodeVerificationDialog> createState() => _CodeVerificationDialogState();
}

class _CodeVerificationDialogState extends State<CodeVerificationDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter the verification code sent to ${widget.phoneNumber}'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
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

  void _verifyCode() {
    if (_codeController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      widget.onVerify(_codeController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
