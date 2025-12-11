import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// conversation page between user and a friend
// NEED TO REPLACE TEMPORARY DEMO DATA WITH LIVE DATA FROM BACKEND
class ChatPage extends StatelessWidget {
  final String friendName;

  /// [friendName] is passed from the previous screen (Friends list or Inbox)
  /// to show which friend the user is chatting with.
  const ChatPage({super.key, required this.friendName});

  @override
  Widget build(BuildContext context) {
    /// Temporary demo message list.
    /// Each message contains:
    /// - fromMe : whether the message was sent by the current user
    /// - text   : the message content
    ///
    /// In the final version, "fromMe" will depend on authenticated user ID.
    final messages = [
      {"fromMe": false, "text": "Hey, where are you now?"},
      {"fromMe": true, "text": "On my way, 5 mins away 👣"},
      {"fromMe": false, "text": "Okay, see you soon!"},
    ];

    return Scaffold(
      appBar: AppBar(
        /// Shows the selected friend's name at the top.
        title: Text(friendName),
      ),

      body: Column(
        children: [
          // -------------------- MESSAGES LIST --------------------
          // expanded ensures the chat list takes available vertical space.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["fromMe"] as bool;

                // aligns outgoing messages to the right and incoming to the left.
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,

                  /// chat bubble design
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),

                    decoration: BoxDecoration(
                      // pink for user messages, soft pink for friend messages.
                      color: isMe
                          ? AppTheme.primaryPink
                          : AppTheme.softPink.withOpacity(0.6),

                      // Rounded corners, with tail depending on who sent it.
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),

                    // Message text
                    child: Text(
                      msg["text"] as String,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // -------------------- MESSAGE INPUT --------------------
          /// The bottom text field where the user types new messages.
          /// SafeArea ensures the input is not covered by device notches.
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  /// Text entry box
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// Send button (currently not wired to backend logic)
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryPink,
                    child: Icon(Icons.send, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
