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
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.softPink, width: 2),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: AppTheme.primaryPink),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
