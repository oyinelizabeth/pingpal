import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import '../widgets/search_bar_widget.dart';

import 'profile.dart';
import 'friends.dart';
import 'inbox.dart';
import 'map.dart';
import 'notifications.dart';
import 'requests.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  GoogleMapController? _mapController;
  bool _hasNotifications = true;

  final List<Widget> _pages = [];

  // Temporary demo data
  final List<Map<String, dynamic>> friends = [
    {
      "name": "Emma Wilson",
      "avatar": "https://i.pravatar.cc/150?img=1",
      "online": true,
    },
    {
      "name": "Jacob Smith",
      "avatar": "https://i.pravatar.cc/150?img=2",
      "online": false,
    },
    {
      "name": "Ava Johnson",
      "avatar": "https://i.pravatar.cc/150?img=3",
      "online": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Do not build widgets that depend on context/MediaQuery in initState.
    // Index 0 is handled specially in build() via _buildMapView().
    _pages.addAll(const [
      SizedBox.shrink(), // placeholder for index 0 (map view is built in build())
      MapPage(),
      ChatsPage(),
      // RequestsPage is not const, add below outside the const list
    ]);
    _pages.addAll([
      RequestsPage(),
      const ProfilePage(),
    ]);
  }

  // -------------------- NAVIGATION --------------------
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void _centerMapOnUser() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(34.0522, -118.2437), // Los Angeles coordinates
        14,
      ),
    );
  }

  void _toggleMapLayers() {
    // Toggle between different map types
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map layers feature coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBodyBehindAppBar: true,
      body: _currentNavIndex == 0 ? _buildMapView() : _pages[_currentNavIndex],
      bottomNavigationBar: NavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  // ------------------------ MAP VIEW ------------------------
  Widget _buildMapView() {
    return Stack(
      children: [
        // Full-screen Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(34.0522, -118.2437), // Los Angeles
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            const Marker(
              markerId: MarkerId('user_location'),
              position: LatLng(34.0522, -118.2437),
              infoWindow: InfoWindow(title: 'You'),
            ),
          },
        ),

        // Top Section: Search Bar & Notification
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: SearchBarWidget(
                    hintText: 'Search pingpals or places...',
                    onTap: () {
                      // Open search page
                    },
                  ),
                ),

                // Notification Icon
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: _openNotifications,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.textWhite,
                          size: 26,
                        ),
                      ),
                      if (_hasNotifications)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.darkBackground,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // User Location Marker with "You" label
        Positioned(
          bottom: 200,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryBlue, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage("https://i.pravatar.cc/150?img=5"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              // Center on User Button
              FloatingActionButton(
                heroTag: 'center',
                onPressed: _centerMapOnUser,
                backgroundColor: AppTheme.cardBackground,
                child: const Icon(
                  Icons.navigation,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),

              // Layers Button
              FloatingActionButton(
                heroTag: 'layers',
                onPressed: _toggleMapLayers,
                backgroundColor: AppTheme.cardBackground,
                child: const Icon(
                  Icons.layers,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),

        // Map Center Button (Red Circle from screenshot)
        Positioned(
          bottom: 100,
          left: MediaQuery.of(context).size.width / 2 - 35,
          child: FloatingActionButton(
            heroTag: 'map_center',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              );
            },
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(
              Icons.map,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
