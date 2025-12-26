import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pingpal/pages/welcome_page.dart';

import '../theme/app_theme.dart';
import '../utils/utils.dart';
import 'blocked_pingpals.dart';
import 'change_password.dart';
import 'edit_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Notification toggles
  bool _pingRequestsEnabled = true;
  bool _pingtrailInvitesEnabled = true;
  bool _arrivalsEnabled = true;
  bool _chatMessagesEnabled = true;

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
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Section
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/300?img=12',
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.darkBackground,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Alex Rider',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '@alex_rider • Visible to 5 Pals',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // General Preferences
                    _buildSectionHeader('GENERAL PREFERENCES'),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.palette,
                      iconColor: Colors.grey,
                      title: 'App Theme',
                      trailing: 'Dark',
                      onTap: () {},
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.globe,
                      iconColor: Colors.blue,
                      title: 'Language',
                      trailing: 'English',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Notifications
                    _buildSectionHeader('NOTIFICATIONS'),
                    _buildToggleTile(
                      icon: FontAwesomeIcons.bell,
                      iconColor: Colors.amber,
                      title: 'Ping Requests',
                      value: _pingRequestsEnabled,
                      onChanged: (val) {
                        setState(() => _pingRequestsEnabled = val);
                      },
                    ),
                    _buildToggleTile(
                      icon: FontAwesomeIcons.route,
                      iconColor: Colors.purple,
                      title: 'Pingtrail Invites',
                      value: _pingtrailInvitesEnabled,
                      onChanged: (val) {
                        setState(() => _pingtrailInvitesEnabled = val);
                      },
                    ),
                    _buildToggleTile(
                      icon: FontAwesomeIcons.locationDot,
                      iconColor: Colors.green,
                      title: 'Arrivals',
                      value: _arrivalsEnabled,
                      onChanged: (val) {
                        setState(() => _arrivalsEnabled = val);
                      },
                    ),
                    _buildToggleTile(
                      icon: FontAwesomeIcons.message,
                      iconColor: Colors.cyan,
                      title: 'Chat Messages',
                      value: _chatMessagesEnabled,
                      onChanged: (val) {
                        setState(() => _chatMessagesEnabled = val);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Account Management
                    _buildSectionHeader('ACCOUNT MANAGEMENT'),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.userPen,
                      iconColor: Colors.orange,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.key,
                      iconColor: Colors.indigo,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.trashCan,
                      iconColor: Colors.red,
                      title: 'Delete Account',
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Privacy Settings
                    _buildSectionHeader('PRIVACY SETTINGS'),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.userSecret,
                      iconColor: Colors.cyan,
                      title: 'Location Privacy Settings',
                      onTap: () {},
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.userSlash,
                      iconColor: Colors.pink,
                      title: 'Blocked Pingpals Management',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BlockedPingpalsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Help & Support
                    _buildSectionHeader('HELP & SUPPORT'),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.circleQuestion,
                      iconColor: Colors.lightGreen,
                      title: 'FAQ',
                      onTap: () {},
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.headset,
                      iconColor: Colors.deepPurple,
                      title: 'Contact Support',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // Legal Information
                    _buildSectionHeader('LEGAL INFORMATION'),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.fileContract,
                      iconColor: Colors.grey,
                      title: 'Terms of Service',
                      onTap: () {
                        Utils.openLink('https://pingpal.co.za/terms-of-use');
                      },
                    ),
                    _buildNavigationTile(
                      icon: FontAwesomeIcons.shieldHalved,
                      iconColor: Colors.grey,
                      title: 'Privacy Policy',
                      onTap: () {
                        Utils.openLink('https://pingpal.co.za/privacy-policy');
                      },
                    ),

                    const SizedBox(height: 32),

                    // Log Out Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showLogoutDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(
                          FontAwesomeIcons.arrowRightFromBracket,
                          color: AppTheme.primaryBlue,
                          size: 16,
                        ),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGray.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                FontAwesomeIcons.chevronRight,
                color: AppTheme.textGray.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primaryBlue,
              activeTrackColor: AppTheme.primaryBlue.withOpacity(0.5),
              inactiveThumbColor: AppTheme.textGray,
              inactiveTrackColor: AppTheme.textGray.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete account logic
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
