import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class PendingPingtrailDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const PendingPingtrailDetailsSheet({
    super.key,
    required this.doc,
    required this.currentUserId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final participants = (data['participants'] as List<dynamic>? ?? []);
    final members = (data['members'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final acceptedIds = participants
        .where((p) => p['status'] == 'accepted')
        .map((p) => p['userId'].toString())
        .toList();

    final trailName = data['name'] ?? 'Pingtrail';
    final destinationName = data['destinationName'] ?? 'Destination';

    final isHost = data['hostId'] == currentUserId;
    final hasAccepted = acceptedIds.contains(currentUserId);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
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

            // Trail name
            Text(
              trailName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),

            const SizedBox(height: 6),

            // Destination
            Text(
              destinationName,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textGray.withOpacity(0.85),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${acceptedIds.length} / ${participants.length} pingpals accepted',
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

            PendingPingtrailMembersList(
              memberIds: participants.map((p) => p['userId'].toString()).toList(),
              acceptedIds: acceptedIds,
              hostId: data['hostId'],
            ),

            const SizedBox(height: 28),

            if (!isHost && !hasAccepted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onAccept();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onDecline();
                        Navigator.pop(context);
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),

            if (hasAccepted)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'You have already accepted this pingtrail',
                  style: TextStyle(color: Colors.green),
                ),
              ),

            if (isHost)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Waiting for pingpals to accept…',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PendingPingtrailMembersList extends StatelessWidget {
  final List<String> memberIds;
  final List<String> acceptedIds;
  final String hostId;

  const PendingPingtrailMembersList({
    super.key,
    required this.memberIds,
    required this.acceptedIds,
    required this.hostId,
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
        whereIn: memberIds,
      )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            final uid = doc.id;

            final isHost = uid == hostId;
            final hasAccepted = acceptedIds.contains(uid);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: user['photoUrl'] != null &&
                        user['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(user['photoUrl'])
                        : null,
                    backgroundColor: AppTheme.inputBackground,
                    child: user['photoUrl'] == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user['fullName'] ?? 'Pingpal',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isHost)
                    const Text(
                      'Host',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (hasAccepted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 18)
                  else
                    const Icon(Icons.hourglass_top,
                        color: Colors.orange, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
