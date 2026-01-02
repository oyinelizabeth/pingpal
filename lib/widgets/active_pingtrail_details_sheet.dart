import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import '../pages/active_pingtrail_map.dart';
import '../services/notification_service.dart';

enum ArrivalStatus { arrived, enRoute, late }

class ActivePingtrailDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUserId;

  const ActivePingtrailDetailsSheet({
    super.key,
    required this.doc,
    required this.currentUserId,
  });

  Map<String, dynamic> get data =>
      (doc.data() as Map<String, dynamic>? ?? {});

  // ─────────────────────────────
  // Arrival calculation
  // ─────────────────────────────

  ArrivalStatus _getArrivalStatus({
    required GeoPoint destination,
    required GeoPoint userLocation,
    required DateTime arrivalTime,
  }) {
    final now = DateTime.now();

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      destination.latitude,
      destination.longitude,
    );

    if (distance <= 50) return ArrivalStatus.arrived;
    if (now.isAfter(arrivalTime)) return ArrivalStatus.late;
    return ArrivalStatus.enRoute;
  }

  // ─────────────────────────────
  // Leave Pingtrail
  // ─────────────────────────────

  Future<void> _leavePingtrail(BuildContext context) async {
    final pingtrailId = doc.id;
    final hostId = (data['creatorId'] ?? '').toString();

    await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(pingtrailId)
        .update({
      'members': FieldValue.arrayRemove([currentUserId]),
      'acceptedMembers': FieldValue.arrayRemove([currentUserId]),
      'leftMembers': FieldValue.arrayUnion([currentUserId]),
    });

    if (hostId.isNotEmpty) {
      await NotificationService.send(
        receiverId: hostId,
        senderId: currentUserId,
        title: 'Pingtrail update',
        body: 'A member left the pingtrail',
        type: 'pingtrail_left',
        pingtrailId: pingtrailId,
      );
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmLeavePingtrail(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Leave Pingtrail?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'You will no longer share or receive live location updates.',
          style: TextStyle(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _leavePingtrail(context);
    }
  }

  // ─────────────────────────────
  // Cancel Pingtrail (host)
  // ─────────────────────────────

  Future<void> _confirmCancelPingtrail(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Cancel Pingtrail?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'This will end the pingtrail for all participants.',
          style: TextStyle(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Pingtrail',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('pingtrails')
          .doc(doc.id)
          .update({
        'status': 'cancelled',
        'endedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) Navigator.pop(context);
    }
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pingtrailId = doc.id;

    final destinationName =
    (data['destinationName'] ?? 'Unknown destination').toString();
    final trailName =
    (data['name'] ?? destinationName).toString();

    final creatorId = (data['creatorId'] ?? '').toString();
    final isHost = creatorId == currentUserId;

    final destination = data['destination'] is GeoPoint
        ? data['destination'] as GeoPoint
        : const GeoPoint(0, 0);

    final arrivalTime = data['arrivalTime'] is Timestamp
        ? (data['arrivalTime'] as Timestamp).toDate()
        : DateTime.now();

    final members = (data['members'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    final accepted = (data['acceptedMembers'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Text(
              trailName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              destinationName,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textGray.withOpacity(0.85),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Arrive by ${TimeOfDay.fromDateTime(arrivalTime).format(context)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${accepted.length} / ${members.length} pingpals active',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Pingpals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 12),

            // ───────── PINGPALS LIST ─────────
            Column(
              children: members.map((uid) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pingtrails')
                      .doc(pingtrailId)
                      .collection('liveLocations')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snap) {
                    ArrivalStatus? status;

                    if (snap.hasData && snap.data!.exists) {
                      final raw = snap.data!.data();
                      if (raw is Map<String, dynamic> &&
                          raw['location'] is GeoPoint) {
                        status = _getArrivalStatus(
                          destination: destination,
                          userLocation:
                          raw['location'] as GeoPoint,
                          arrivalTime: arrivalTime,
                        );
                      }
                    }

                    return _PingpalTile(
                      uid: uid,
                      isAccepted: accepted.contains(uid),
                      status: status,
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Leave / Cancel
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isHost
                    ? () => _confirmCancelPingtrail(context)
                    : () => _confirmLeavePingtrail(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isHost ? Colors.red : Colors.orange,
                  ),
                  foregroundColor:
                  isHost ? Colors.red : Colors.orange,
                ),
                child: Text(
                    isHost ? 'Cancel Pingtrail' : 'Leave Pingtrail'),
              ),
            ),

            const SizedBox(height: 12),

            // Track
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActivePingtrailMapPage(
                          pingtrailId: pingtrailId,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Track Pingtrail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                minimumSize:
                const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────
// Pingpal tile
// ─────────────────────────────

class _PingpalTile extends StatelessWidget {
  final String uid;
  final bool isAccepted;
  final ArrivalStatus? status;

  const _PingpalTile({
    required this.uid,
    required this.isAccepted,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case ArrivalStatus.arrived:
        color = Colors.green;
        text = 'Arrived';
        break;
      case ArrivalStatus.late:
        color = Colors.red;
        text = 'Late';
        break;
      default:
        color = Colors.orange;
        text = 'En route';
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        final name = snap.data?.data() is Map<String, dynamic>
            ? (snap.data!.data() as Map<String, dynamic>)['fullName']
            ?.toString() ??
            'Pingpal'
            : 'Pingpal';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppTheme.inputBackground,
            child: Icon(Icons.person,
                color: AppTheme.primaryBlue),
          ),
          title: Text(
            name,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: isAccepted
              ? Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600))
              : const Text('Pending',
              style:
              TextStyle(color: AppTheme.textGray)),
          trailing: Icon(Icons.circle,
              size: 12,
              color:
              isAccepted ? color : AppTheme.textGray),
        );
      },
    );
  }
}
