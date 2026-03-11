import 'package:flutter/material.dart';

class SimpleTestScreen extends StatelessWidget {
  const SimpleTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Test'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Simple Test Screen'),
            SizedBox(height: 20),
            Text('If you can see this, the app is working!'),
          ],
        ),
      ),
    );
  }
}
