import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

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
  Timer? _pollingTimer;

  final Set<Marker> _markers = {};

  static const String backendBaseUrl =
      'http://34.28.189.176/api/location';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _fetchLiveLocations(),
    );
  }

  Future<void> _fetchLiveLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl?pingtrailId=${widget.pingtrailId}'),
      );

      if (response.statusCode != 200) return;

      final List data = jsonDecode(response.body);
      final Set<Marker> newMarkers = {};

      // 🔴 Live user markers (Redis)
      for (final user in data) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(user['userId']),
            position: LatLng(user['lat'], user['lng']),
            infoWindow: InfoWindow(
              title: user['name'] ?? 'Pingpal',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              user['userId'] == currentUserId
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      // Destination marker (Firestore)
      newMarkers.add(
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

      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    } catch (e) {
      debugPrint('Error fetching live locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.destination.latitude,
            widget.destination.longitude,
          ),
          zoom: 13,
        ),
        markers: _markers,
        myLocationEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
