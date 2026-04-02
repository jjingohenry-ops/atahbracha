import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int _resendCooldownSeconds = 30;

  int _cooldown = 0;
  bool _isSending = false;
  bool _isChecking = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldown > 0 || _isSending) return;

    setState(() => _isSending = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendEmailVerification();
    if (!mounted) return;

    setState(() => _isSending = false);

    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Check your inbox.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to send verification email')),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final verified = await authProvider.reloadAndCheckVerification();
    if (!mounted) return;

    setState(() => _isChecking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not verified yet. Please verify and try again.')),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final userEmail = authProvider.user?.email ?? '';
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mark_email_read_outlined, size: 56, color: Color(0xFF13EC5B)),
                          const SizedBox(height: 16),
                          const Text(
                            'Verify Your Email',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userEmail.isEmpty
                                ? 'We sent a verification link to your email.'
                                : 'We sent a verification link to $userEmail',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isChecking ? null : _checkVerificationStatus,
                              child: _isChecking
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('I Have Verified My Email'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: (_cooldown > 0 || _isSending) ? null : _resendVerificationEmail,
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      _cooldown > 0
                                          ? 'Resend in ${_cooldown}s'
                                          : 'Resend Verification Email',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              await authProvider.signOut();
                              if (!mounted) return;
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            child: const Text('Use a different account'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
