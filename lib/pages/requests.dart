
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _navIndex = 1; // Requests is at index 1
  int _newRequestsCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Sample data for received requests
  final List<Map<String, dynamic>> receivedRequests = [
    {
      "name": "Alex Chen",
      "username": "@alexc",
      "avatar": "https://i.pravatar.cc/150?img=1",
      "time": "2m ago",
      "message": "Found you via nearby trails",
      "verified": true,
      "hasLocation": true,
    },
    {
      "name": "Marcus Johnson",
      "username": "@marcus_j",
      "avatar": "https://i.pravatar.cc/150?img=2",
      "time": "1h ago",
      "message": "Wants to join your Pingtrail to Downtown",
      "verified": false,
      "hasLocation": false,
    },
    {
      "name": "Sarah Jones",
      "username": "@sarah_jones",
      "avatar": "https://i.pravatar.cc/150?img=3",
      "time": "yesterday",
      "message": "",
      "verified": false,
      "hasLocation": false,
    },
  ];

  // Sample data for suggested pingpals
  final List<Map<String, dynamic>> suggestedPingpals = [
    {
      "name": "Davide",
      "avatar": "https://i.pravatar.cc/150?img=4",
    },
    {
      "name": "Elara",
      "avatar": "https://i.pravatar.cc/150?img=5",
    },
    {
      "name": "Jordan",
      "avatar": "https://i.pravatar.cc/150?img=6",
    },
  ];

  void _markAllAsRead() {
    setState(() {
      _newRequestsCount = 0;
    });
  }

  void _acceptRequest(int index) {
    setState(() {
      receivedRequests.removeAt(index);
      _newRequestsCount = receivedRequests.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted'),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _declineRequest(int index) {
    setState(() {
      receivedRequests.removeAt(index);
      _newRequestsCount = receivedRequests.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request declined'),
        backgroundColor: AppTheme.textGray,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ping Requests',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your connections',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.gear,
                      color: AppTheme.textWhite,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextField(
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Find new Pingpals',
                    hintStyle: TextStyle(
                      color: AppTheme.textGray.withOpacity(0.6),
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppTheme.textGray,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.textWhite,
                unselectedLabelColor: AppTheme.textGray,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Received'),
                        if (_newRequestsCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Sent'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReceivedTab(),
                  _buildSentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index != _navIndex) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildReceivedTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Mark all read
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEW REQUESTS ($_newRequestsCount)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    letterSpacing: 1,
                  ),
                ),
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Request Cards
          ...List.generate(receivedRequests.length, (index) {
            return _buildRequestCard(receivedRequests[index], index);
          }),

          const SizedBox(height: 32),

          // Suggested Pingpals
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SUGGESTED PINGPALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: suggestedPingpals.map((pingpal) {
                return _buildSuggestedCard(pingpal);
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with location badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(request["avatar"]),
                  ),
                  if (request["hasLocation"])
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          FontAwesomeIcons.locationDot,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          request["name"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        if (request["verified"]) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            FontAwesomeIcons.circleCheck,
                            color: AppTheme.primaryBlue,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request["username"]} • Pinged ${request["time"]}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),
                    if (request["message"].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        request["message"],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineRequest(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    backgroundColor: AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(Map<String, dynamic> pingpal) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(pingpal["avatar"]),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  FontAwesomeIcons.plus,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pingpal["name"],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildSentTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.paperPlane,
            size: 48,
            color: AppTheme.textGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sent requests',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Requests you send will appear here',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
