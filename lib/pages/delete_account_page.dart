import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pingpal/pages/auth_page.dart';
import 'package:pingpal/pages/login.dart';

import '../theme/app_theme.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔥 Delete Firestore user data (including subcollections)
  Future<void> _deleteUserData(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // 🔹 List all subcollections you use
    final subCollections = [
      'friends',
      'posts',
      'locations',
      'chats',
    ];

    for (final collection in subCollections) {
      final snapshot = await userRef.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // 🔹 Delete main user document
    await userRef.delete();
  }

  Future<void> _deleteAccount() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        _showError('User not logged in');
        return;
      }

      // 🔐 Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 🧹 Delete Firestore data
      await _deleteUserData(user.uid);

      // ❌ Delete Firebase Auth account
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account and data deleted permanently'),
          backgroundColor: Colors.red,
        ),
      );

      // 🚪 Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Account deletion failed');
    } catch (e) {
      _showError('Something went wrong. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.arrowLeft,
                  color: AppTheme.textWhite,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete your account and all associated data.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textGray.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Delete My Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
