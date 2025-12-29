import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_text_field.dart';
import 'forget_password.dart';
import 'home.dart';

class AuthPage extends StatefulWidget {
  final int initialTab;

  const AuthPage({super.key, this.initialTab = 0});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'email': user.email ?? '',
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    }
    setState(() => loading = false);
  }

  Future<void> register() async {
    setState(() => loading = true);
    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _tabController.animateTo(0);
        _clearFields();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
    setState(() => loading = false);
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn.standard().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Google login failed")));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  void _clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmController.clear();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // World map background
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/world_map.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(); // Fallback if image not found
                },
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // App Logo and Brand
                _buildHeader(),
                const SizedBox(height: 32),
                // Tab Bar
                _buildTabBar(),
                const SizedBox(height: 24),
                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignUpForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.accentBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            FontAwesomeIcons.locationDot,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pingpal',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Stay connected, anywhere.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGray,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textGray,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Log In'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 12),

          // Email Field
          CustomTextField(
            hintText: "Email",
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            suffixIcon: FontAwesomeIcons.envelope,
          ),
          const SizedBox(height: 16),

          // Password Field
          PasswordTextField(
            controller: passwordController,
            hintText: 'Password',
            // prefixIcon: FontAwesomeIcons.lock,
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login Button
          CustomButton(text: "Log in", onPressed: login),

          const SizedBox(height: 32),

          // Divider with OR
          const Row(
            children: [
              Expanded(child: Divider(color: AppTheme.dividerColor)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.dividerColor)),
            ],
          ),

          const SizedBox(height: 24),

          // Social Login Buttons
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  label: 'Apple',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  label: 'Google',
                  onPressed: () => signInWithGoogle(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign up to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 32),

          // Full Name Field
          CustomTextField(
            hintText: 'Full name',
            controller: nameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            suffixIcon: FontAwesomeIcons.user,
          ),
          const SizedBox(height: 16),

          // Email Field
          CustomTextField(
            hintText: 'Email',
            controller: emailController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            suffixIcon: FontAwesomeIcons.envelope,
          ),
          const SizedBox(height: 16),

          // Password Field
          PasswordTextField(
            hintText: 'Password',
            controller: passwordController,
            // prefixIcon: FontAwesomeIcons.lock,
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          PasswordTextField(
            hintText: 'Confirm password',
            controller: confirmController,
            // prefixIcon: FontAwesomeIcons.lockOpen,
          ),

          const SizedBox(height: 24),

          // Sign Up Button
          CustomButton(text: 'Create account', onPressed: register),

          const SizedBox(height: 24),

          // Divider with OR
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or continue with',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          // Social Login Buttons
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  label: 'Google',
                  onPressed: () => signInWithGoogle(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  label: 'Apple',
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: FaIcon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
        foregroundColor: AppTheme.textWhite,
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
