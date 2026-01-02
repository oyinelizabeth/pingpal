import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import '../services/live_location_service.dart';
import '../services/notification_service.dart';
import '../services/pingtrail_service.dart';

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
  String _currentUserName = 'A user';

  // ───────── POLYLINE STATE ─────────
  final Set<Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  LatLng? _lastRouteOrigin;

  static const String _googleApiKey =
      'AIzaSyDLHq8J0RZKNvtgVImOmNicP4QuWCivQyc';

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

    LiveLocationService.start(pingtrailId: widget.pingtrailId);
  }

  @override
  void dispose() {
    LiveLocationService.stop();
    super.dispose();
  }

  // ─────────────────────────────
  // Load user name
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

  // ─────────────────────────────
  // Arrival state
  // ─────────────────────────────
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
  // Host cancel
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
  // HYBRID ROUTE (YOU)
  // ─────────────────────────────
  Future<void> _drawHybridRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_lastRouteOrigin != null) {
      final moved = Geolocator.distanceBetween(
        _lastRouteOrigin!.latitude,
        _lastRouteOrigin!.longitude,
        origin.latitude,
        origin.longitude,
      );
      if (moved < 30) return;
    }
    _lastRouteOrigin = origin;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _polylines
          ..removeWhere(
                (p) => p.polylineId.value == 'fallback' ||
                p.polylineId.value == 'route',
          )
          ..add(
            Polyline(
              polylineId: const PolylineId('fallback'),
              color: AppTheme.primaryBlue,
              width: 6,
              points: [origin, destination],
            ),
          );
      });
    });

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination:
          PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) return;

      final routePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _polylines
            ..removeWhere(
                  (p) => p.polylineId.value == 'fallback' ||
                  p.polylineId.value == 'route',
            )
            ..add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: AppTheme.primaryBlue,
                width: 6,
                points: routePoints,
              ),
            );
        });
      });
    } catch (_) {}
  }

  // ─────────────────────────────
  // STRAIGHT LINE (OTHER MEMBERS)
  // ─────────────────────────────
  void _addMemberLine({
    required String uid,
    required LatLng origin,
    required LatLng destination,
  }) {
    final id = PolylineId('member_$uid');

    if (!mounted) return;

    setState(() {
      _polylines.removeWhere((p) => p.polylineId == id);

      _polylines.add(
        Polyline(
          polylineId: id,
          points: [origin, destination],
          color: AppTheme.primaryBlue.withOpacity(0.35),
          width: 4,
        ),
      );
    });
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

          final trail =
          trailSnap.data!.data() as Map<String, dynamic>;

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

          final String hostId =
          (trail['creatorId'] ?? '').toString();

          final String trailName =
          (trail['destinationName'] ?? 'Pingtrail')
              .toString();

          return Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pingtrails')
                    .doc(widget.pingtrailId)
                    .collection('liveLocations')
                    .snapshots(),
                builder: (context, snapshot) {
                  final Set<Marker> markers = {
                    Marker(
                      markerId:
                      const MarkerId('destination'),
                      position: destination,
                      icon:
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                  };

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final raw =
                      doc.data() as Map<String, dynamic>;
                      if (raw['location'] is! GeoPoint) continue;

                      final GeoPoint locGp = raw['location'];
                      final LatLng loc =
                      LatLng(locGp.latitude, locGp.longitude);
                      final String uid = doc.id;

                      if (uid == currentUserId) {
                        _drawHybridRoute(
                          origin: loc,
                          destination: destination,
                        );
                      } else {
                        _addMemberLine(
                          uid: uid,
                          origin: loc,
                          destination: destination,
                        );
                      }

                      markers.add(
                        Marker(
                          markerId: MarkerId(uid),
                          position: loc,
                          icon:
                          BitmapDescriptor.defaultMarkerWithHue(
                            uid == currentUserId
                                ? BitmapDescriptor.hueAzure
                                : BitmapDescriptor.hueRed,
                          ),
                        ),
                      );
                    }
                  }

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: destination,
                      zoom: 13,
                    ),
                    markers: markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) =>
                    _mapController = c,
                  );
                },
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: ElevatedButton.icon(
                  onPressed:
                  _hasArrived || _isArriving
                      ? null
                      : () =>
                      _onArrivedPressed(members),
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
                    icon: const Icon(Icons.close,
                        color: Colors.red),
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
      ),
    );
  }
}
