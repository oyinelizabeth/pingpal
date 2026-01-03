import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// conversation page between user and a friend
// NEED TO REPLACE TEMPORARY DEMO DATA WITH LIVE DATA FROM BACKEND
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/chat_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final String trailId;
  final String trailName;
  final bool isActive;

  const ChatPage({
    super.key,
    required this.trailId,
    required this.trailName,
    required this.isActive,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadLocalMessages();
    if (widget.isActive) {
      _startAdaptivePolling();
    } else {
      _fetchArchivedMessages();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalMessages() async {
    final localMsgs = await LocalStorageService.getMessagesForTrail(widget.trailId);
    if (mounted) {
      setState(() {
        _messages = List.from(localMsgs);
      });
      _scrollToBottom();
    }
  }

  void _startAdaptivePolling() async {
    // Initial fetch
    await _syncMessages();

    _scheduleNextPoll();
  }

  void _scheduleNextPoll() async {
    _pollingTimer?.cancel();
    if (!mounted || !widget.isActive) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    int interval = 5; // Default 5 seconds (mobile data)

    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      interval = 1; // 1 second (Wi-Fi)
    }

    debugPrint('Adaptive Polling: interval $interval s (Mobile Cloud Optimization)');

    _pollingTimer = Timer(Duration(seconds: interval), () async {
      await _syncMessages();
      _scheduleNextPoll();
    });
  }

  Future<void> _syncMessages() async {
    try {
      final remoteMsgs = await ChatService.fetchActiveMessages(widget.trailId);
      
      bool hasNew = false;
      for (var msg in remoteMsgs) {
        // Prepare for local storage
        final localMsg = {
          'id': msg['id'],
          'trailId': widget.trailId,
          'userId': msg['userId'],
          'text': msg['text'],
          'timestamp': msg['timestamp'],
          'isSentByMe': msg['userId'] == _currentUserId ? 1 : 0,
        };

        // This handles duplicates internally via ConflictAlgorithm.ignore
        await LocalStorageService.saveMessage(localMsg);
        hasNew = true;
      }

      if (hasNew) {
        _loadLocalMessages();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retrying connection...'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _fetchArchivedMessages() async {
    try {
      final archived = await ChatService.fetchArchivedMessages(widget.trailId);
      for (var msg in archived) {
        await LocalStorageService.saveMessage({
          'id': msg['id'],
          'trailId': widget.trailId,
          'userId': msg['userId'],
          'text': msg['text'],
          'timestamp': msg['timestamp'],
          'isSentByMe': msg['userId'] == _currentUserId ? 1 : 0,
        });
      }
      _loadLocalMessages();
    } catch (e) {
      debugPrint('Archive fetch error: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ChatService.sendMessage(
        trailId: widget.trailId,
        userId: _currentUserId,
        message: text,
      );
      // Immediate sync
      await _syncMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _leaveTrail() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Leave Trail?', style: TextStyle(color: Colors.white)),
        content: const Text('You will no longer receive updates.', style: TextStyle(color: AppTheme.textGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final docRef = FirebaseFirestore.instance.collection('pingtrails').doc(widget.trailId);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data()!;
          final participants = List.from(data['participants'] ?? []);
          final hostId = (data['hostId'] ?? '').toString();

          for (var p in participants) {
            if (p['userId'] == _currentUserId) {
              p['status'] = 'left';
              break;
            }
          }
          await docRef.update({'participants': participants});

          if (hostId.isNotEmpty) {
            await NotificationService.send(
              receiverId: hostId,
              senderId: _currentUserId,
              title: 'Pingtrail update',
              body: 'A member left the pingtrail',
              type: 'pingtrail_left',
              pingtrailId: widget.trailId,
            );
          }

          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trailName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.isActive)
              const Text('Active Trail', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        actions: [
          if (widget.isActive)
            IconButton(
              icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 18),
              onPressed: _leaveTrail,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isSentByMe'] == 1;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryBlue : AppTheme.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(color: isMe ? Colors.white : AppTheme.textWhite),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(msg['timestamp'] as int),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.isActive)
            _buildMessageInput()
          else
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.cardBackground,
              width: double.infinity,
              child: const Text(
                'This chat is archived and read-only.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGray),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: AppTheme.textGray.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppTheme.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: const CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.send, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
