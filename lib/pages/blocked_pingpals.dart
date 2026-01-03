import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class BlockedPingpalsPage extends StatefulWidget {
  const BlockedPingpalsPage({super.key});

  @override
  State<BlockedPingpalsPage> createState() => _BlockedPingpalsPageState();
}

class _BlockedPingpalsPageState extends State<BlockedPingpalsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample blocked users data
  final List<Map<String, dynamic>> blockedUsers = [
    {
      "username": "@cyber_ninja",
      "avatar": null,
      "blockedTime": "2 days ago",
    },
    {
      "username": "@map_tracker",
      "avatar": null,
      "blockedTime": "1 month ago",
    },
    {
      "username": "@john_doe_99",
      "avatar": null,
      "blockedTime": "3 months ago",
    },
    {
      "username": "@travel_bug_x",
      "avatar": null,
      "blockedTime": "yesterday",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _unblockUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Unblock User?',
          style: TextStyle(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This user will be able to see your location and send you ping requests again.',
          style: TextStyle(
            color: AppTheme.textGray.withOpacity(0.9),
          ),
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
              setState(() {
                blockedUsers.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User unblocked'),
                  backgroundColor: AppTheme.primaryBlue,
                ),
              );
            },
            child: const Text(
              'Unblock',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
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
                        'Blocked Pingpals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.userSlash,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Search blocked users...',
                    hintStyle: TextStyle(
                      color: AppTheme.textGray.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppTheme.textGray.withOpacity(0.6),
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Users listed below cannot see your real-time location, cannot join your active Pingtrails, and are restricted from sending you Ping Requests.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGray.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recently Blocked Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENTLY BLOCKED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.arrowsRotate,
                          color: Colors.green,
                          size: 10,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Synced',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Blocked Users List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: blockedUsers.length,
                itemBuilder: (context, index) {
                  return _buildBlockedUserCard(blockedUsers[index], index);
                },
              ),
            ),

            // Info Box
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.circleInfo,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Did you know?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Blocking a user also removes them from your friend list automatically. They won\'t be notified.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGray.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              user["avatar"] != null
                  ? CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(user["avatar"]),
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.inputBackground,
                      child: Text(
                        user["username"][1].toUpperCase() + user["username"][2].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.ban,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["username"],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blocked ${user["blockedTime"]}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGray.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _unblockUser(index),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              side: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Unblock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
