import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                      markerId: const MarkerId('destination'),
                      position: destination,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                  };

                  final Set<Polyline> polylines = {};

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final raw =
                      doc.data() as Map<String, dynamic>;
                      if (raw['location'] is! GeoPoint) continue;

                      final GeoPoint gp = raw['location'];
                      final LatLng loc =
                      LatLng(gp.latitude, gp.longitude);
                      final String uid = doc.id;

                      // YOU → destination
                      if (uid == currentUserId) {
                        polylines.add(
                          Polyline(
                            polylineId: const PolylineId('you'),
                            points: [loc, destination],
                            color: AppTheme.primaryBlue,
                            width: 6,
                          ),
                        );
                      } else {
                        // OTHER MEMBERS → destination
                        polylines.add(
                          Polyline(
                            polylineId:
                            PolylineId('member_$uid'),
                            points: [loc, destination],
                            color: AppTheme.primaryBlue
                                .withOpacity(0.35),
                            width: 4,
                          ),
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
                    polylines: polylines,
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
      ),
    );
  }
}
