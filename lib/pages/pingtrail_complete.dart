import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class PingtrailCompletePage extends StatefulWidget {
  final String trailName;
  final String destination;
  final String duration;
  final String distance;
  final List<Map<String, dynamic>> participants;

  const PingtrailCompletePage({
    super.key,
    required this.trailName,
    required this.destination,
    required this.duration,
    required this.distance,
    required this.participants,
  });

  @override
  State<PingtrailCompletePage> createState() => _PingtrailCompletePageState();
}

class _PingtrailCompletePageState extends State<PingtrailCompletePage>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get arrivedCount =>
      widget.participants.where((p) => p["arrived"]).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Completion Icon with Animation
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        width: 3,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.2),
                          AppTheme.darkBackground,
                        ],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.flag,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.darkBackground,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              FontAwesomeIcons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Pingtrail Complete Header
                const Text(
                  'PINGTRAIL COMPLETE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                // Trail Name
                Text(
                  widget.trailName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Destination
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.locationDot,
                        color: AppTheme.textGray.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.destination,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'DURATION',
                        value: widget.duration,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'DISTANCE',
                        value: widget.distance,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Arrival Times Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Arrival Times',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      '$arrivedCount of ${widget.participants.length} arrived',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Participants List
                ...widget.participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  final isLast = index == widget.participants.length - 1;
                  return _buildParticipantItem(participant, isLast);
                }),

                const SizedBox(height: 32),

                // Close Summary Button
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
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
                      FontAwesomeIcons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Close Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(
      Map<String, dynamic> participant, bool isLast) {
    final bool isHost = participant["isHost"] ?? false;
    final bool arrived = participant["arrived"] ?? false;
    final String timeDiff = participant["timeDiff"] ?? "";

    return Column(
      children: [
        Row(
          children: [
            // Avatar with border for host
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isHost
                        ? Border.all(
                            color: AppTheme.primaryBlue,
                            width: 3,
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: isHost ? 27 : 28,
                    backgroundImage: NetworkImage(participant["avatar"]),
                  ),
                ),
                if (isHost)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.darkBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.crown,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Name and Host Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant["name"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  if (isHost) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Host',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrival Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  participant["arrivalTime"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                if (timeDiff.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeDiff,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        // Connecting Line (except for last item)
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 28, top: 8, bottom: 8),
            height: 40,
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.borderColor,
                  AppTheme.borderColor.withOpacity(0.3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
