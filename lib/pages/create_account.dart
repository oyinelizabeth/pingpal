import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_text_field.dart';
import 'home.dart';
import 'login.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    // Lightweight client-side checks (placeholder until real auth)
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Password should be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }

    // Navigate to Home as placeholder for successful sign up
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: AuthHeader(
                  title: 'Create your account',
                  subtitle: 'Live location, faster on any network.',
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: 'Full name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      hintText: 'Email',
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    PasswordTextField(
                      hintText: 'Password',
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    PasswordTextField(
                      hintText: 'Confirm password',
                      controller: _confirmController,
                    ),

                    const SizedBox(height: 24),
                    CustomButton(text: 'Create account', onPressed: _submit),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                          ),
                          child: const Text('Log in'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
