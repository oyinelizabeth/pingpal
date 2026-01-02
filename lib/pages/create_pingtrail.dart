import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'select_destination.dart';

class CreatePingtrailPage extends StatefulWidget {
  const CreatePingtrailPage({super.key});

  @override
  State<CreatePingtrailPage> createState() => _CreatePingtrailPageState();
}

class _CreatePingtrailPageState extends State<CreatePingtrailPage> {
  final int _navIndex = 0;
  final TextEditingController _trailNameController = TextEditingController(
    text: 'Friday Night Out',
  );
  final TextEditingController _searchController = TextEditingController();

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController destinationController = TextEditingController();

// selected pingpals (UIDs)
  final Set<String> selectedPingpals = {};

  bool isCreating = false;

  Stream<List<DocumentSnapshot>> friendsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>;
      final List friends = data['friends'] ?? [];

      if (friends.isEmpty) return [];

      return Future.wait(
        friends.map(
              (id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get(),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
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
                    const Text(
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
                                '${selectedPingpals.length} / 5 Selected',

                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                    const Text(
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
                    StreamBuilder<List<DocumentSnapshot>>(
                      stream: friendsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final friends = snapshot.data!;

                        if (friends.isEmpty) {
                          return const Text(
                            'No Pingpals yet',
                            style: TextStyle(color: AppTheme.textGray),
                          );
                        }

                        return Column(
                          children: friends.map((doc) {
                            final user = doc.data() as Map<String, dynamic>;
                            final uid = doc.id;
                            final isSelected = selectedPingpals.contains(uid);

                            return _buildFirestoreFriendCard(
                              uid: uid,
                              user: user,
                              isSelected: isSelected,
                            );
                          }).toList(),
                        );
                      },
                    ),


                    const SizedBox(height: 24),

                    // All Pingpals Section
                    const Text(
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
              onPressed: selectedPingpals.length < 1 ? null:
                () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectDestinationPage(
                      trailName: _trailNameController.text,
                      selectedFriends: selectedPingpals.toList(),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
    );
  }

  Widget _buildFirestoreFriendCard({
    required String uid,
    required Map<String, dynamic> user,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedPingpals.remove(uid);
          } else {
            if (selectedPingpals.length < 5) {
              selectedPingpals.add(uid);
            }
          }
        });
      },
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
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
              backgroundImage: user['photoUrl'] != null &&
                  user['photoUrl'].toString().isNotEmpty
                  ? NetworkImage(user['photoUrl'])
                  : null,
              child: user['photoUrl'] == null ||
                  user['photoUrl'].toString().isEmpty
                  ? const Icon(Icons.person, color: AppTheme.primaryBlue)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['fullName'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                FontAwesomeIcons.check,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

}
