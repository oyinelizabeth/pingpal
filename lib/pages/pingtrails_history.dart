import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'pingtrail_complete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PingtrailsHistoryPage extends StatefulWidget {
  const PingtrailsHistoryPage({super.key});

  @override
  State<PingtrailsHistoryPage> createState() => _PingtrailsHistoryPageState();
}

class _PingtrailsHistoryPageState extends State<PingtrailsHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _navIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, String> _userNameCache = {};

  Future<void> _loadUserNames(List<String> userIds) async {
    final missingIds = userIds.where((id) => !_userNameCache.containsKey(id)).toList();
    if (missingIds.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: missingIds.take(10).toList())
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      _userNameCache[doc.id] = (data['name'] ?? '').toString().toLowerCase();
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return true;

    final trailName = (data['name'] ?? '').toString().toLowerCase();
    final destination =
    (data['destination']?['name'] ?? '').toString().toLowerCase();

    // Basic checks
    if (trailName.contains(query) || destination.contains(query)) {
      return true;
    }

    // Member name check
    final members = List<String>.from(data['members'] ?? []);
    _loadUserNames(members);

    for (final uid in members) {
      final name = _userNameCache[uid];
      if (name != null && name.contains(query)) {
        return true;
      }
    }

    return false;
  }



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      setState(() {});
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  void _openTrailDetailsFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PingtrailCompletePage(
          trailName: data['name'],
          destination: data['destination']?['name'] ?? '',
          duration: data['duration'] ?? '',
          distance: data['distance'] ?? '',
          participants: const [], // we’ll make this dynamic next
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
                    prefixIcon: const Icon(
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('members', arrayContains: currentUserId)
          .where('status', isEqualTo: 'completed')
          .orderBy('endedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          return _matchesSearch(doc.data() as Map<String, dynamic>);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            _searchController.text.isNotEmpty
                ? 'No matching pingtrails'
                : 'No completed pingtrails',
          );
        }


        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: filteredDocs
              .map((doc) => _buildTrailCardFromDoc(doc, true))
              .toList(),
        );
      },
    );
  }


  Widget _buildCancelledTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('members', arrayContains: currentUserId)
          .where('status', isEqualTo: 'cancelled')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          return _matchesSearch(doc.data() as Map<String, dynamic>);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            _searchController.text.isNotEmpty
                ? 'No matching pingtrails'
                : 'No cancelled pingtrails',
          );
        }


        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: filteredDocs
              .map((doc) => _buildTrailCardFromDoc(doc, false))
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildTrailCardFromDoc(QueryDocumentSnapshot doc, bool isCompleted) {
    final data = doc.data() as Map<String, dynamic>;

    final title = data['name'] ?? 'Pingtrail';
    final destination = data['destination']?['name'] ?? 'Unknown destination';
    final members = List<String>.from(data['members'] ?? []);
    final endedAt = data['endedAt'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;

    final date = isCompleted && endedAt != null
        ? _formatDate(endedAt.toDate())
        : createdAt != null
        ? _formatDate(createdAt.toDate())
        : '';

    return GestureDetector(
      onTap: isCompleted
          ? () => _openTrailDetailsFromDoc(doc)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Icon(
                FontAwesomeIcons.route,
                color: AppTheme.textGray.withOpacity(0.4),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
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

                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.locationDot,
                          size: 12,
                          color: isCompleted
                              ? AppTheme.primaryBlue
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            destination,
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

                    HistoryParticipantsRow(memberIds: members),

                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGray.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryParticipantsRow extends StatelessWidget {
  final List<String> memberIds;

  const HistoryParticipantsRow({
    super.key,
    required this.memberIds,
  });

  @override
  Widget build(BuildContext context) {
    if (memberIds.isEmpty) {
      return const SizedBox();
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(
        FieldPath.documentId,
        whereIn: memberIds.take(4).toList(),
      )
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 24);
        }

        final users = snapshot.data!.docs;
        final extraCount = memberIds.length - users.length;

        return Row(
          children: [
            ...users.map((doc) {
              final user = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.cardBackground,
                  backgroundImage: NetworkImage(
                    user['photoUrl'] ?? 'https://i.pravatar.cc/150',
                  ),
                ),
              );
            }),

            if (extraCount > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.inputBackground,
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

