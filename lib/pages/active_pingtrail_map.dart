import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/live_location_service.dart';

class ActivePingtrailMapPage extends StatefulWidget {
  final String pingtrailId;
  final GeoPoint destination;

  const ActivePingtrailMapPage({
    super.key,
    required this.pingtrailId,
    required this.destination,
  });

  @override
  State<ActivePingtrailMapPage> createState() =>
      _ActivePingtrailMapPageState();
}

class _ActivePingtrailMapPageState extends State<ActivePingtrailMapPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    LiveLocationService.start(pingtrailId: widget.pingtrailId);
  }

  @override
  void dispose() {
    LiveLocationService.stop(pingtrailId: widget.pingtrailId);
    super.dispose();
  }

  Future<void> _cancelPingtrail() async {
    final confirmed = await _confirmCancel();
    if (!confirmed) return;

    /// Stop sharing location immediately
    LiveLocationService.stop(pingtrailId: widget.pingtrailId);

    await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .update({
      'status': 'cancelled',
      'endedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool> _confirmCancel() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Pingtrail?'),
        content: const Text(
          'This will end the pingtrail for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,

      /// TOP BAR
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Live Pingtrail'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pingtrails')
                .doc(widget.pingtrailId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final bool isHost = data['hostId'] == currentUserId;

              if (!isHost) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _cancelPingtrail,
                tooltip: 'Cancel Pingtrail',
              );
            },
          ),
        ],

      ),

      /// LIVE MAP
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_locations')
            .where('pingtrailId', isEqualTo: widget.pingtrailId)
            .snapshots(),
        builder: (context, snapshot) {
          final Set<Marker> markers = {};

          /// Destination marker
          markers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(
                widget.destination.latitude,
                widget.destination.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: const InfoWindow(title: 'Destination'),
            ),
          );

          /// Live user markers
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final GeoPoint location = data['location'];
              final String uid = data['uid'];

              markers.add(
                Marker(
                  markerId: MarkerId(uid),
                  position: LatLng(
                    location.latitude,
                    location.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    uid == currentUserId
                        ? BitmapDescriptor.hueAzure
                        : BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: uid == currentUserId ? 'You' : 'Pingpal',
                  ),
                ),
              );
            }
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.destination.latitude,
                widget.destination.longitude,
              ),
              zoom: 13,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          );
        },
      ),
    );
  }
}
