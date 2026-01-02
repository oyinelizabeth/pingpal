import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class PingtrailInviteService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> inviteUser({
    required String pingtrailId,
    required String hostId,
    required String hostName,
    required String invitedUserId,
  }) async {
    // Create invitation
    final invitationRef = _firestore
        .collection('pingtrails')
        .doc(pingtrailId)
        .collection('invitations')
        .doc();

    await invitationRef.set({
      'fromId': hostId,
      'toId': invitedUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send notification
    await NotificationService.send(
      receiverId: invitedUserId,
      senderId: hostId,
      title: 'Pingtrail invitation',
      body: '$hostName invited you to a Pingtrail',
      type: 'pingtrail_invite',
      pingtrailId: pingtrailId,
      //invitationId: invitationRef.id,
    );
  }
}
