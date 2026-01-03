import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  LatLng? _userLocation;

  final List<Map<String, dynamic>> friendLocations = [
    {
      "name": "Emma",
      "position": const LatLng(51.509, -0.13),
    },
    {
      "name": "Jacob",
      "position": const LatLng(51.503, -0.12),
    },
    {
      "name": "Ava",
      "position": const LatLng(51.51, -0.135),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  // ─────────────────────────────
  // Get REAL user location
  // ─────────────────────────────
  Future<void> _loadUserLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );
    }
  }

  Set<Marker> get _markers {
    final markers = friendLocations.map((f) {
      return Marker(
        markerId: MarkerId(f["name"] as String),
        position: f["position"] as LatLng,
        infoWindow: InfoWindow(title: f["name"] as String),
      );
    }).toSet();

    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('you'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map"),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(51.5074, -0.1278), // fallback
          zoom: 13,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (c) {
          _controller = c;
          if (_userLocation != null) {
            _controller!.animateCamera(
              CameraUpdate.newLatLngZoom(_userLocation!, 14),
            );
          }
        },
      ),
    );
  }
}
