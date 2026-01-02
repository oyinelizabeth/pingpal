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

  // ------------------------ MAP VIEW ------------------------
  Widget _buildMapView() {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pingtrails')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            final Set<Marker> markers = {
              const Marker(
                markerId: MarkerId('user_location'),
                position: LatLng(51.5074, -0.1278),
                infoWindow: InfoWindow(title: 'You'),
              ),
            };

            final Set<Circle> circles = {};

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                if (data['destination'] is! GeoPoint) continue;

                final GeoPoint dest = data['destination'];
                final LatLng destLatLng =
                LatLng(dest.latitude, dest.longitude);

                final String title =
                (data['destinationName'] ?? 'Pingtrail').toString();

                final List<String> members =
                (data['members'] as List<dynamic>? ?? [])
                    .whereType<String>()
                    .toList();

                final int memberCount = members.length;

                final String memberText = memberCount == 1
                    ? '1 pingpal heading here'
                    : '$memberCount pingpals heading here';

                String etaText = '';

                if (data['arrivalTime'] is Timestamp) {
                  final DateTime arrivalTime =
                  (data['arrivalTime'] as Timestamp).toDate();

                  final Duration diff =
                  arrivalTime.difference(DateTime.now());

                  if (diff.inMinutes > 0 && diff.inMinutes <= 30) {
                    etaText =
                    '\nArrive by ${TimeOfDay.fromDateTime(arrivalTime).format(context)}';
                  }
                }

                circles.add(
                  Circle(
                    circleId: CircleId('pulse_${doc.id}'),
                    center: destLatLng,
                    radius: 90,
                    fillColor: AppTheme.primaryBlue.withOpacity(0.15),
                    strokeColor: AppTheme.primaryBlue.withOpacity(0.4),
                    strokeWidth: 2,
                  ),
                );

                markers.add(
                  Marker(
                    markerId: MarkerId('pingtrail_${doc.id}'),
                    position: destLatLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: '$memberText$etaText',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ActivePingtrailDetailsSheet(
                            doc: doc,
                            currentUserId:
                            FirebaseAuth.instance.currentUser!.uid,
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
              circles: circles,
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
