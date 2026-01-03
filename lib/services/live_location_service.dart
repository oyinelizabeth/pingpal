import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _lastPosition;

  // Ensures location services and permissions are granted before tracking
  static Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Starts continuous live location tracking for an active Pingtrail
  static Future<void> start({
    required String pingtrailId,
  }) async {
    if (pingtrailId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasPermission = await _ensurePermission();
    if (!hasPermission) return;

    await stop(); // Prevents multiple active location streams

    final uid = user.uid;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((position) async {
      // Filters out insignificant movement to reduce database writes
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < 20) return;
      }

      _lastPosition = position;

      // Writes live location updates to Firestore for real-time syncing
      await FirebaseFirestore.instance
          .collection('ping_trails')
          .doc(pingtrailId)
          .collection('liveLocations')
          .doc(uid)
          .set({
        'location': GeoPoint(
          position.latitude,
          position.longitude,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // Stops live location tracking and clears cached state
  static Future<void> stop() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
  }
}
