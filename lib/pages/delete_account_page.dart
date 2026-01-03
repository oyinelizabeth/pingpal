import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pingpal/pages/auth_page.dart';
import 'package:pingpal/services/local_storage_service.dart';

import '../theme/app_theme.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔥 Delete Firestore user data (including subcollections and references)
  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);

    // 1. Delete user subcollections (specifically pingpals)
    final subCollections = ['pingpals'];
    for (final collection in subCollections) {
      final snapshot = await userRef.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // 2. Delete friend requests (as sender OR receiver)
    final sentRequests = await firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: uid)
        .get();
    for (final doc in sentRequests.docs) {
      await doc.reference.delete();
    }

    final receivedRequests = await firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (final doc in receivedRequests.docs) {
      await doc.reference.delete();
    }

    // 3. Delete notifications (as sender OR receiver)
    final sentNotifs = await firestore
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .get();
    for (final doc in sentNotifs.docs) {
      await doc.reference.delete();
    }

    final receivedNotifs = await firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (final doc in receivedNotifs.docs) {
      await doc.reference.delete();
    }

    // 4. Handle Pingtrails
    // Case A: User is the host -> Delete or Cancel the trail
    final hostedTrails = await firestore
        .collection('ping_trails')
        .where('hostId', isEqualTo: uid)
        .get();
    for (final doc in hostedTrails.docs) {
      // For PoC, we'll mark as cancelled so others can see it ended, 
      // or just delete it if we want "all records" gone.
      // Deleting is more aligned with "delete all their records".
      await doc.reference.delete();
    }

    // Case B: User is a participant -> Remove from arrays
    final participatingTrails = await firestore
        .collection('ping_trails')
        .where('members', arrayContains: uid)
        .get();
    for (final doc in participatingTrails.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      final participants = List<dynamic>.from(data['participants'] ?? []);

      members.remove(uid);
      participants.removeWhere((p) => p['userId'] == uid);

      await doc.reference.update({
        'members': members,
        'participants': participants,
      });
    }

    // 5. Delete main user document
    await userRef.delete();

    // 6. Clear Local DB
    await LocalStorageService.clearAll();
  }

  Future<void> _deleteAccount() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        _showError('User not logged in');
        return;
      }

      // 🔐 Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 🧹 Delete Firestore data
      await _deleteUserData(user.uid);

      // ❌ Delete Firebase Auth account
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account and data deleted permanently'),
          backgroundColor: Colors.red,
        ),
      );

      // 🚪 Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Account deletion failed');
    } catch (e) {
      _showError('Something went wrong. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.arrowLeft,
                  color: AppTheme.textWhite,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete your account and all associated data.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textGray.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Delete My Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
