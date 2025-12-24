import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textGray,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildItem(Icons.home_outlined, 0),
          _buildItem(Icons.location_on_outlined, 1),
          _buildItem(Icons.chat_bubble_outline, 2),
          _buildItem(Icons.people_alt_outlined, 3),
          _buildItem(Icons.settings_outlined, 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildItem(IconData icon, int index) {
    final bool isActive = currentIndex == index;

    return BottomNavigationBarItem(
      label: "",
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isActive ? 8 : 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isActive ? 26 : 22,
        ),
      ),
    );
  }
}

