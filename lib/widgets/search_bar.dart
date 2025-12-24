import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PingPalSearchBar extends StatelessWidget {
  final String hint;
  const PingPalSearchBar({super.key, this.hint = "Search for location"});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
      ),
      child: TextField(
        style: const TextStyle(color: AppTheme.textWhite),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AppTheme.primaryBlue),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textGray.withOpacity(0.6)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
