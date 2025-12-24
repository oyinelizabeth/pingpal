import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../pages/settings.dart';
import '../pages/chat_list.dart';
import '../pages/pingpals.dart';

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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pingtrail
              GestureDetector(
                onTap: () => onTap(0),
                child: _buildNavItem(
                  icon: FontAwesomeIcons.route,
                  label: 'Pingtrail',
                  index: 0,
                ),
              ),
              // Pingpals
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PingpalsPage(),
                    ),
                  );
                },
                child: _buildNavItem(
                  icon: FontAwesomeIcons.users,
                  label: 'Pingpals',
                  index: 1,
                ),
              ),
              // Map (Center, Larger)
              _buildCenterMapButton(),
              // Chat
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatListPage(),
                    ),
                  );
                },
                child: _buildNavItem(
                  icon: FontAwesomeIcons.message,
                  label: 'Chat',
                  index: 3,
                ),
              ),
              // Settings (Note: Settings page doesn't have navbar, so index doesn't matter)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
                child: _buildNavItem(
                  icon: FontAwesomeIcons.gear,
                  label: 'Settings',
                  index: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isActive ? 10 : 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              icon,
              size: 20,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textGray,
            ),
          ),
        ],
      );
  }

  Widget _buildCenterMapButton() {
    final bool isActive = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                )
              : null,
          color: isActive ? null : AppTheme.inputBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.transparent : AppTheme.borderColor,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.mapLocationDot,
            size: 24,
            color: isActive ? Colors.white : AppTheme.textGray,
          ),
        ),
      ),
    );
  }
}

