import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pingpal/pages/auth_page.dart';
import 'package:pingpal/services/local_storage_service.dart';

import '../theme/app_theme.dart';

// Page allowing a user to permanently delete their account and all related data
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  // Controller for confirming the user's password before deletion
  final TextEditingController _passwordController = TextEditingController();

  // Controls loading state while deletion is in progress
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // Deletes all Firestore data associated with the user - This ensures no orphaned data remains after account deletion
  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);

    //  Delete user subcollections (e.g. pingpals)
    final subCollections = ['pingpals'];
    for (final collection in subCollections) {
      final snapshot = await userRef.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // Delete friend requests where the user is sender or receiver
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

    // Delete notifications involving the user
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

    // Handle Pingtrails
    // User is host and deletes their hosted trails
    final hostedTrails = await firestore
        .collection('ping_trails')
        .where('hostId', isEqualTo: uid)
        .get();
    for (final doc in hostedTrails.docs) {
      await doc.reference.delete();
    }

    // User is participant and wants to be removed from pingtrails
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

    // Delete the main user document
    await userRef.delete();

    // Clear locally cached data
    await LocalStorageService.clearAll();
  }

  // Handles full account deletion flow: re-authentication → data deletion → auth account removal
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

      // Re-authenticate user before sensitive action
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete all Firestore data
      await _deleteUserData(user.uid);

      // Delete Firebase Authentication account
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account and data deleted permanently'),
          backgroundColor: Colors.red,
        ),
      );

      // Redirect to authentication screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Account deletion failed');
    } catch (_) {
      _showError('Something went wrong. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Displays an error message using a SnackBar
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
              // Back navigation
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.arrowLeft,
                  color: AppTheme.textWhite,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 20),

              // Page title
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 12),

              // Warning message
              Text(
                'This will permanently delete your account and all associated data.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textGray.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 32),

              // Password confirmation
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

              // Delete button
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
