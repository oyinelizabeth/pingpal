import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'chats.dart';
import 'pingtrail.dart';
import 'pingpals.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  final int _navIndex = 3; 
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGray,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrailList(isActive: true),
          _buildTrailList(isActive: false),
        ],
      ),
    );
  }

  Widget _buildTrailList({required bool isActive}) {
    // We want to fetch all trails the user is part of, then filter in memory
    // because Firestore whereIn/array-contains-any has limits and we have complex logic.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pingtrails').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final trails = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List participants = data['participants'] ?? [];
          final String status = data['status'] ?? 'active';

          final myParticipant = participants.firstWhere(
            (p) => p['userId'] == _currentUserId,
            orElse: () => null,
          );

          if (myParticipant == null) return false;

          final myStatus = myParticipant['status'] ?? '';

          if (isActive) {
            // Active: Trail status is active AND I haven't left/rejected
            return status == 'active' && myStatus == 'accepted';
          } else {
            // Archived: Trail is completed/cancelled OR I have left/rejected
            return status == 'completed' || status == 'cancelled' || myStatus == 'left' || myStatus == 'rejected';
          }
        }).toList();

        if (trails.isEmpty) {
          return _buildEmptyState(isActive);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trails.length,
          itemBuilder: (context, index) {
            final doc = trails[index];
            final data = doc.data() as Map<String, dynamic>;
            // In Archived view, isActive should be false for the ChatPage
            return _buildChatCard(doc.id, data, isActive: isActive);
          },
        );
      },
    );
  }

  Widget _buildChatCard(String trailId, Map<String, dynamic> data, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              trailId: trailId,
              trailName: data['name'] ?? 'Pingtrail',
              isActive: isActive,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(FontAwesomeIcons.route, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Pingtrail',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['destinationName'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(FontAwesomeIcons.chevronRight, color: AppTheme.textGray, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? FontAwesomeIcons.comments : FontAwesomeIcons.boxArchive,
            size: 64,
            color: AppTheme.textGray.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'No active chats' : 'No archived chats',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
