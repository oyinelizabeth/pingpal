import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

import 'profile.dart';
import 'friends.dart';
import 'chats.dart';  // ChatPage (conversation)
import 'inbox.dart'; // ChatsPage (inbox list)
import 'map.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int navIndex = 0;

  // temporary demo data for friends list
  // NEED TO REPLACE WITH LIVE DATA FROM BACKEND
  
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

  /// Pull-to-refresh handler (currently a placeholder)
  /// This will later call backend APIs to refresh live data.
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // -------------------- NAVIGATION HANDLERS --------------------

  // navigates to the user's profile page
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // navigate to the friends list page
  void _openFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendsPage(friends: friends)),
    );
  }

  // navigate to chats inbox
  void _openChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatsPage()),
    );
  }

  // navigate to full interactive map screen
  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPage()),
    );
  }

  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ------------------------ APP BAR -------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Welcome back 👋",
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        // profile picture in the top right, acts as a shortcut to ProfilePage/settings
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openProfile,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.softPink,
                backgroundImage:
                    NetworkImage("https://i.pravatar.cc/150?img=5"),
              ),
            ),
          ),
        ],
      ),

      // ------------------------ MAIN BODY ------------------------
      body: RefreshIndicator(
        // pull-to-refresh functionality
        onRefresh: _onRefresh, 
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ------------------------ MAP PREVIEW ------------------------
              // GoogleMap widget shown on the home screen.
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(51.5074, -0.1278), // London default
                      zoom: 12,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // ------------------------ FRIENDS SECTION ---------------------
              const Text(
                "Friends",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 12),

              // shows a summary of friends and their status and takes the user to the full friends list page.
              GestureDetector(
                onTap: _openFriends,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.softPink, width: 1.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: friends.map((friend) {
                      final isLast = friend == friends.last;

                      return Column(
                        children: [
                          Row(
                            children: [
                              // friend's profile picture
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(friend["avatar"]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // friend's name and online status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend["name"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textBlack,
                                    ),
                                  ),
                                  Text(
                                    friend["online"] ? "Online" : "Offline",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: friend["online"]
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // arrow icon indicating tap behaviour
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: AppTheme.primaryPink,
                              ),
                            ],
                          ),

                          // divider between each friend tile
                          if (!isLast)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: AppTheme.softPink,
                                thickness: 1,
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------ FEATURES GRID -----------------------
              const Text(
                "Features",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 12),

              // shortcuts to features.
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1,
                children: [
                  _featureTile(Icons.chat_bubble_outline, "Chats", _openChats),
                  _featureTile(Icons.share_location, "Share", _openMap),
                  _featureTile(Icons.warning_amber_rounded, "Emergency", () {}),
                  _featureTile(Icons.map_outlined, "Map", _openMap),
                  _featureTile(Icons.people_alt_outlined, "Friends", _openFriends),
                  _featureTile(Icons.settings_outlined, "Settings", () {}),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ------------------------ BOTTOM NAVIGATION ------------------------
      bottomNavigationBar: NavBar(
        currentIndex: navIndex,
        onTap: (i) {
          setState(() => navIndex = i);

          // each button is linked to a different page.
          if (i == 1) _openMap();
          if (i == 2) _openChats();
          if (i == 3) _openFriends();
          if (i == 4) _openProfile();
        },
      ),
    );
  }

  // ------------------------ FEATURE TILE BUILDER ------------------------
  // feature grid
  Widget _featureTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.softPink.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softPink, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryPink, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textBlack,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
