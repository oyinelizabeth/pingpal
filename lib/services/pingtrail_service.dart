import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PingTrailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createPingTrail({
    required String destinationName,
    required GeoPoint destination,
    required DateTime arrivalTime,
    required List<String> members,
  }) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('pingtrails').add({
      'creatorId': uid,
      'destinationName': destinationName,
      'destination': destination,
      'arrivalTime': Timestamp.fromDate(arrivalTime.toUtc()),
      'members': uid,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
