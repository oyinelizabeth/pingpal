import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  GoogleMapController? _mapController;
  final PingtrailService _pingtrailService = PingtrailService();

  bool _hasArrived = false;
  bool _isArriving = false;

  String _currentUserName = 'A user';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
    _checkIfAlreadyArrived();
    LiveLocationService.start(pingtrailId: widget.pingtrailId);
  }

  @override
  void dispose() {
    LiveLocationService.stop(pingtrailId: widget.pingtrailId);
    super.dispose();
  }

  // Load user's name
  Future<void> _loadCurrentUserName() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists) {
      setState(() {
        _currentUserName = snap.data()?['fullName'] ?? 'A user';
      });
    }
  }

  // Check arrival
  Future<void> _checkIfAlreadyArrived() async {
    final snap = await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .get();

    final arrivedMembers =
    List<String>.from(snap.data()?['arrivedMembers'] ?? []);

    if (arrivedMembers.contains(currentUserId)) {
      setState(() => _hasArrived = true);
    }
  }

  // Arrival button
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
      setState(() => _isArriving = false);
    }
  }

  Future<void> _cancelPingtrail(
      String hostId,
      String trailName,
      List<String> members,
      ) async {
    if (currentUserId != hostId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the host can cancel this pingtrail')),
      );
      return;
    }

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

  // UI
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
          if (!trailSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trail = trailSnap.data!.data() as Map<String, dynamic>;

          if (trail['destination'] == null) {
            return const Center(
              child: Text(
                'Destination not set',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final GeoPoint destination = trail['destination'];
          final List<String> members =
          List<String>.from(trail['members'] ?? []);
          final String hostId = trail['creatorId'];
          final String trailName =
          (trail['destinationName'] ?? 'Pingtrail').toString();

          return Stack(
            children: [
              // Map
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user_locations')
                    .where('pingtrailId',
                    isEqualTo: widget.pingtrailId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final Set<Marker> markers = {};

                  markers.add(
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: LatLng(
                        destination.latitude,
                        destination.longitude,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow:
                      const InfoWindow(title: 'Destination'),
                    ),
                  );

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final GeoPoint loc = data['location'];
                      final String uid = data['uid'];

                      markers.add(
                        Marker(
                          markerId: MarkerId(uid),
                          position:
                          LatLng(loc.latitude, loc.longitude),
                          icon:
                          BitmapDescriptor.defaultMarkerWithHue(
                            uid == currentUserId
                                ? BitmapDescriptor.hueAzure
                                : BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(
                            title:
                            uid == currentUserId ? 'You' : 'Pingpal',
                          ),
                        ),
                      );
                    }
                  }

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        destination.latitude,
                        destination.longitude,
                      ),
                      zoom: 13,
                    ),
                    markers: markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) => _mapController = c,
                  );
                },
              ),

              // Arrival button
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
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              // Cancel if the host
              if (currentUserId == hostId)
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
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
