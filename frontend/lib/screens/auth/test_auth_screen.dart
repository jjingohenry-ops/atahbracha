import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  String _status = 'Checking Firebase...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseAuth();
  }

  void _checkFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      setState(() {
        _status = 'Firebase Auth is working!\nCurrent user: ${currentUser?.email ?? "Not signed in"}';
      });
    } catch (e) {
      setState(() {
        _status = 'Firebase Auth Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
