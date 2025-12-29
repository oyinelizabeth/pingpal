import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Failed to send reset email');
    } finally {
      setState(() => _isLoading = false);
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppTheme.textWhite,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset your password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your registered email address and we will send you a password reset link.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textGray.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontSize: 17,
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
          ],
        ),
      ),
    );
  }
}
