import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../theme/app_theme.dart';
import '../services/live_location_service.dart';
import '../services/notification_service.dart';
import '../services/pingtrail_service.dart';
import '../services/location_api_service.dart';

class ActivePingtrailMapPage extends StatefulWidget {
  final String pingtrailId;

  const ActivePingtrailMapPage({
    super.key,
    required this.pingtrailId,
  });

  @override
  State<ActivePingtrailMapPage> createState() =>
      _ActivePingtrailMapPageState();
}

class _ActivePingtrailMapPageState extends State<ActivePingtrailMapPage> {
  late final String currentUserId;
  final PingtrailService _pingtrailService = PingtrailService();

  GoogleMapController? _mapController;

  bool _hasArrived = false;
  bool _isArriving = false;
  bool _hasFittedCamera = false;

  String _currentUserName = 'A user';

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Timer? _writerTimer;
  Timer? _readerTimer;
  Map<String, Marker> _friendMarkers = {};

  // ─────────────────────────────
  // Lifecycle
  // ─────────────────────────────
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.pingtrailId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    currentUserId = user.uid;

    _loadCurrentUserName();
    _checkIfAlreadyArrived();

    _startLoops();
  }

  void _startLoops() {
    // 1. Writer Loop (Every 5 Seconds)
    _writerTimer = Timer.periodic(const Duration(seconds: 5), (_) => _writerLoop());

    // 2. Reader Loop (Every 2 Seconds)
    _readerTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readerLoop());
  }

  Future<void> _writerLoop() async {
    try {
      // Get GPS position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get Network Status
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      String networkType = '3g'; // Default
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkType = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        // Simple logic for PoC: assume mobile is 4g/3g.
        // In real app we could use another package for more detail.
        networkType = '4g';
      }

      // Action: Call POST /update
      await LocationApiService.sendLocation(
        userId: currentUserId,
        lat: position.latitude,
        lng: position.longitude,
        networkType: networkType,
      );

      // Arrival Detection
      if (!_hasArrived) {
        final trailSnap = await FirebaseFirestore.instance
            .collection('pingtrails')
            .doc(widget.pingtrailId)
            .get();

        if (trailSnap.exists) {
          final data = trailSnap.data()!;
          final dest = data['destination'];
          double destLat, destLng;
          if (dest is GeoPoint) {
            destLat = dest.latitude;
            destLng = dest.longitude;
          } else {
            destLat = (dest['lat'] as num).toDouble();
            destLng = (dest['lng'] as num).toDouble();
          }

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destLat,
            destLng,
          );

          if (distance < 50) {
            final List<dynamic> participantsData = data['participants'] ?? [];
            final List<String> memberIds = participantsData
                .map((p) => p['userId'].toString())
                .toList();
            _onArrivedPressed(memberIds);
          }
        }
      }
    } catch (e) {
      debugPrint('Writer loop error: $e');
    }
  }

  Future<void> _readerLoop() async {
    try {
      final List<dynamic> locations = await LocationApiService.getTrailLocations(widget.pingtrailId);

      setState(() {
        for (var loc in locations) {
          final String uid = loc['userId'];
          if (uid == currentUserId) continue;

          final double lat = (loc['location']['lat'] as num).toDouble();
          final double lng = (loc['location']['lng'] as num).toDouble();

          final marker = Marker(
            markerId: MarkerId(uid),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(title: 'Friend ($uid)'),
          );

          _friendMarkers[uid] = marker;
        }

        // Repaint all markers
        _markers.clear();
        _markers.addAll(_friendMarkers.values);

        // Add self marker (Blue)
        _addSelfMarker();
      });
    } catch (e) {
      debugPrint('Reader loop error: $e');
    }
  }

  Future<void> _addSelfMarker() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(currentUserId),
          position: LatLng(pos.latitude, pos.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Me'),
        ),
      );
    });
  }

  @override
  void dispose() {
    _writerTimer?.cancel();
    _readerTimer?.cancel();
    LiveLocationService.stop();
    super.dispose();
  }

  // ─────────────────────────────
  // Helpers
  // ─────────────────────────────
  Future<void> _loadCurrentUserName() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists && mounted) {
      _currentUserName =
          (snap.data()?['fullName'] ?? 'A user').toString();
    }
  }

  Future<void> _checkIfAlreadyArrived() async {
    final snap = await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .get();

    final arrivedMembers =
    (snap.data()?['arrivedMembers'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    if (arrivedMembers.contains(currentUserId)) {
      _hasArrived = true;
    }
  }

  // ─────────────────────────────
  // Camera helpers
  // ─────────────────────────────
  Future<void> _moveToUserLocation() async {
    if (_mapController == null) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        14,
      ),
    );
  }

  Future<void> _fitCamera(Set<LatLng> points) async {
    if (_mapController == null || points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  // ─────────────────────────────
  // Arrival
  // ─────────────────────────────
  Future<void> _onArrivedPressed(List<String> members) async {
    setState(() => _isArriving = true);

    try {
      await _pingtrailService.userArrived(
        pingtrailId: widget.pingtrailId,
        userName: _currentUserName,
        members: members,
      );

      setState(() => _hasArrived = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival confirmed 🎉')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm arrival')),
      );
    } finally {
      if (mounted) setState(() => _isArriving = false);
    }
  }

  // ─────────────────────────────
  // Cancel (host)
  // ─────────────────────────────
  Future<void> _cancelPingtrail(
      String hostId,
      String trailName,
      List<String> members,
      ) async {
    if (currentUserId != hostId) return;

    await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .update({
      'status': 'cancelled',
      'endedAt': FieldValue.serverTimestamp(),
    });

    for (final uid in members) {
      if (uid == hostId) continue;

      await NotificationService.send(
        receiverId: uid,
        senderId: hostId,
        title: 'Pingtrail cancelled',
        body: '$trailName was cancelled by the host',
        type: 'pingtrail_cancelled',
        pingtrailId: widget.pingtrailId,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Live Pingtrail'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pingtrails')
            .doc(widget.pingtrailId)
            .snapshots(),
        builder: (context, trailSnap) {
          if (!trailSnap.hasData || !trailSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final trail = trailSnap.data!.data() as Map<String, dynamic>;
          if (trail['destination'] is! GeoPoint) {
            return const Center(
              child: Text(
                'Destination not set',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final GeoPoint destGp = trail['destination'];
          final LatLng destination =
          LatLng(destGp.latitude, destGp.longitude);

          final List<String> members =
          (trail['members'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList();

          final String hostId = (trail['creatorId'] ?? '').toString();
          final String trailName =
          (trail['destinationName'] ?? 'Pingtrail').toString();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pingtrails')
                .doc(widget.pingtrailId)
                .collection('liveLocations')
                .snapshots(),
            builder: (context, snapshot) {
              _markers.clear();
              _polylines.clear();

              final Set<LatLng> cameraPoints = {destination};

              _markers.add(
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              );

              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final raw = doc.data() as Map<String, dynamic>;
                  if (raw['location'] is! GeoPoint) continue;

                  final GeoPoint gp = raw['location'];
                  final LatLng loc =
                  LatLng(gp.latitude, gp.longitude);
                  final String uid = doc.id;

                  cameraPoints.add(loc);

                  _markers.add(
                    Marker(
                      markerId: MarkerId(uid),
                      position: loc,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        uid == currentUserId
                            ? BitmapDescriptor.hueAzure
                            : BitmapDescriptor.hueRed,
                      ),
                    ),
                  );

                  _polylines.add(
                    Polyline(
                      polylineId: PolylineId(uid),
                      points: [loc, destination],
                      color: uid == currentUserId
                          ? AppTheme.primaryBlue
                          : AppTheme.primaryBlue.withOpacity(0.35),
                      width: uid == currentUserId ? 6 : 4,
                    ),
                  );
                }
              }

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!_hasFittedCamera &&
                    cameraPoints.length > 1 &&
                    _mapController != null) {
                  _hasFittedCamera = true;
                  await _fitCamera(cameraPoints);
                } else if (_mapController != null &&
                    cameraPoints.length == 1) {
                  await _moveToUserLocation();
                }
              });

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: destination,
                      zoom: 13,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) => _mapController = c,
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: ElevatedButton.icon(
                      onPressed: _hasArrived || _isArriving
                          ? null
                          : () => _onArrivedPressed(members),
                      icon: const Icon(Icons.flag),
                      label: Text(
                        _hasArrived
                            ? 'Arrival confirmed'
                            : "I've arrived",
                      ),
                    ),
                  ),

                  if (currentUserId == hostId)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                        onPressed: () => _cancelPingtrail(
                          hostId,
                          trailName,
                          members,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
