import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

import 'profile.dart';
import 'inbox.dart'; // ChatsPage (inbox list)
import 'pingtrail.dart';
import 'requests.dart';
import 'notifications.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int navIndex = 2; // Map is at index 2 (center)
  bool hasNotifications = true; // For notification badge

  // -------------------- NAVIGATION HANDLERS --------------------

  // navigate to pingtrail page
  void _openPingtrail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PingtrailPage()),
    );
  }

  // navigate to ping requests page
  void _openRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestsPage()),
    );
  }

  // navigate to chats inbox
  void _openChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatsPage()),
    );
  }

  // navigate to settings/profile
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // navigate to notifications
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    setState(() {
      hasNotifications = false; // Clear badge after viewing
    });
  }

  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ------------------------ FULL SCREEN MAP ------------------------
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(34.0522, -118.2437), // Los Angeles (from screenshot)
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ------------------------ TOP OVERLAY ------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search pingpals or places...',
                          hintStyle: TextStyle(
                            color: AppTheme.textGray.withOpacity(0.7),
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            color: AppTheme.textGray,
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Notification Bell
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.bell,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
                            onPressed: _openNotifications,
                          ),
                        ),
                        // Notification Badge
                        if (hasNotifications)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
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

          // ------------------------ FLOATING ACTION BUTTONS ------------------------
          // Recenter/My Location Button
          Positioned(
            bottom: 104,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'recenter',
              onPressed: () {
                // TODO: Recenter map to user's location
              },
              backgroundColor: AppTheme.cardBackground,
              child: const Icon(
                FontAwesomeIcons.locationCrosshairs,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),

          // Map Layers Button
          Positioned(
            bottom: 174,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'layers',
              onPressed: () {
                // TODO: Show map layer options
              },
              backgroundColor: AppTheme.cardBackground,
              child: const Icon(
                FontAwesomeIcons.layerGroup,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),

      // ------------------------ BOTTOM NAVIGATION ------------------------
      bottomNavigationBar: NavBar(
        currentIndex: navIndex,
        onTap: (i) {
          setState(() => navIndex = i);

          // Navigation routing
          if (i == 0) _openPingtrail();
          if (i == 1) _openRequests();
          // i == 2 is Map (current page, do nothing)
          if (i == 3) _openChats();
          if (i == 4) _openSettings();
        },
      ),
    );
  }
}
