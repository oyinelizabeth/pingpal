import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

import 'profile.dart';
import 'friends.dart';
import 'inbox.dart';
import 'map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int navIndex = 0;

  // Temporary demo data (to be replaced with Firebase data)
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

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // -------------------- NAVIGATION --------------------
  void _openProfile() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));

  void _openFriends() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage(friends: friends)));

  void _openChats() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsPage()));

  void _openMap() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));

  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,

      // ------------------------ APP BAR -------------------------
      appBar: AppBar(
        title: const Text(
          "Welcome back 👋",
          style: TextStyle(
            color: AppTheme.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openProfile,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.cardBackground,
                backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
              ),
            ),
          ),
        ],
      ),

      // ------------------------ BODY ------------------------
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ------------------------ MAP PREVIEW ------------------------
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(51.5074, -0.1278),
                      zoom: 12,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // ------------------------ FRIENDS ------------------------
              const Text(
                "Friends",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _openFriends,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: friends.map((friend) {
                      final isLast = friend == friends.last;

                      return Column(
                        children: [
                          Row(
                            children: [
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

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend["name"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                  Text(
                                    friend["online"] ? "Online" : "Offline",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: friend["online"]
                                          ? Colors.green
                                          : AppTheme.textGray,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ),

                          if (!isLast)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: AppTheme.dividerColor),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------ FEATURES ------------------------
              const Text(
                "Features",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),

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
            ],
          ),
        ),
      ),

      // ------------------------ NAV BAR ------------------------
      bottomNavigationBar: NavBar(
        currentIndex: navIndex,
        onTap: (i) {
          setState(() => navIndex = i);
          if (i == 1) _openMap();
          if (i == 2) _openChats();
          if (i == 3) _openFriends();
          if (i == 4) _openProfile();
        },
      ),
    );
  }

  // ------------------------ FEATURE TILE ------------------------
  Widget _featureTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textWhite,
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
