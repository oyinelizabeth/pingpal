import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;

  static const LatLng center = LatLng(51.5074, -0.1278); // London

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

  Set<Marker> get _markers {
    return friendLocations.map((f) {
      return Marker(
        markerId: MarkerId(f["name"] as String),
        position: f["position"] as LatLng,
        infoWindow: InfoWindow(title: f["name"] as String),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map"),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: center,
          zoom: 13,
        ),
        markers: _markers,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
        onMapCreated: (c) => _controller = c,
      ),
    );
  }
}
