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

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final String pingtrailId = doc.id;
    final String trailName = data['name'] ?? 'Pingtrail';
    final String destinationName = data['destinationName'] ?? '';
    final GeoPoint destination = data['destination'];
    final DateTime arrivalTime =
    (data['arrivalTime'] as Timestamp).toDate();

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

            /// Accepted count
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
                  builder: (context, snapshot) {
                    ArrivalStatus? status;

                    if (snapshot.hasData &&
                        snapshot.data!.docs.isNotEmpty) {
                      final locData = snapshot.data!.docs.first.data()
                      as Map<String, dynamic>;

                      final GeoPoint userLocation =
                      locData['location'];

                      status = _getArrivalStatus(
                        destination: destination,
                        userLocation: userLocation,
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


/// Live Status

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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppTheme.inputBackground,
        child: Icon(Icons.person),
      ),
      title: Text(
        uid,
        style: const TextStyle(color: AppTheme.textWhite),
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
  }
}
