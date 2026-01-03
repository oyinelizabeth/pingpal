import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'requests.dart';
import 'user_profile.dart';
import 'chats.dart';
import 'chat_list.dart';
import 'add_friends.dart';

class PingpalsPage extends StatefulWidget {
  const PingpalsPage({super.key});

  @override
  State<PingpalsPage> createState() => _PingpalsPageState();
}

class _PingpalsPageState extends State<PingpalsPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final int _navIndex = 1; // Pingpals is at index 1 (correct)
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recent';



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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFriendPage(),
                      ),
                    );
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
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('friend_requests')
                                  .where('receiverId', isEqualTo: currentUserId)
                                  .where('status', isEqualTo: 'pending')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.docs.length ?? 0;
                                if (count == 0) return const SizedBox();

                                return Positioned(
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
                                      count.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('friend_requests')
                                    .where('receiverId', isEqualTo: currentUserId)
                                    .where('status', isEqualTo: 'pending')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final received = snapshot.data?.docs.length ?? 0;
                                  return Text(
                                    '$received received',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textGray.withOpacity(0.8),
                                    ),
                                  );
                                },
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
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .collection('pingpals')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Text(
                        'MY PINGPALS ($count)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      );
                    },
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('pingpals')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Pingpals yet',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final pingpal = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildPingpalCard(pingpal);
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildPingpalCard(Map<String, dynamic> pingpal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              userId: pingpal['uid'],
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
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                  backgroundImage: pingpal["photoUrl"] != null &&
                      pingpal["photoUrl"].toString().isNotEmpty
                      ? NetworkImage(pingpal["photoUrl"])
                      : null,
                  child: pingpal["photoUrl"] == null ||
                      pingpal["photoUrl"].toString().isEmpty
                      ? const Icon(
                    Icons.person,
                    color: AppTheme.primaryBlue,
                    size: 30,
                  )
                      : null,
                ),

                if (pingpal["isOnline"] == true)
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
                    pingpal["fullName"],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pingpal["email"],
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
