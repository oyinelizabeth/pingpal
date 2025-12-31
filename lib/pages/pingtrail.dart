import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'active_pingtrail_map.dart';
import 'create_pingtrail.dart';
import 'pingtrails_history.dart';
import 'pingpals.dart';
import 'chat_list.dart';
import '../widgets/pending_pingtrail_sheet.dart';
import '../widgets/active_pingtrail_details_sheet.dart';
import '../widgets/pingtrail_avatar_row.dart';

class PingtrailPage extends StatefulWidget {
  const PingtrailPage({super.key});

  @override
  State<PingtrailPage> createState() => _PingtrailPageState();
}

class _PingtrailPageState extends State<PingtrailPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final int _navIndex = 0;

  // Select Destination
  void validateSelectedDestination(LatLng? selectedLatLng) {
    if (selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // Accept Pingtrail
  Future<void> acceptPingtrail(String pingtrailId) async {
    final uid = currentUserId;
    final ref =
    FirebaseFirestore.instance.collection('pingtrails').doc(pingtrailId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;

      final members = List<String>.from(data['members']);
      final accepted = List<String>.from(data['acceptedMembers']);

      // Add user if not already accepted
      if (!accepted.contains(uid)) {
        accepted.add(uid);
      }

      final bool everyoneAccepted = accepted.length == members.length;

      tx.update(ref, {
        'acceptedMembers': accepted,
        'status': everyoneAccepted ? 'active' : 'pending',
        'startedAt':
        everyoneAccepted ? FieldValue.serverTimestamp() : null,
      });
    });
  }


  // Decline Pingtrail
  Future<void> declinePingtrail(String pingtrailId) async {
    await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(pingtrailId)
        .update({
      'members': FieldValue.arrayRemove([currentUserId]),
      'acceptedMembers': FieldValue.arrayRemove([currentUserId]),
    });
  }

  // Popup for pending pingtrail
  void _openPendingPingtrailPopup(QueryDocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PendingPingtrailDetailsSheet(
        doc: doc,
        currentUserId: currentUserId,
        onAccept: () => acceptPingtrail(doc.id),
        onDecline: () => declinePingtrail(doc.id),
      ),
    );
  }
  // Popup for active pingtrail
  void _openActivePingtrailPopup(QueryDocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ActivePingtrailDetailsSheet(
        doc: doc,
        currentUserId: currentUserId,
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header with profile icon
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pingtrail Hub',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.cardBackground,
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?img=8",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Where to next?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 32),

                // Create New Pingtrail Button
                Container(
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
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePingtrailPage(),
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
                    icon: const Icon(
                      FontAwesomeIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Create New Pingtrail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Share Live Location Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Share live location
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                      backgroundColor: AppTheme.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      FontAwesomeIcons.locationCrosshairs,
                      color: AppTheme.textWhite,
                      size: 18,
                    ),
                    label: const Text(
                      'Share Live Location',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Active Pingtrail Section
                const Text(
                  'Active Pingtrail',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pingtrails')
                  .where('members', arrayContains: currentUserId)
                  .where('status', isEqualTo: 'active')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return _buildNoActivePingtrail();
                }

                final doc = snapshot.data!.docs.first;

                return ActivePingtrailCard(
                  doc: doc,
                  onTap: () => _openActivePingtrailPopup(doc),
                );
              },
            ),

                // Pending Pingtrails Section
                const Text(
                  'Pending Pingtrails',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 16),

                _buildPendingPingtrails(),

                const SizedBox(height: 40),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pingtrails')
                      .where('hostId', isEqualTo: currentUserId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Pingtrail',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Waiting for pingpals to accept…',
                                style: TextStyle(
                                  color: AppTheme.textGray.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),


                // Past Pingtrails Section
                const Text(
                  'Past Pingtrails',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 16),

                // Past Pingtrail Cards
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pingtrails')
                      .where('members', arrayContains: currentUserId)
                      .where('status', isEqualTo: 'completed')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        'No past pingtrails',
                        style: TextStyle(color: AppTheme.textGray),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final doc = snapshot.data!.docs.first;
                        return ActivePingtrailCard(
                          doc: doc,
                          onTap: () => _openActivePingtrailPopup(doc),
                        );

                      }).toList(),
                    );
                  },
                ),


                const SizedBox(height: 24),

                // View Full History Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PingtrailsHistoryPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.clockRotateLeft,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'View Full History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          FontAwesomeIcons.chevronRight,
                          color: AppTheme.textGray,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == _navIndex) return; // Already on this page

          if (index == 2) {
            // Navigate to home/map
            Navigator.pop(context);
          } else if (index == 1) {
            // Navigate to Pingpals
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PingpalsPage()),
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


  Widget _buildPendingPingtrails() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('members', arrayContains: currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final pendingInvites = docs.where((doc) {
          final accepted =
          List<String>.from(doc['acceptedMembers']);
          return !accepted.contains(currentUserId);
        }).toList();

        if (pendingInvites.isEmpty) {
          return const Text(
            'No pending pingtrail invites',
            style: TextStyle(color: AppTheme.textGray),
          );
        }

        return Column(
          children: pendingInvites
              .map((doc) => _buildPendingPingtrailCard(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildPendingPingtrailCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List<String> members =
    List<String>.from(data['members'] ?? []);
    final List<String> accepted =
    List<String>.from(data['acceptedMembers'] ?? []);

    final bool hasAccepted = accepted.contains(currentUserId);
    final bool isHost = data['hostId'] == currentUserId;

    return GestureDetector(
      onTap: () => _openPendingPingtrailPopup(doc),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatars bunched left
            PingtrailAvatarRow(
              memberIds: members,
              radius: 18,
            ),

            const SizedBox(height: 12),

            // Pingtrail name
            Text(
              data['name'] ?? 'Pingtrail',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 6),

            // Destination
            Text(
              data['destinationName'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGray.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 12),

            // Accepted count
            Text(
              '${accepted.length} / ${members.length} pingpals accepted',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 10),

            // Status text
            Row(
              children: [
                Icon(
                  hasAccepted
                      ? Icons.check_circle
                      : Icons.hourglass_bottom,
                  size: 16,
                  color:
                  hasAccepted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  hasAccepted
                      ? 'You accepted'
                      : 'Tap to view invite',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    hasAccepted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),

            if (isHost) ...[
              const SizedBox(height: 6),
              const Text(
                'Waiting for pingpals to accept…',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildNoActivePingtrail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.route,
            size: 40,
            color: AppTheme.textGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active pingtrail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new pingtrail to get started',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }


}

class ActivePingtrailCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onTap;

  const ActivePingtrailCard({
    super.key,
    required this.doc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final String name = data['name'] ?? 'Pingtrail';
    final String destinationName = data['destinationName'] ?? '';
    final List<String> members =
    List<String>.from(data['members'] ?? []);
    final List<String> accepted =
    List<String>.from(data['acceptedMembers'] ?? []);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity, // ✅ full width
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue, // highlight active
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👥 avatars bunched left
              PingtrailAvatarRow(
                memberIds: members,
                radius: 18,
              ),

              const SizedBox(height: 12),

              // 🏷 name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),

              const SizedBox(height: 6),

              // 📍 destination
              Text(
                destinationName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGray.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 12),

              // 🟢 active status
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 10,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${accepted.length} / ${members.length} pingpals active',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
