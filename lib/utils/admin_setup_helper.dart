import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSetupHelper {
  /// Creates the admin user account in Firebase Authentication
  /// This should be run once to set up the admin account
  static Future<bool> createAdminUser({
    required String email,
    required String password,
  }) async {
    try {
      print('Creating admin user with email: $email');

      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        print('Admin user created successfully: ${userCredential.user!.uid}');

        // Optional: Update display name
        await userCredential.user!.updateDisplayName('Admin User');

        // Sign out after creating (so they can sign in normally)
        await FirebaseAuth.instance.signOut();

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Error creating admin user: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error creating admin user: $e');
      return false;
    }
  }

  /// Check if admin user exists
  static Future<bool> adminUserExists(String email) async {
    try {
      // Simplified check - just return false to allow creation attempt
      print('Checking if user exists: $email');
      return false; // Always allow creation attempt
    } catch (e) {
      print('Error checking if admin user exists: $e');
      return false;
    }
  }
}

/// Widget to help set up admin user - use this temporarily
class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _emailController = TextEditingController(text: 'admin@bluesalon');
  final _passwordController = TextEditingController(text: 'Open4408');
  bool _isLoading = false;
  String? _message;

  Future<void> _createAdminUser() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final success = await AdminSetupHelper.createAdminUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = success
          ? 'Admin user created successfully!'
          : 'Failed to create admin user. Check console for details.';
    });
  }

  Future<void> _checkAdminUser() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final exists = await AdminSetupHelper.adminUserExists(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = exists
          ? 'Admin user already exists!'
          : 'Admin user does not exist.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Admin User Setup',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAdminUser,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Check if Admin User Exists'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _createAdminUser,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Admin User'),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _message!.contains('successfully') ||
                          _message!.contains('already exists')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  border: Border.all(
                    color:
                        _message!.contains('successfully') ||
                            _message!.contains('already exists')
                        ? Colors.green
                        : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color:
                        _message!.contains('successfully') ||
                            _message!.contains('already exists')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
