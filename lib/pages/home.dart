import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

// correct pages
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

  // NAVIGATION HANDLERS ------------------------

  void _openProfile() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openFriends() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => FriendsPage(friends: friends)));
  }

  void _openChats() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ChatsPage())); // inbox
  }

  void _openMap() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const MapPage()));
  }

  // --------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // MAP SECTION -------------------------
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
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

              // FRIENDS SECTION ---------------------
              const Text(
                "Friends",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 12),

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
                              const Icon(Icons.arrow_forward_ios,
                                  size: 18, color: AppTheme.primaryPink),
                            ],
                          ),

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

              // FEATURES GRID -----------------------
              const Text(
                "Features",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
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
                  _featureTile(Icons.warning_amber_rounded,
                      "Emergency", () {}),
                  _featureTile(Icons.map_outlined, "Map", _openMap),
                  _featureTile(Icons.people_alt_outlined,
                      "Friends", _openFriends),
                  _featureTile(Icons.settings_outlined, "Settings", () {}),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // NAVBAR HANDLING --------------------------
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

  // Tile UI builder
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
