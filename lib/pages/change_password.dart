import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password requirements
  bool _hasMinLength = false;
  bool _hasSpecialChar = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _savePassword() {
    if (_currentPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (!_hasMinLength || !_hasSpecialChar || !_hasNumber) {
      _showError('Password does not meet requirements');
      return;
    }

    // TODO: Implement password change logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
    Navigator.pop(context);
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
            // Header
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
                        'Change Password',
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
                    // Header Text
                    const Text(
                      'Secure your account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a strong password to keep your pingtrails and location data safe.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textGray.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Current Password
                    const Text(
                      'Current Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        hintStyle: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? FontAwesomeIcons.eyeSlash
                                : FontAwesomeIcons.eye,
                            size: 18,
                            color: AppTheme.textGray,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // New Password
                    const Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? FontAwesomeIcons.eyeSlash
                                : FontAwesomeIcons.eye,
                            size: 18,
                            color: AppTheme.textGray,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Confirm New Password
                    const Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        hintStyle: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? FontAwesomeIcons.eyeSlash
                                : FontAwesomeIcons.eye,
                            size: 18,
                            color: AppTheme.textGray,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Requirements
                    Text(
                      'REQUIREMENTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildRequirement(
                      'At least 8 characters',
                      _hasMinLength,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirement(
                      'Includes a special character',
                      _hasSpecialChar,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirement(
                      'Includes a number',
                      _hasNumber,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
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
                        onPressed: _savePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Password',
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

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: met ? Colors.green : AppTheme.inputBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: met ? Colors.green : AppTheme.borderColor,
              width: 2,
            ),
          ),
          child: met
              ? const Icon(
                  FontAwesomeIcons.check,
                  size: 10,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: met
                ? AppTheme.textWhite
                : AppTheme.textGray.withOpacity(0.7),
            fontWeight: met ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
