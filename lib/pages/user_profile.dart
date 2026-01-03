import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'chats.dart';

enum RelationshipStatus {
  friend,
  pendingReceived,
  pendingSent,
  none,
}

class UserProfilePage extends StatefulWidget {
  final String userId;
  final RelationshipStatus initialStatus;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.initialStatus = RelationshipStatus.friend,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late RelationshipStatus _relationshipStatus;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _relationshipStatus = widget.initialStatus;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _sendPingRequest() {
    setState(() {
      _relationshipStatus = RelationshipStatus.pendingSent;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ping request sent'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _cancelPingRequest() {
    setState(() {
      _relationshipStatus = RelationshipStatus.none;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ping request cancelled'),
        backgroundColor: AppTheme.textGray,
      ),
    );
  }

  void _acceptPingRequest() {
    setState(() {
      _relationshipStatus = RelationshipStatus.friend;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Now you are pingpals!'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _declinePingRequest() {
    setState(() {
      _relationshipStatus = RelationshipStatus.none;
    });
    Navigator.pop(context);
  }

  void _removeFriend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove ${uiUserData["name"].split(' ')[0]}?',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'This will remove them from your pingpals. You can add them back later.',
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
              setState(() {
                _relationshipStatus = RelationshipStatus.none;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  late Map<String, dynamic> uiUserData;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: Text("User not found", style: TextStyle(color: Colors.white))),
      );
    }

    // Adapt userData from Firestore to match the UI's expectations
    uiUserData = {
      "name": userData!["fullName"] ?? "Unknown User",
      "email": userData!["email"] ?? "",
      "username": userData!["email"] ?? "",
      "avatar": userData!["photoUrl"] != null && userData!["photoUrl"].isNotEmpty
          ? userData!["photoUrl"]
          : "https://i.pravatar.cc/300?img=3",
      "lastActive": "ONLINE NOW",
      "isOnline": true,
      "stats": {
        "trails": 0,
        "pings": 0,
        "days": 0,
      },
      "sharedPingtrails": [],
    };

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppTheme.textWhite,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.ellipsis,
                      color: AppTheme.textWhite,
                    ),
                    onPressed: () {
                      // Show options menu
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 68,
                            backgroundImage: NetworkImage(uiUserData["avatar"]),
                          ),
                        ),
                        if (uiUserData["isOnline"])
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.darkBackground,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Name
                    Text(
                      uiUserData["name"],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Username
                    Text(
                      uiUserData["username"],
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Last Active Location
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            FontAwesomeIcons.locationDot,
                            color: AppTheme.primaryBlue,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            uiUserData["lastActive"],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textGray.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildActionButtons(),
                    ),

                    const SizedBox(height: 24),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatCard('TRAILS', 12, FontAwesomeIcons.route)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('PINGS', 45, FontAwesomeIcons.bell)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('DAYS', 182, FontAwesomeIcons.calendar)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Shared Pingtrails
                    if (_relationshipStatus == RelationshipStatus.friend)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shared Pingtrails',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...uiUserData["sharedPingtrails"].map<Widget>(
                            (trail) => _buildPingtrailCard(trail),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Remove/Block Button (only for friends)
                    if (_relationshipStatus == RelationshipStatus.friend)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextButton.icon(
                          onPressed: _removeFriend,
                          icon: const Icon(
                            FontAwesomeIcons.userMinus,
                            size: 14,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Remove ${uiUserData["name"].split(' ')[0]} from Pingpals',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
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

  Widget _buildActionButtons() {
    switch (_relationshipStatus) {
      case RelationshipStatus.friend:
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _sendPingRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const Icon(
                    FontAwesomeIcons.bell,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Ping',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(friendName: uiUserData["name"]),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.borderColor),
                  backgroundColor: AppTheme.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(
                  FontAwesomeIcons.message,
                  color: AppTheme.textWhite,
                  size: 14,
                ),
                label: const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: AppTheme.borderColor),
                backgroundColor: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Icon(
                FontAwesomeIcons.locationDot,
                color: AppTheme.textWhite,
                size: 16,
              ),
            ),
          ],
        );

      case RelationshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ElevatedButton(
                  onPressed: _acceptPingRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _declinePingRequest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        );

      case RelationshipStatus.pendingSent:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.clock,
                    color: AppTheme.textGray,
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ping Request Sent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cancelPingRequest,
              child: const Text(
                'Cancel Request',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case RelationshipStatus.none:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _sendPingRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(
              FontAwesomeIcons.userPlus,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              'Send Ping Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingtrailCard(Map<String, dynamic> trail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.route,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trail["title"],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.clock,
                      size: 12,
                      color: AppTheme.textGray.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trail["duration"],
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (trail["speed"] != null) ...[
                      Icon(
                        FontAwesomeIcons.gaugeHigh,
                        size: 12,
                        color: AppTheme.textGray.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trail["speed"],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                    if (trail["participants"] != null) ...[
                      Icon(
                        FontAwesomeIcons.users,
                        size: 12,
                        color: AppTheme.textGray.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trail["participants"],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            trail["date"],
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
