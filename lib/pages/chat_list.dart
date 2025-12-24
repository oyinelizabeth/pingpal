import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';
import 'chats.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  int _navIndex = 3; // Chat is at index 3

  // Sample active trail chat
  final Map<String, dynamic>? activeTrail = {
    "trailName": "Friday Night Out",
    "destination": "Downtown Coffee",
    "participants": [
      "https://i.pravatar.cc/150?img=1",
      "https://i.pravatar.cc/150?img=2",
      "https://i.pravatar.cc/150?img=3",
    ],
    "additionalCount": 2,
    "lastMessage": "On my way! 🚗",
    "lastMessageTime": "2m ago",
    "unreadCount": 3,
    "isActive": true,
  };

  // Sample chat history
  final List<Map<String, dynamic>> chatHistory = [
    {
      "trailName": "Roadtrip to Vegas",
      "destination": "Las Vegas Strip",
      "participants": [
        "https://i.pravatar.cc/150?img=4",
        "https://i.pravatar.cc/150?img=5",
      ],
      "additionalCount": 1,
      "lastMessage": "That was amazing! 🎉",
      "lastMessageTime": "Oct 12",
      "unreadCount": 0,
      "isActive": false,
    },
    {
      "trailName": "Morning Hike",
      "destination": "Blue Ridge Trail",
      "participants": [
        "https://i.pravatar.cc/150?img=6",
        "https://i.pravatar.cc/150?img=7",
        "https://i.pravatar.cc/150?img=8",
      ],
      "additionalCount": 0,
      "lastMessage": "Great trail! Thanks for inviting",
      "lastMessageTime": "Nov 14",
      "unreadCount": 0,
      "isActive": false,
    },
    {
      "trailName": "Beach Day",
      "destination": "Santa Monica",
      "participants": [
        "https://i.pravatar.cc/150?img=9",
        "https://i.pravatar.cc/150?img=10",
      ],
      "additionalCount": 3,
      "lastMessage": "See you next time!",
      "lastMessageTime": "Last week",
      "unreadCount": 0,
      "isActive": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.circlePlus,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: Start new group chat
                    },
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
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(
                      color: AppTheme.textGray.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppTheme.textGray.withOpacity(0.6),
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

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: activeTrail != null
                  ? _buildChatList()
                  : _buildEmptyState(),
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

  Widget _buildChatList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Trail Section
          if (activeTrail != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'ACTIVE TRAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildChatCard(activeTrail!, isActive: true),
            const SizedBox(height: 24),
          ],

          // Recent Chats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'RECENT CHATS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...chatHistory.map((chat) => _buildChatCard(chat)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(friendName: chat["trailName"]),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Participants Stack
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  ...List.generate(
                    chat["participants"].length.clamp(0, 3),
                    (index) {
                      final positions = [
                        const Offset(0, 0),
                        const Offset(20, 0),
                        const Offset(10, 20),
                      ];
                      return Positioned(
                        left: positions[index].dx,
                        top: positions[index].dy,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primaryBlue.withOpacity(0.3)
                                  : AppTheme.darkBackground,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(
                              chat["participants"][index],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (chat["additionalCount"] > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : AppTheme.cardBackground,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+${chat["additionalCount"]}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat["trailName"],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                FontAwesomeIcons.circle,
                                color: Colors.green,
                                size: 6,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.locationDot,
                        size: 10,
                        color: isActive
                            ? AppTheme.primaryBlue
                            : AppTheme.textGray.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat["destination"],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chat["lastMessage"],
                    style: TextStyle(
                      fontSize: 14,
                      color: chat["unreadCount"] > 0
                          ? AppTheme.textWhite
                          : AppTheme.textGray.withOpacity(0.8),
                      fontWeight: chat["unreadCount"] > 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Time and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat["lastMessageTime"],
                  style: TextStyle(
                    fontSize: 12,
                    color: chat["unreadCount"] > 0
                        ? AppTheme.primaryBlue
                        : AppTheme.textGray.withOpacity(0.6),
                    fontWeight: chat["unreadCount"] > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (chat["unreadCount"] > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chat["unreadCount"].toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor, width: 2),
            ),
            child: Icon(
              FontAwesomeIcons.comments,
              size: 48,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start a pingtrail to chat with your friends in real-time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textGray.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to create pingtrail
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(
                FontAwesomeIcons.plus,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Start Pingtrail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
