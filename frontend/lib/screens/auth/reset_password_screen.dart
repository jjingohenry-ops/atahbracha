import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/password_policy.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Step 1: Request reset email',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _sendResetEmail,
            child: const Text('Send Reset Email'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Step 2: Complete reset with code',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Copy the reset code from your email link and set a new password below.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Reset Code (oobCode)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _completeReset,
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnack('Please enter a valid email address.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(email);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnack('Password reset email sent to $email.');
    } else {
      _showSnack(authProvider.errorMessage ?? 'Unable to send reset email.', isError: true);
    }
  }

  Future<void> _completeReset() async {
    final code = _codeController.text.trim();
    final password = PasswordPolicy.sanitize(_newPasswordController.text);
    final confirm = PasswordPolicy.sanitize(_confirmPasswordController.text);

    if (code.isEmpty) {
      _showSnack('Enter the reset code from your email.', isError: true);
      return;
    }

    final passwordError = PasswordPolicy.validate(password);
    if (passwordError != null) {
      _showSnack(passwordError, isError: true);
      return;
    }

    if (password != confirm) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.confirmPasswordReset(code, password);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnack('Password reset successful. You can now sign in.');
      Navigator.of(context).pop();
    } else {
      _showSnack(authProvider.errorMessage ?? 'Unable to reset password.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
