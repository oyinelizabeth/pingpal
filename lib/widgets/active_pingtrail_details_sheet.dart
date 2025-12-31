import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../pages/active_pingtrail_map.dart';

class ActivePingtrailDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUserId;

  const ActivePingtrailDetailsSheet({
    super.key,
    required this.doc,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final String trailName = data['name'] ?? 'Pingtrail';
    final String destinationName = data['destinationName'] ?? '';
    final GeoPoint destination = data['destination'];
    final List<String> members = List<String>.from(data['members'] ?? []);
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

            _ActivePingtrailMembersList(
              memberIds: members,
              acceptedIds: accepted,
            ),

            const SizedBox(height: 28),

            /// Track button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivePingtrailMapPage(
                      pingtrailId: doc.id,
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

/// -----------------------------
/// MEMBERS LIST
/// -----------------------------
class _ActivePingtrailMembersList extends StatelessWidget {
  final List<String> memberIds;
  final List<String> acceptedIds;

  const _ActivePingtrailMembersList({
    required this.memberIds,
    required this.acceptedIds,
  });

  @override
  Widget build(BuildContext context) {
    if (memberIds.isEmpty) {
      return const Text(
        'No pingpals',
        style: TextStyle(color: AppTheme.textGray),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(
        FieldPath.documentId,
        whereIn: memberIds.take(10).toList(),
      )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            final bool isActive = acceptedIds.contains(doc.id);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['photoUrl'] != null &&
                    user['photoUrl'].toString().isNotEmpty
                    ? NetworkImage(user['photoUrl'])
                    : null,
                backgroundColor: AppTheme.inputBackground,
                child: user['photoUrl'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                user['fullName'] ?? 'Pingpal',
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              trailing: Icon(
                isActive ? Icons.circle : Icons.circle_outlined,
                size: 14,
                color: isActive ? Colors.green : AppTheme.textGray,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
