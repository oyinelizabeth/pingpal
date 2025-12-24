import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'pingtrail_complete.dart';

class PingtrailsHistoryPage extends StatefulWidget {
  const PingtrailsHistoryPage({super.key});

  @override
  State<PingtrailsHistoryPage> createState() => _PingtrailsHistoryPageState();
}

class _PingtrailsHistoryPageState extends State<PingtrailsHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Sample completed pingtrails data
  final List<Map<String, dynamic>> completedTrails = [
    {
      "title": "Roadtrip to Vegas",
      "destination": "Las Vegas Strip, NV",
      "date": "Oct 12",
      "duration": "2h 15m",
      "participants": [
        "https://i.pravatar.cc/150?img=1",
        "https://i.pravatar.cc/150?img=2",
        "https://i.pravatar.cc/150?img=3",
      ],
      "additionalCount": 2,
      "thumbnail": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400",
      "completed": true,
    },
    {
      "title": "Friday Night Dinner",
      "destination": "123 Sushi Lane,...",
      "date": "Nov 14",
      "duration": "45m",
      "participants": [
        "https://i.pravatar.cc/150?img=4",
        "https://i.pravatar.cc/150?img=5",
      ],
      "additionalCount": 0,
      "thumbnail": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400",
      "completed": true,
    },
    {
      "title": "Morning Hike",
      "destination": "Blue Ridge Trailhead",
      "date": "Yesterday",
      "duration": "3h 10m",
      "participants": [
        "https://i.pravatar.cc/150?img=6",
        "https://i.pravatar.cc/150?img=7",
        "https://i.pravatar.cc/150?img=8",
      ],
      "additionalCount": 0,
      "thumbnail": "https://images.unsplash.com/photo-1551632811-561732d1e306?w=400",
      "completed": true,
    },
    {
      "title": "Stadium Concert",
      "destination": "City Arena, Gate 4",
      "date": "Last Week",
      "duration": "55m",
      "participants": [
        "https://i.pravatar.cc/150?img=9",
      ],
      "additionalCount": 4,
      "thumbnail": "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400",
      "completed": true,
    },
  ];

  // Sample cancelled pingtrails data
  final List<Map<String, dynamic>> cancelledTrails = [
    {
      "title": "Beach Day",
      "destination": "Santa Monica Pier",
      "date": "2 weeks ago",
      "duration": "N/A",
      "participants": [
        "https://i.pravatar.cc/150?img=10",
        "https://i.pravatar.cc/150?img=11",
      ],
      "additionalCount": 1,
      "thumbnail": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400",
      "completed": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openTrailDetails(Map<String, dynamic> trail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PingtrailCompletePage(
          trailName: trail["title"],
          destination: trail["destination"],
          duration: trail["duration"],
          distance: '3.2 km',
          participants: [
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
          ],
        ),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppTheme.textWhite,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pingtrails History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
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
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Search trails by friend or destination',
                    hintStyle: TextStyle(
                      color: AppTheme.textGray.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppTheme.primaryBlue,
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
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textGray,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCompletedTab(),
                  _buildCancelledTab(),
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
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: completedTrails.length,
      itemBuilder: (context, index) {
        return _buildTrailCard(completedTrails[index], true);
      },
    );
  }

  Widget _buildCancelledTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: cancelledTrails.length,
      itemBuilder: (context, index) {
        return _buildTrailCard(cancelledTrails[index], false);
      },
    );
  }

  Widget _buildTrailCard(Map<String, dynamic> trail, bool isCompleted) {
    return GestureDetector(
      onTap: isCompleted ? () => _openTrailDetails(trail) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground,
                  image: DecorationImage(
                    image: NetworkImage(trail["thumbnail"]),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trail["title"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ),
                        Icon(
                          isCompleted
                              ? FontAwesomeIcons.circleCheck
                              : FontAwesomeIcons.circleXmark,
                          color: isCompleted ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Destination
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.locationDot,
                          color: isCompleted
                              ? AppTheme.primaryBlue
                              : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            trail["destination"],
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Participants
                    Row(
                      children: [
                        ...List.generate(
                          trail["participants"].length.clamp(0, 3),
                          (index) => Container(
                            margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.cardBackground,
                              backgroundImage: NetworkImage(
                                trail["participants"][index],
                              ),
                            ),
                          ),
                        ),
                        if (trail["additionalCount"] > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.inputBackground,
                              child: Text(
                                '+${trail["additionalCount"]}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Date and Duration
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trail["date"],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.clock,
                        size: 12,
                        color: AppTheme.textGray.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trail["duration"],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
