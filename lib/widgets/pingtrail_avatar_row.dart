import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class PingtrailAvatarRow extends StatelessWidget {
  final List<String> memberIds;
  final double radius;
  final int maxVisible;

  const PingtrailAvatarRow({
    super.key,
    required this.memberIds,
    this.radius = 18,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (memberIds.isEmpty) return const SizedBox();

    final visibleIds = memberIds.take(maxVisible).toList();
    final extraCount = memberIds.length - visibleIds.length;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(
        FieldPath.documentId,
        whereIn: visibleIds,
      )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 32);
        }

        return SizedBox(
          height: radius * 2,
          child: Stack(
            children: [
              ...snapshot.data!.docs.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value.data() as Map<String, dynamic>;

                return Positioned(
                  left: index * (radius * 1.4),
                  child: CircleAvatar(
                    radius: radius,
                    backgroundColor: AppTheme.cardBackground,
                    backgroundImage: user['photoUrl'] != null &&
                        user['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(user['photoUrl'])
                        : null,
                    child: user['photoUrl'] == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                );
              }),

              if (extraCount > 0)
                Positioned(
                  left: visibleIds.length * (radius * 1.4),
                  child: CircleAvatar(
                    radius: radius,
                    backgroundColor: AppTheme.inputBackground,
                    child: Text(
                      '+$extraCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
