import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final int _navIndex = 0;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return true;

    final name = (data['name'] ?? '').toString().toLowerCase();
    final destination =
    (data['destinationName'] ?? '').toString().toLowerCase();

    return name.contains(query) || destination.contains(query);
  }

  void _openCompletedTrail(QueryDocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PingtrailCompletePage(
          trailId: doc.id,
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
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTabs(),
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
    );
  }

  /// Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowLeft,
                color: AppTheme.textWhite),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: const InputDecoration(
            hintText: 'Search pingtrails',
            prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass,
                size: 16, color: AppTheme.primaryBlue),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textGray,
        tabs: const [
          Tab(text: 'Completed'),
          Tab(text: 'Cancelled'),
        ],
      ),
    );
  }

  /// Completed
  Widget _buildCompletedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('members', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'active';
          return status == 'completed' && _matchesSearch(data);
        }).toList();

        if (docs.isEmpty) {
          return _emptyState('No completed pingtrails');
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: docs
              .map((doc) => _buildTrailCard(doc, true))
              .toList(),
        );
      },
    );
  }

  /// Cancelled or left pingtrail
  Widget _buildCancelledTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pingtrails')
          .where('members', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];
          final participants = data['participants'] as List<dynamic>? ?? [];

          final myParticipant = participants.firstWhere(
            (p) => p['userId'] == currentUserId,
            orElse: () => null,
          );
          final myStatus = myParticipant != null ? myParticipant['status'] : '';

          final bool cancelled = status == 'cancelled';
          final bool userLeft = myStatus == 'left' || myStatus == 'rejected';

          return (cancelled || userLeft) && _matchesSearch(data);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _emptyState('No cancelled pingtrails');
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: filteredDocs
              .map((doc) => _buildTrailCard(doc, false))
              .toList(),
        );
      },
    );
  }

  /// Card
  Widget _buildTrailCard(QueryDocumentSnapshot doc, bool completed) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = data['participants'] as List<dynamic>? ?? [];
    final myParticipant = participants.firstWhere(
      (p) => p['userId'] == currentUserId,
      orElse: () => null,
    );
    final bool userLeft = myParticipant != null && (myParticipant['status'] == 'left' || myParticipant['status'] == 'rejected');

    return GestureDetector(
      onTap: () => _openCompletedTrail(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'Pingtrail',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data['destinationName'] ?? '',
              style: const TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  completed
                      ? FontAwesomeIcons.circleCheck
                      : FontAwesomeIcons.circleXmark,
                  size: 14,
                  color: completed
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  completed
                      ? 'Completed'
                      : userLeft
                      ? 'You left this pingtrail'
                      : 'Cancelled',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: completed
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textGray),
      ),
    );
  }
}
