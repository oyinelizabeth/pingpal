import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../pages/active_pingtrail_map.dart';

enum ArrivalStatus { arrived, enRoute, late }

class ActivePingtrailDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUserId;

  const ActivePingtrailDetailsSheet({
    super.key,
    required this.doc,
    required this.currentUserId,
  });

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

  Future<void> _leavePingtrail(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(doc.id)
        .update({
      'members': FieldValue.arrayRemove([currentUserId]),
      'acceptedMembers': FieldValue.arrayRemove([currentUserId]),
    });

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmLeavePingtrail(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.orange),
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
        'members': FieldValue.arrayRemove([currentUserId]),
        'acceptedMembers': FieldValue.arrayRemove([currentUserId]),
        'leftMembers': FieldValue.arrayUnion([currentUserId]),
      });

      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmCancelPingtrail(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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


  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final String pingtrailId = doc.id;
    final String trailName = data['name'] ?? 'Pingtrail';
    final String destinationName = data['destinationName'] ?? '';
    final GeoPoint destination = data['destination'];
    final DateTime arrivalTime =
    (data['arrivalTime'] as Timestamp).toDate();
    final bool isHost = data['hostId'] == currentUserId;


    final List<String> members =
    List<String>.from(data['members'] ?? []);
    final List<String> accepted =
    List<String>.from(data['acceptedMembers'] ?? []);

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
            /// Drag handle
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

            /// Title
            Text(
              trailName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 6),

            /// Destination
            Text(
              destinationName,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textGray.withOpacity(0.85),
              ),
            ),

            const SizedBox(height: 12),

            /// Arrival time
            Text(
              'Arrive by ${TimeOfDay.fromDateTime(arrivalTime).format(context)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            /// Active count
            Text(
              '${accepted.length} / ${members.length} pingpals active',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            /// Pingpals list
            const Text(
              'Pingpals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 12),

            Column(
              children: members.map((uid) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('user_locations')
                      .where('pingtrailId', isEqualTo: pingtrailId)
                      .where('uid', isEqualTo: uid)
                      .limit(1)
                      .snapshots(),
                  builder: (context, locationSnap) {
                    ArrivalStatus? status;

                    if (locationSnap.hasData &&
                        locationSnap.data!.docs.isNotEmpty) {
                      final locData = locationSnap.data!.docs.first.data()
                      as Map<String, dynamic>;

                      status = _getArrivalStatus(
                        destination: destination,
                        userLocation: locData['location'],
                        arrivalTime: arrivalTime,
                      );
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

            if (isHost)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmCancelPingtrail(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancel Pingtrail'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmLeavePingtrail(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Leave Pingtrail'),
                ),
              ),

            /// Track button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivePingtrailMapPage(
                      pingtrailId: pingtrailId,
                      destination: destination,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Track Pingtrail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                minimumSize: const Size(double.infinity, 52),
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

/// Pingpal Tile

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
    Color statusColor;
    String statusText;

    switch (status) {
      case ArrivalStatus.arrived:
        statusColor = Colors.green;
        statusText = 'Arrived';
        break;
      case ArrivalStatus.late:
        statusColor = Colors.red;
        statusText = 'Late';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'En route';
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        String displayName = 'Pingpal';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final user =
          snapshot.data!.data() as Map<String, dynamic>;
          displayName = user['fullName'] ?? 'Pingpal';
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppTheme.inputBackground,
            child: Icon(Icons.person, color: AppTheme.primaryBlue),
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: isAccepted
              ? Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          )
              : const Text(
            'Pending',
            style: TextStyle(color: AppTheme.textGray),
          ),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: isAccepted ? statusColor : AppTheme.textGray,
          ),
        );
      },
    );
  }
}
