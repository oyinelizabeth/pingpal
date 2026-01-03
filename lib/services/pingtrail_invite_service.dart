import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class PingtrailInviteService {
  static final _firestore = FirebaseFirestore.instance;

  // Creates a Pingtrail invitation and stores it under the trail document
  static Future<void> inviteUser({
    required String pingtrailId,
    required String hostId,
    required String hostName,
    required String invitedUserId,
  }) async {
    // Stores the invitation with pending status
    final invitationRef = _firestore
        .collection('ping_trails')
        .doc(pingtrailId)
        .collection('invitations')
        .doc();

    await invitationRef.set({
      'fromId': hostId,
      'toId': invitedUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Sends a notification to the invited user
    await NotificationService.send(
      receiverId: invitedUserId,
      senderId: hostId,
      title: 'Pingtrail invitation',
      body: '$hostName invited you to a Pingtrail',
      type: 'pingtrail_invitation',
      pingtrailId: pingtrailId,
      invitationId: invitationRef.id,
    );
  }
}
