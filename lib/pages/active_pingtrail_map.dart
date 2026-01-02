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

    /// Start live location updates for pingtrail
    LiveLocationService.start(pingtrailId: widget.pingtrailId);
  }

  @override
  void dispose() {
    /// Stop live location updates
    LiveLocationService.stop(pingtrailId: widget.pingtrailId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
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
                    title: uid == currentUserId
                        ? 'You'
                        : 'Pingpal',
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
