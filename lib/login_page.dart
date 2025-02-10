import 'package:flutter/material.dart';
import 'dashboard_page.dart'; // Import Dashboard Page

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Dashboard when Login button is pressed
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
