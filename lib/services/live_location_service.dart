import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _lastPosition;

  static Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Start sharing live location for a specific pingtrail
  static Future<void> start({
    required String pingtrailId,
  }) async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25, // update only if moved 25m
      ),
    ).listen((position) async {
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

      await FirebaseFirestore.instance
          .collection('user_locations')
          .doc('${uid}_$pingtrailId')
          .set({
        'uid': uid,
        'pingtrailId': pingtrailId,
        'location': GeoPoint(
          position.latitude,
          position.longitude,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Stop sharing location
  static Future<void> stop({
    required String pingtrailId,
  }) async {
    await _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
  }
}
