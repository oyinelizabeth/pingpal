import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendsPage extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  const FriendsPage({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Friends"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.softPink, width: 1.7),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
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
                        color: friend["online"] ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // later: open chat with this friend
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppTheme.primaryPink),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
