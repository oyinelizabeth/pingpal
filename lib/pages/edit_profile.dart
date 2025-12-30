import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _pingpalIdController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  bool _ghostModeEnabled = false;
  bool _publicVisibilityEnabled = true;
  bool _loading = false;

  File? _image;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pingpalIdController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // 🔹 LOAD PROFILE FROM FIREBASE
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _displayNameController.text = data['fullName'] ?? '';
      _pingpalIdController.text = data['pingpalId'] ?? '';
      _statusController.text = data['status'] ?? '';
      _ghostModeEnabled = data['ghostMode'] ?? false;
      _publicVisibilityEnabled = data['publicVisibility'] ?? true;
      _photoUrl = data['photoUrl'] ?? user.photoURL;
      setState(() {});
    }
  }

  // 🔹 PICK IMAGE
  Future<void> pickImage(String type) async {
    final picked = await ImagePicker().pickImage(
      source: type == "gallery" ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // 🔹 UPLOAD IMAGE TO FIREBASE STORAGE
  Future<String?> _uploadProfileImage(File image) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // 🔹 SAVE PROFILE
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      String? imageUrl = _photoUrl;

      if (_image != null) {
        imageUrl = await _uploadProfileImage(_image!);
        await user.updatePhotoURL(imageUrl);
      }

      await user.updateDisplayName(
        _displayNameController.text.trim(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "fullName": _displayNameController.text.trim(),
        "pingpalId": _pingpalIdController.text.trim(),
        "status": _statusController.text.trim(),
        "photoUrl": imageUrl,
        "ghostMode": _ghostModeEnabled,
        "publicVisibility": _publicVisibilityEnabled,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 CHANGE PHOTO SHEET
  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: _iconBox(FontAwesomeIcons.camera),
                title: _sheetText('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage("camera");
                },
              ),
              ListTile(
                leading: _iconBox(FontAwesomeIcons.image),
                title: _sheetText('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage("gallery");
                },
              ),
              ListTile(
                leading: _iconBox(FontAwesomeIcons.trash, red: true),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final user = _auth.currentUser;
                  if (user != null) {
                    await user.updatePhotoURL(null);
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .update({"photoUrl": null});
                    setState(() {
                      _photoUrl = null;
                      _image = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, {bool red = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: red
            ? Colors.red.withOpacity(0.2)
            : AppTheme.primaryBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: red ? Colors.red : AppTheme.primaryBlue,
        size: 20,
      ),
    );
  }

  Widget _sheetText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textWhite,
        fontWeight: FontWeight.w500,
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
            // HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _saveProfile,
                    child: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (_photoUrl != null
                                ? NetworkImage(_photoUrl!)
                                : null) as ImageProvider?,
                            child: _image == null && _photoUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.accentBlue,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.darkBackground,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.camera,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Display Name
                    const Text(
                      'Display Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _displayNameController,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pingpal ID
                    const Text(
                      'Pingpal ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pingpalIdController,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        prefixText: '@ ',
                        prefixStyle: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is your unique handle for ping requests.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Status
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _statusController,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                      ),
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Privacy Section
                    const Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textWhite,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ghost Mode
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.userSecret,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ghost Mode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hide location from everyone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textGray.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _ghostModeEnabled,
                            onChanged: (val) {
                              setState(() => _ghostModeEnabled = val);
                            },
                            thumbColor: MaterialStateProperty.resolveWith<Color?>(
                                  (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppTheme.primaryBlue;
                                }
                                return null;
                              },
                            ),

                            activeTrackColor:
                            AppTheme.primaryBlue.withOpacity(0.5),
                            inactiveThumbColor: AppTheme.textGray,
                            inactiveTrackColor:
                            AppTheme.textGray.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Public Visibility
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.globe,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Public Visibility',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Allow non-friends to find you',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textGray.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _publicVisibilityEnabled,
                            onChanged: (val) {
                              setState(() => _publicVisibilityEnabled = val);
                            },
                            thumbColor: MaterialStateProperty.resolveWith<Color?>(
                                  (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppTheme.primaryBlue;
                                }
                                return null;
                              },
                            ),

                            activeTrackColor:
                            AppTheme.primaryBlue.withOpacity(0.5),
                            inactiveThumbColor: AppTheme.textGray,
                            inactiveTrackColor:
                            AppTheme.textGray.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update Phone Number
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to phone number update
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Update Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            Icon(
                              FontAwesomeIcons.chevronRight,
                              color: AppTheme.textGray.withOpacity(0.5),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Linked Accounts
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to linked accounts
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Linked Accounts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            Icon(
                              FontAwesomeIcons.chevronRight,
                              color: AppTheme.textGray.withOpacity(0.5),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
