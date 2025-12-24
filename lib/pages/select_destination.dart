import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'pingtrail_complete.dart';
import 'dart:async';

class SelectDestinationPage extends StatefulWidget {
  final String trailName;
  final List<Map<String, dynamic>> selectedFriends;

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
  final TextEditingController _searchController = TextEditingController(
    text: 'Cosmic Bowli',
  );
  GoogleMapController? _mapController;
  final bool _showDestinationDetails = true;

  // Sample destination data
  final Map<String, dynamic> selectedDestination = {
    "name": "Cosmic Bowling Center",
    "address": "42 Galaxy Lane, Star City",
    "status": "OPEN",
    "rating": 4.8,
    "reviewCount": 124,
    "travelTime": "12 min",
    "category": "Entertainment",
    "icon": FontAwesomeIcons.gamepad,
    "location": const LatLng(34.0522, -118.2437),
  };

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: selectedDestination["location"],
        infoWindow: InfoWindow(
          title: selectedDestination["name"],
          snippet: '${selectedDestination["travelTime"]} drive',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startPingtrail() {
    // TODO: Start pingtrail and send invites to selected friends
    // For demo purposes, show completion screen after a delay
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Pingtrail Started!',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Invitations sent to ${widget.selectedFriends.length} pingpals for "${widget.trailName}"',
          style: const TextStyle(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Done',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to completion screen (for demo)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PingtrailCompletePage(
                    trailName: widget.trailName,
                    destination: selectedDestination["name"],
                    duration: '45m 12s',
                    distance: '3.2 km',
                    participants: const [
                      {
                        "name": "You",
                        "avatar": "https://i.pravatar.cc/150?img=8",
                        "arrivalTime": "20:12",
                        "timeDiff": "+0m",
                        "isHost": true,
                        "arrived": true,
                      },
                      {
                        "name": "Sarah",
                        "avatar": "https://i.pravatar.cc/150?img=3",
                        "arrivalTime": "20:15",
                        "timeDiff": "+3m",
                        "arrived": true,
                      },
                      {
                        "name": "Mike",
                        "avatar": "https://i.pravatar.cc/150?img=2",
                        "arrivalTime": "20:18",
                        "timeDiff": "+6m",
                        "arrived": true,
                      },
                      {
                        "name": "Jessica",
                        "avatar": "https://i.pravatar.cc/150?img=1",
                        "arrivalTime": "20:25",
                        "timeDiff": "+13m",
                        "arrived": true,
                      },
                    ],
                  ),
                ),
              );
            },
            child: const Text(
              'View Summary',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _shareLocationOnly() {
    // TODO: Share location without creating pingtrail
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing location only...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedDestination["location"],
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.arrowLeft,
                        color: AppTheme.textWhite,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for destination',
                          hintStyle: TextStyle(
                            color: AppTheme.textGray.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            color: AppTheme.textGray,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.xmark,
                              color: AppTheme.textGray,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with Destination Details
          if (_showDestinationDetails)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Destination Info
                          Row(
                            children: [
                              // Category Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.inputBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  selectedDestination["icon"],
                                  color: AppTheme.textWhite,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Name and Address
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDestination["name"],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedDestination["address"],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textGray.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Status, Rating, and Travel Time
                          Row(
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedDestination["status"],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Rating
                              const Icon(
                                FontAwesomeIcons.solidStar,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${selectedDestination["rating"]} (${selectedDestination["reviewCount"]})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),

                              const Spacer(),

                              // Travel Time
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.car,
                                      color: AppTheme.primaryBlue,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedDestination["travelTime"],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Start Pingtrail Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _startPingtrail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(
                                FontAwesomeIcons.arrowRight,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Start Pingtrail Here',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Share Location Only Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _shareLocationOnly,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                  width: 1.5,
                                ),
                                backgroundColor: AppTheme.inputBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(
                                FontAwesomeIcons.locationCrosshairs,
                                color: AppTheme.textWhite,
                                size: 16,
                              ),
                              label: const Text(
                                'Share Location Only',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Compass/Recenter Button
          Positioned(
            bottom: _showDestinationDetails ? 450 : 120,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'compass',
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: selectedDestination["location"],
                      zoom: 14,
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.cardBackground,
              child: const Icon(
                FontAwesomeIcons.paperPlane,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index != _navIndex) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }
}
