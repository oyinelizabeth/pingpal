import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class SelectDestinationPage extends StatefulWidget {
  final String trailName;
  final List<String> selectedFriends;

  const SelectDestinationPage({
    super.key,
    required this.trailName,
    required this.selectedFriends,
  });

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
  final int _navIndex = 0;
  final TextEditingController _destinationController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  final Set<Marker> _markers = {};

  Future<void> _startPingtrail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a destination name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('pingtrails').add({
      'hostId': user.uid,
      'name': widget.trailName,
      'destinationName': _destinationController.text.trim(),
      if (_selectedLatLng != null)
        'destinationGeo': GeoPoint(
          _selectedLatLng!.latitude,
          _selectedLatLng!.longitude,
        ),
      'members': [user.uid, ...widget.selectedFriends],
      'acceptedMembers': [user.uid],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'endedAt': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pingtrail created! Waiting for pingpals...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          /// MAP
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.5074, -0.1278), // London
              zoom: 12,
            ),
            myLocationEnabled: true,
            markers: _markers,
            onTap: (latLng) {
              setState(() {
                _selectedLatLng = latLng;
                _markers
                  ..clear()
                  ..add(
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: latLng,
                    ),
                  );
              });
            },
            onMapCreated: (controller) => _mapController = controller,
          ),

          /// TOP BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.cardBackground,
                    child: IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.arrowLeft,
                        color: AppTheme.textWhite,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// DESTINATION INPUT SHEET
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Destination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'e.g. Westfield Stratford',
                      hintStyle: TextStyle(
                        color: AppTheme.textGray.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startPingtrail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Start Pingtrail',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// RECENTER BUTTON
          Positioned(
            bottom: 220,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.cardBackground,
              child: const Icon(
                FontAwesomeIcons.locationArrow,
                color: AppTheme.primaryBlue,
              ),
              onPressed: () {
                if (_selectedLatLng != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLatLng!, 14),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (_) => Navigator.popUntil(context, (r) => r.isFirst),
      ),
    );
  }
}
