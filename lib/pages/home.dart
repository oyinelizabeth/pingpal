import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/active_pingtrail_details_sheet.dart';

import 'profile.dart';
import 'friends.dart';
import 'inbox.dart';
import 'map.dart';
import 'notifications.dart';
import 'requests.dart';
import 'pingtrail.dart';
import 'pingpals.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 2;
  GoogleMapController? _mapController;
  final bool _hasNotifications = true;

  final String _currentUserId =
      FirebaseAuth.instance.currentUser!.uid;

  final List<Widget> _pages = [];

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
    _pages.addAll([
      const PingtrailPage(),
      const PingpalsPage(),
      const SizedBox.shrink(),
      const ChatsPage(),
      const SettingsPage(),
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
        const LatLng(51.5074, -0.1278),
        14,
      ),
    );
  }

  void _toggleMapLayers() {
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
      body: _currentNavIndex == 2 ? _buildMapView() : _pages[_currentNavIndex],
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

  // ------------------------ ACTIVE PINGTRAIL OVERVIEW ------------------------
  Widget _buildActivePingtrailOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('status', isEqualTo: 'active')
          .where('members', arrayContains: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title =
              (data['destinationName'] ?? 'Pingtrail').toString();

              final List members =
              (data['members'] as List<dynamic>? ?? []);

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ActivePingtrailDetailsSheet(
                      doc: doc,
                      currentUserId: _currentUserId,
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryBlue,
                        size: 22,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        members.length == 1
                            ? '1 pingpal'
                            : '${members.length} pingpals',
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ------------------------ MAP VIEW ------------------------
  Widget _buildMapView() {
    return Stack(
      children: [
        // Full-screen Map with ACTIVE PINGTRAILS
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pingtrails')
              .where('status', isEqualTo: 'active')
              .where('members', arrayContains: _currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            final Set<Marker> markers = {
              const Marker(
                markerId: MarkerId('user_location'),
                position: LatLng(51.5074, -0.1278),
                infoWindow: InfoWindow(title: 'You'),
              ),
            };

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                if (data['destination'] is! GeoPoint) continue;

                final GeoPoint dest = data['destination'];
                final String title =
                (data['destinationName'] ?? 'Pingtrail').toString();

                markers.add(
                  Marker(
                    markerId: MarkerId('pingtrail_${doc.id}'),
                    position: LatLng(dest.latitude, dest.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: 'Active Pingtrail',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ActivePingtrailDetailsSheet(
                            doc: doc,
                            currentUserId: _currentUserId,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            }

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(51.5074, -0.1278),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: markers,
            );
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
                Expanded(
                  child: SearchBarWidget(
                    hintText: 'Search pingpals or places...',
                    onTap: () {},
                  ),
                ),
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

        // Active Pingtrails Overview (Horizontal Cards)
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: _buildActivePingtrailOverview(),
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
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
