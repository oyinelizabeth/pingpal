import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PingtrailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Creates a new Pingtrail document with host, destination, and participants
  Future<String> createPingtrail({
    required String name,
    required String destinationName,
    required GeoPoint destination,
    required DateTime arrivalTime,
    required List<String> participants,
  }) async {
    final uid = _auth.currentUser!.uid;

    final docRef = await _firestore.collection('ping_trails').add({
      'hostId': uid,
      'name': name,
      'destinationName': destinationName,
      'destination': destination,
      'arrivalTime': Timestamp.fromDate(arrivalTime.toUtc()),
      'participants': participants.map((pId) => {
        'userId': pId,
        'status': pId == uid ? 'accepted' : 'pending',
      }).toList(),
      'arrivedMembers': [],
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Marks a user as arrived using a Firestore transaction for consistency
  Future<void> markUserArrived({
    required String pingtrailId,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser!.uid;

    final docRef = _firestore.collection('ping_trails').doc(pingtrailId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> participants = List.from(data['participants'] ?? []);

      bool updated = false;
      for (var p in participants) {
        if (p['userId'] == uid) {
          p['status'] = 'arrived';
          p['arrivedAt'] = FieldValue.serverTimestamp();
          updated = true;
          break;
        }
      }

      if (updated) {
        transaction.update(docRef, {
          'participants': participants,
          'arrivedMembers': FieldValue.arrayUnion([uid]),
        });
      } else {
        // Fallback to ensure arrival is still recorded
        transaction.update(docRef, {
          'arrivedMembers': FieldValue.arrayUnion([uid]),
        });
      }
    });
  }

  // Sends arrival notifications to all other Pingtrail members
  Future<void> sendArrivalNotifications({
    required String pingtrailId,
    required String userId,
    required String userName,
    required List<String> members,
  }) async {
    final batch = _firestore.batch();
    final notifications = _firestore.collection('notifications');

    for (final uid in members) {
      if (uid == userId) continue;

      final doc = notifications.doc();
      batch.set(doc, {
        'type': 'arrival',
        'pingtrailId': pingtrailId,
        'receiverId': uid,
        'senderId': userId,
        'title': 'Arrival update',
        'body': '$userName has arrived at the destination',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Handles the full arrival flow: update status and notify members
  Future<void> userArrived({
    required String pingtrailId,
    required String userName,
    required List<String> members,
  }) async {
    final uid = _auth.currentUser!.uid;

    await markUserArrived(
      pingtrailId: pingtrailId,
      userId: uid,
    );

    await sendArrivalNotifications(
      pingtrailId: pingtrailId,
      userId: uid,
      userName: userName,
      members: members,
    );
  }
}
