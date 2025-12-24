import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppTheme.primaryPink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.place, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Brand name
        const Text(
          'PingPal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textBlack,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        // Tagline directly under the logo/brand
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 20),
        // Page-specific title
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBlack,
          ),
        ),
      ],
    );
  }
}
