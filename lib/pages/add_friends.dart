import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController emailController = TextEditingController();

  Map<String, dynamic>? foundUser;
  bool isLoading = false;
  bool isSending = false;
  bool requestSent = false;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // 🔍 SEARCH USER BY EMAIL
  Future<void> searchUser() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showMessage('Please enter an email');
      return;
    }

    setState(() {
      isLoading = true;
      foundUser = null;
      requestSent = false;
    });

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      _showMessage('User not found');
    } else {
      final doc = query.docs.first;

      if (doc.id == currentUserId) {
        _showMessage('You cannot add yourself');
      } else {
        setState(() {
          foundUser = {
            'uid': doc.id,
            ...doc.data(),
          };
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // 🚫 CHECK FOR DUPLICATE REQUESTS
  Future<bool> _requestAlreadyExists(String receiverId) async {
    final firestore = FirebaseFirestore.instance;

    final outgoing = await firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    final incoming = await firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    return outgoing.docs.isNotEmpty || incoming.docs.isNotEmpty;
  }

  // 📤 SEND FRIEND REQUEST
  Future<void> sendFriendRequest() async {
    if (foundUser == null || isSending || requestSent) return;

    setState(() {
      isSending = true;
    });

    final receiverId = foundUser!['uid'];

    // Prevent duplicate requests
    final exists = await _requestAlreadyExists(receiverId);
    if (exists) {
      _showMessage('A request already exists');
      setState(() => isSending = false);
      return;
    }

    // Get sender info
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final senderData = senderDoc.data()!;

    await FirebaseFirestore.instance.collection('friend_requests').add({
      'senderId': currentUserId,
      'senderName': senderData['fullName'],
      'senderEmail': senderData['email'],
      'senderPhoto': senderData['photoUrl'] ?? '',
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showMessage('Friend request sent');

    setState(() {
      requestSent = true;
      isSending = false;
      emailController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Pingpal',
          style: TextStyle(color: AppTheme.textWhite),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search by email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'example@email.com',
                hintStyle: TextStyle(
                  color: AppTheme.textGray.withOpacity(0.6),
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (foundUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                      AppTheme.primaryBlue.withOpacity(0.15),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foundUser!['fullName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            foundUser!['email'],
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              AppTheme.textGray.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                      (isSending || requestSent) ? null : sendFriendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        requestSent ? 'Sent' : 'Send',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
