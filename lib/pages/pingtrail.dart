import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'create_pingtrail.dart';
import 'pingtrails_history.dart';

class PingtrailPage extends StatefulWidget {
  const PingtrailPage({super.key});

  @override
  State<PingtrailPage> createState() => _PingtrailPageState();
}

class _PingtrailPageState extends State<PingtrailPage> {
  int _navIndex = 0; // Pingtrail is at index 0

  // Sample data for active pingtrail
  final Map<String, dynamic>? activePingtrail = {
    "title": "Road Trip to Vegas",
    "timeRemaining": "120mi remaining",
    "duration": "2h 14m",
    "progress": 0.45,
    "participants": [
      "https://i.pravatar.cc/150?img=1",
      "https://i.pravatar.cc/150?img=2",
      "https://i.pravatar.cc/150?img=3",
    ],
    "additionalCount": 2,
  };

  // Sample data for past pingtrails
  final List<Map<String, dynamic>> pastPingtrails = [
    {
      "title": "Downtown Meetup",
      "endedTime": "15 mins ago",
      "participants": [
        "https://i.pravatar.cc/150?img=4",
        "https://i.pravatar.cc/150?img=5",
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header with profile icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pingtrail Hub',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.cardBackground,
                      backgroundImage: const NetworkImage(
                        "https://i.pravatar.cc/150?img=8",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Where to next?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 32),

                // Create New Pingtrail Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePingtrailPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      FontAwesomeIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Create New Pingtrail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Share Live Location Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Share live location
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                      backgroundColor: AppTheme.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      FontAwesomeIcons.locationCrosshairs,
                      color: AppTheme.textWhite,
                      size: 18,
                    ),
                    label: const Text(
                      'Share Live Location',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Active Pingtrail Section
                const Text(
                  'Active Pingtrail',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 16),

                if (activePingtrail != null)
                  _buildActivePingtrailCard(activePingtrail!)
                else
                  _buildNoActivePingtrail(),

                const SizedBox(height: 40),

                // Past Pingtrails Section
                const Text(
                  'Past Pingtrails',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 16),

                // Past Pingtrail Cards
                ...pastPingtrails.map((trail) => _buildPastPingtrailCard(trail)),

                const SizedBox(height: 24),

                // View Full History Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PingtrailsHistoryPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.clockRotateLeft,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View Full History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          FontAwesomeIcons.chevronRight,
                          color: AppTheme.textGray,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
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

  Widget _buildActivePingtrailCard(Map<String, dynamic> trail) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        image: const DecorationImage(
          image: NetworkImage(
            'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/-118.2437,34.0522,9,0/600x400@2x?access_token=pk.eyJ1IjoiZXhhbXBsZSIsImEiOiJjazBiMXNlMGIwMDAwM25wZWk2Y2cwdXplIn0',
          ),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIVE badge and participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Participants avatars
                    Row(
                      children: [
                        ...List.generate(
                          trail["participants"].length.clamp(0, 2),
                          (index) => Padding(
                            padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.cardBackground,
                              backgroundImage: NetworkImage(
                                trail["participants"][index],
                              ),
                            ),
                          ),
                        ),
                        if (trail["additionalCount"] > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.inputBackground,
                              child: Text(
                                '+${trail["additionalCount"]}',
                                style: const TextStyle(
                                  fontSize: 11,
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

                const Spacer(),

                // Trail title
                Text(
                  trail["title"],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 8),

                // Time info
                Row(
                  children: [
                    Text(
                      trail["timeRemaining"],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      trail["duration"],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar and Track button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: trail["progress"],
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Track pingtrail
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(
                          FontAwesomeIcons.pause,
                          color: Colors.white,
                          size: 14,
                        ),
                        label: const Text(
                          'Track',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActivePingtrail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.route,
            size: 40,
            color: AppTheme.textGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No active pingtrail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new pingtrail to get started',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastPingtrailCard(Map<String, dynamic> trail) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        image: const DecorationImage(
          image: NetworkImage(
            'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/-97.7431,30.2672,11,0/600x300@2x?access_token=pk.eyJ1IjoiZXhhbXBsZSIsImEiOiJjazBiMXNlMGIwMDAwM25wZWk2Y2cwdXplIn0',
          ),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COMPLETED badge and participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.circleCheck,
                            color: AppTheme.textGray,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Participants avatars
                    Row(
                      children: List.generate(
                        trail["participants"].length,
                        (index) => Padding(
                          padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.cardBackground,
                            backgroundImage: NetworkImage(
                              trail["participants"][index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Trail title
                Text(
                  trail["title"],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 8),

                // Ended time
                Text(
                  'Ended ${trail["endedTime"]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 20),

                // View Summary Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: View summary
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'View Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
