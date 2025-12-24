import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'select_destination.dart';

class CreatePingtrailPage extends StatefulWidget {
  const CreatePingtrailPage({super.key});

  @override
  State<CreatePingtrailPage> createState() => _CreatePingtrailPageState();
}

class _CreatePingtrailPageState extends State<CreatePingtrailPage> {
  int _navIndex = 0; // Pingtrail is at index 0
  final TextEditingController _trailNameController = TextEditingController(
    text: 'Friday Night Out',
  );
  final TextEditingController _searchController = TextEditingController();

  // Sample friends data
  final List<Map<String, dynamic>> suggestedFriends = [
    {
      "id": 1,
      "name": "Jessica",
      "avatar": "https://i.pravatar.cc/150?img=1",
      "status": "Nearby • 1.2 mi away",
      "online": true,
      "selected": true,
    },
    {
      "id": 2,
      "name": "Sarah",
      "avatar": "https://i.pravatar.cc/150?img=3",
      "status": "Online now",
      "online": true,
      "selected": true,
    },
    {
      "id": 3,
      "name": "Mike",
      "avatar": "https://i.pravatar.cc/150?img=2",
      "status": "Moving • 12 mph",
      "online": false,
      "moving": true,
      "selected": true,
    },
  ];

  int get selectedCount => suggestedFriends.where((f) => f["selected"]).length;

  void _toggleSelection(int id) {
    setState(() {
      final friend = suggestedFriends.firstWhere((f) => f["id"] == id);
      friend["selected"] = !friend["selected"];
    });
  }

  void _selectAll() {
    setState(() {
      for (var friend in suggestedFriends) {
        friend["selected"] = true;
      }
    });
  }

  @override
  void dispose() {
    _trailNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.xmark,
                      color: AppTheme.textWhite,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Create Pingtrail',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trail Name Label
                    Text(
                      'TRAIL NAME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Trail Name Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _trailNameController,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            FontAwesomeIcons.pen,
                            color: AppTheme.textGray.withOpacity(0.6),
                            size: 20,
                          ),
                          onPressed: () {
                            // Focus on text field
                          },
                        ),
                      ],
                    ),

                    Container(
                      height: 1,
                      color: AppTheme.borderColor,
                      margin: const EdgeInsets.only(top: 8),
                    ),

                    const SizedBox(height: 32),

                    // Select Pingpals Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Select Pingpals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedCount Selected',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _selectAll,
                          child: const Text(
                            'Select All',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Search friends...',
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

                    const SizedBox(height: 24),

                    // Suggested Section
                    Text(
                      'SUGGESTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Suggested Friends List
                    ...suggestedFriends.map((friend) {
                      return _buildFriendCard(friend);
                    }),

                    const SizedBox(height: 24),

                    // All Pingpals Section
                    Text(
                      'ALL PINGPALS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Button
      bottomSheet: Container(
        color: AppTheme.darkBackground,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectDestinationPage(
                      trailName: _trailNameController.text,
                      selectedFriends: suggestedFriends
                          .where((f) => f["selected"])
                          .toList(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP 1 OF 2',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select Destination',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Icon(
                    FontAwesomeIcons.arrowRight,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index != _navIndex) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final bool isSelected = friend["selected"];
    final bool isOnline = friend["online"] ?? false;
    final bool isMoving = friend["moving"] ?? false;

    return GestureDetector(
      onTap: () => _toggleSelection(friend["id"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(friend["avatar"]),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? Colors.green
                          : (isMoving ? Colors.orange : Colors.grey),
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

            const SizedBox(width: 12),

            // Friend Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend["name"],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend["status"],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      FontAwesomeIcons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
