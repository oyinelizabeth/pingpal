import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'requests.dart';
import 'user_profile.dart';
import 'chats.dart';
import 'pingtrail.dart';
import 'chat_list.dart';

class PingpalsPage extends StatefulWidget {
  const PingpalsPage({super.key});

  @override
  State<PingpalsPage> createState() => _PingpalsPageState();
}

class _PingpalsPageState extends State<PingpalsPage> {
  final int _navIndex = 1; // Pingpals is at index 1 (correct)
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recent';

  // Sample pingpals data
  final List<Map<String, dynamic>> pingpals = [
    {
      "name": "Alex Chen",
      "username": "@alexc",
      "avatar": "https://i.pravatar.cc/150?img=1",
      "status": "Nearby",
      "isOnline": true,
      "lastSeen": null,
    },
    {
      "name": "Davide Rossi",
      "username": "@davide",
      "avatar": "https://i.pravatar.cc/150?img=4",
      "status": "Active now",
      "isOnline": true,
      "lastSeen": null,
    },
    {
      "name": "Sarah Jones",
      "username": "@sarah_jones",
      "avatar": "https://i.pravatar.cc/150?img=3",
      "status": "2h ago",
      "isOnline": false,
      "lastSeen": "2h ago",
    },
    {
      "name": "Marcus Johnson",
      "username": "@marcus_j",
      "avatar": "https://i.pravatar.cc/150?img=2",
      "status": "Last seen 1d ago",
      "isOnline": false,
      "lastSeen": "1d ago",
    },
    {
      "name": "Elara Vance",
      "username": "@elara_v",
      "avatar": "https://i.pravatar.cc/150?img=5",
      "status": "Last seen 3d ago",
      "isOnline": false,
      "lastSeen": "3d ago",
    },
  ];

  int get newRequestsCount => 3; // From requests page

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Recent'),
              _buildSortOption('Name'),
              _buildSortOption('Status'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _sortBy == option;
    return ListTile(
      title: Text(
        option,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textWhite,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              FontAwesomeIcons.check,
              color: AppTheme.primaryBlue,
              size: 18,
            )
          : null,
      onTap: () {
        setState(() {
          _sortBy = option;
        });
        Navigator.pop(context);
      },
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pingpals',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your connections',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.gear,
                      color: AppTheme.textWhite,
                      size: 22,
                    ),
                    onPressed: () {
                      // TODO: Open settings
                    },
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
                    hintText: 'Search your Pingpals',
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

            const SizedBox(height: 16),

            // Add New Pingpal Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add new pingpal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    FontAwesomeIcons.userPlus,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Add New Pingpal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ping Requests Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequestsPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              FontAwesomeIcons.envelope,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            if (newRequestsCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    newRequestsCount.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ping Requests',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$newRequestsCount received • 1 sent',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textGray.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        FontAwesomeIcons.chevronRight,
                        color: AppTheme.textGray.withOpacity(0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // My Pingpals Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY PINGPALS (${pingpals.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: _showSortOptions,
                    child: const Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Pingpals List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pingpals.length,
                itemBuilder: (context, index) {
                  return _buildPingpalCard(pingpals[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == _navIndex) return; // Already on this page

          if (index == 2) {
            // Navigate to home/map
            Navigator.pop(context);
          } else if (index == 0) {
            // Navigate to Pingtrail
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PingtrailPage()),
            );
          } else if (index == 3) {
            // Navigate to Chat
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatListPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildPingpalCard(Map<String, dynamic> pingpal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UserProfilePage(
              userId: 'user_id',
              initialStatus: RelationshipStatus.friend,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(pingpal["avatar"]),
                ),
                if (pingpal["isOnline"])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.cardBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pingpal["name"],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pingpal["username"]} • ${pingpal["status"]}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(friendName: pingpal["name"]),
                      ),
                    );
                  },
                  icon: Icon(
                    FontAwesomeIcons.message,
                    color: AppTheme.textGray.withOpacity(0.7),
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.inputBackground,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    // Show more options
                  },
                  icon: Icon(
                    FontAwesomeIcons.ellipsisVertical,
                    color: AppTheme.textGray.withOpacity(0.7),
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.inputBackground,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
