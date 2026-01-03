import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'active_pingtrail_map.dart';
import 'pingtrail_invitation.dart';
import 'user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

// Notification hub for social and Pingtrail events
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _navIndex = 1;

  // Current authenticated user
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String currentUserName = 'A user';

  // Converts timestamps into user-friendly date labels
  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }


  // Base Firestore stream for notifications with optional filtering
  Stream<QuerySnapshot> _notificationsStream({List<String>? types}) {
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    if (types != null && types.isNotEmpty) {
      // Normalises type names to match Firestore records
      final List<String> filteredTypes = types.map((t) => t == 'pingtrail_invite' ? 'pingtrail_invitation' : t).toList();
      query = query.where('type', whereIn: filteredTypes);
    }

    return query.snapshots();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentUserName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Loads the current user’s name for personalised notifications
  Future<void> _loadCurrentUserName() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists) {
      setState(() {
        currentUserName = snap.data()?['fullName'] ?? 'A user';
      });
    }
  }

  // Marks all unread notifications as read
  Future<void> _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // Accepts a friend request and updates both user documents
  Future<void> _acceptFriendRequest(String senderId, String notificationId) async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserRef =
    FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final senderRef =
    FirebaseFirestore.instance.collection('users').doc(senderId);
    final notificationRef =
    FirebaseFirestore.instance.collection('notifications').doc(notificationId);

    batch.update(currentUserRef, {
      'friends': FieldValue.arrayUnion([senderId]),
    });

    batch.update(senderRef, {
      'friends': FieldValue.arrayUnion([currentUserId]),
    });

    batch.update(notificationRef, {'read': true});

    await batch.commit();

    // Notify sender that their request was accepted
    await NotificationService.send(
      receiverId: senderId,
      senderId: currentUserId,
      title: 'Friend request accepted',
      body: '$currentUserName accepted your friend request',
      type: 'friend_request_accepted',
    );

  }

  // Removes a notification when declined
  Future<void> _declineNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Accepts a Pingtrail invitation directly from a notification
  Future<void> _acceptPingtrailFromNotification(
      String pingtrailId,
      String notificationId,
      ) async {
    final ref =
    FirebaseFirestore.instance.collection('ping_trails').doc(pingtrailId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;

        final data = snap.data()!;
        final List<dynamic> participants = List.from(data['participants'] ?? []);
        final List<String> members = List<String>.from(data['members'] ?? []);
        final String hostId = data['hostId'] ?? '';

        bool found = false;
        for (var p in participants) {
          if (p['userId'] == currentUserId) {
            p['status'] = 'accepted';
            found = true;
            break;
          }
        }

        if (!found) {
          participants.add({
            'userId': currentUserId,
            'status': 'accepted',
          });
        }

        if (!members.contains(currentUserId)) {
          members.add(currentUserId);
        }

        tx.update(ref, {
          'participants': participants,
          'members': members,
        });

        // Notify host
        if (hostId.isNotEmpty && hostId != currentUserId) {
          await NotificationService.send(
            receiverId: hostId,
            senderId: currentUserId,
            title: 'Pingtrail accepted',
            body: '$currentUserName joined your pingtrail',
            type: 'pingtrail_accepted',
            pingtrailId: pingtrailId,
          );
        }
      });

      // Mark notification as read
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined pingtrail! Opening map...'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );

        // Navigate to live tracking map
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivePingtrailMapPage(
              pingtrailId: pingtrailId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting pingtrail: $e');
    }
  }

  // Declines a Pingtrail invitation from notifications
  Future<void> _declinePingtrailFromNotification(
      String pingtrailId,
      String notificationId,
      ) async {
    final ref = FirebaseFirestore.instance.collection('ping_trails').doc(pingtrailId);
    
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final List<dynamic> participants = List.from(data['participants'] ?? []);
      final List<String> members = List<String>.from(data['members'] ?? []);

      members.remove(currentUserId);
      for (var p in participants) {
        if (p['userId'] == currentUserId) {
          p['status'] = 'declined';
          break;
        }
      }

      tx.update(ref, {
        'members': members,
        'participants': participants,
      });
    });

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
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
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('receiverId', isEqualTo: currentUserId)
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          if (count == 0) return const SizedBox();

                          return Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppTheme.textGray.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textGray,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('All'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Requests'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Trails'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Arrivals'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildRequestsTab(),
                  _buildPingtrailsTab(),
                  _buildArrivalsTab(),
                ],
              ),
            ),
          ],
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

  Widget _buildAllTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;

        if (notifications.isEmpty) {
          return const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(color: AppTheme.textGray),
            ),
          );
        }

        final Map<String, List<QueryDocumentSnapshot>> grouped = {};

        for (final doc in notifications) {
          final ts = doc['createdAt'] as Timestamp;
          final label = _dateLabel(ts.toDate());
          grouped.putIfAbsent(label, () => []).add(doc);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ...entry.value.map(_buildNotificationTile),
              ],
            );
          }).toList(),
        );

      },
    );
  }

  Widget _buildNotificationTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final bool isRead = data['read'] == true;
    final String type = data['type'];
    final Timestamp ts = data['createdAt'];
    final DateTime time = ts.toDate();

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'friend_request_sent':
        icon = FontAwesomeIcons.userPlus;
        iconColor = AppTheme.primaryBlue;
        break;

      case 'friend_request_accepted':
        icon = FontAwesomeIcons.userCheck;
        iconColor = Colors.green;
        break;

      case 'pingtrail_invitation':
        icon = FontAwesomeIcons.route;
        iconColor = AppTheme.primaryBlue;
        break;

      case 'pingtrail_accepted':
        icon = FontAwesomeIcons.check;
        iconColor = Colors.green;
        break;

      case 'pingtrail_declined':
        icon = FontAwesomeIcons.xmark;
        iconColor = Colors.red;
        break;

      case 'arrival':
        icon = FontAwesomeIcons.locationDot;
        iconColor = Colors.green;
        break;

      default:
        icon = FontAwesomeIcons.bell;
        iconColor = AppTheme.textGray;
    }

    return GestureDetector(
      onTap: () async {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'read': true});

        final String type = data['type'];

        switch (type) {

        // Pingtrail invitation
          case 'pingtrail_invitation':
            if (data['invitationId'] == null || data['invitationId'] == '') {
              _showSnack(context, 'Invitation is no longer available');
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PingtrailInvitationPage(
                  pingtrailId: data['pingtrailId'],
                  invitationId: data['invitationId'],
                ),
              ),
            );
            break;

        // Pingtrail becomes active
          case 'pingtrail_active':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivePingtrailMapPage(
                  pingtrailId: data['pingtrailId'],
                ),
              ),
            );
            break;

        // User arrived
          case 'arrival':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivePingtrailMapPage(
                  pingtrailId: data['pingtrailId'],
                ),
              ),
            );
            break;

        // Freidn requested accepted
          case 'friend_request_accepted':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  userId: data['senderId'],
                ),
              ),
            );
            break;

        // Friend request sent
          case 'friend_request_sent':
          // stays inline (buttons already shown)
            break;

          default:
            _showSnack(context, 'Nothing to open for this notification');
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppTheme.borderColor
                : AppTheme.primaryBlue.withOpacity(0.5),
          ),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['body'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),

                      // ACCEPT / DECLINE
                      if ((type == 'friend_request_sent' ||
                          type == 'pingtrail_invitation') && !isRead) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (type == 'friend_request_sent') {
                                    _acceptFriendRequest(
                                      data['senderId'],
                                      doc.id,
                                    );
                                  } else {
                                    _acceptPingtrailFromNotification(
                                      data['pingtrailId'],
                                      doc.id,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (type == 'pingtrail_invitation') {
                                    _declinePingtrailFromNotification(
                                      data['pingtrailId'],
                                      doc.id,
                                    );
                                  } else {
                                    _declineNotification(doc.id);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((type == 'friend_request_sent' || type == 'pingtrail_invitation') && isRead) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                type == 'friend_request_sent' ? 'Accepted' : 'Joined',
                                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // DELETE (X) BUTTON
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  FontAwesomeIcons.xmark,
                  size: 14,
                  color: AppTheme.textGray.withOpacity(0.6),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .delete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream(types: [
        'friend_request_sent',
        'friend_request_accepted',
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No request notifications',
                style: TextStyle(color: AppTheme.textGray)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildNotificationTile(docs[index]);
          },
        );
      },
    );
  }

  Widget _buildPingtrailsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream(types: [
        'pingtrail_invitation',
        'pingtrail_accepted',
        'pingtrail_declined',
        'pingtrail_cancelled',
        'pingtrail_left',
        'pingtrail_active',
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No pingtrail notifications',
                style: TextStyle(color: AppTheme.textGray)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildNotificationTile(docs[index]);
          },
        );
      },
    );
  }


  Widget _buildArrivalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream(types: ['arrival']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No arrival updates',
                style: TextStyle(color: AppTheme.textGray)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildNotificationTile(docs[index]);
          },
        );
      },
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}


