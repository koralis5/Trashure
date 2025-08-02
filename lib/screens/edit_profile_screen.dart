import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_service.dart';
import '../services/firebase_service.dart';
import 'package:get_it/get_it.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit_profile';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final _firebaseService = GetIt.instance<FirebaseService>();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  XFile? _imageFile;
  bool _isLoading = false;
  String? _currentImageBase64;

  // To track if user signed in via email/password
  bool canChangeEmailPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && mounted) {
        // Load from Firebase Auth
        emailController.text = user.email ?? '';

        // Detect sign-in method(s)
        final providers = user.providerData.map((p) => p.providerId).toList();
        canChangeEmailPassword = providers.contains('password');

        // Load from Firestore
        final firestoreProfile = await _firestoreService.getUserProfile(user.uid);
        if (firestoreProfile != null && mounted) {
          usernameController.text = firestoreProfile['displayName'] ?? user.displayName ?? '';
          phoneController.text = firestoreProfile['phone'] ?? '';
          _currentImageBase64 = firestoreProfile['profileImageBase64'];
        }

        setState(() {}); // Refresh UI with updated state
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePicture() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null && mounted) {
                    setState(() => _imageFile = pickedFile);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error taking photo: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && mounted) {
                    setState(() => _imageFile = pickedFile);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error selecting image: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            if (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _currentImageBase64 = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
      }
      return false;
    }
  }

  Future<Uint8List?> _compressImage(XFile file) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        quality: 70,
        minWidth: 600,
        minHeight: 600,
      );
    } catch (e) {
      return null;
    }
  }

  String? _getSafeImageUrl(String? url) {
    // This method is no longer needed with base64 approach
    // Keeping for potential backward compatibility
    return url;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Reauthenticate only if changing password or email, and allowed
      if (canChangeEmailPassword &&
          (newPasswordController.text.isNotEmpty ||
              emailController.text.trim() != user.email)) {
        if (!await _reauthenticate(currentPasswordController.text)) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update display name (allowed for all)
      if (usernameController.text.trim() != user.displayName) {
        await user.updateDisplayName(usernameController.text.trim());
      }

      // Handle email change
      if (canChangeEmailPassword && emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification email sent to the new address. '
                    'Please verify to complete the email change. You will be signed out now.',
              ),
            ),
          );
        }

        await _auth.signOut();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }

        return; // Stop here since user is signed out
      }

      // Update password
      if (canChangeEmailPassword && newPasswordController.text.isNotEmpty) {
        await user.updatePassword(newPasswordController.text);
      }

      // Handle profile picture
      String? newImageBase64 = _currentImageBase64;
      if (_imageFile != null) {
        // Convert new image to base64
        newImageBase64 = await _firestoreService.convertImageToBase64(_imageFile!);
      } else if (_currentImageBase64 == null) {
        // Remove profile picture
        newImageBase64 = null;
      }

      // Update Firestore with profile data including image
      await _firestoreService.updateUserProfile(
        uid: user.uid,
        displayName: usernameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        profileImageBase64: newImageBase64,
      );

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileImage() {
    if (_imageFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: kIsWeb
            ? NetworkImage(_imageFile!.path)
            : FileImage(File(_imageFile!.path)) as ImageProvider,
      );
    }

    if (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_currentImageBase64!);
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey[200],
      child: const Icon(Icons.person, size: 50, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FDF6),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _selectProfilePicture,
                child: Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _selectProfilePicture,
                child: const Text('Change Profile Picture'),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Username',
                hintText: 'Enter your username',
                controller: usernameController,
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Email field, disabled if cannot change
              CustomTextField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: canChangeEmailPassword,
                validator: (val) {
                  if (!canChangeEmailPassword) return null;
                  if (val == null || val.isEmpty) return 'Required';
                  return val.contains('@') ? null : 'Enter valid email';
                },
              ),
              if (!canChangeEmailPassword)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Email cannot be changed for this sign-in method',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),

              // Phone number allowed for all
              CustomTextField(
                label: 'Phone Number',
                hintText: 'Enter your phone number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Current password required only if allowed and changing password/email
              if (canChangeEmailPassword) ...[
                CustomTextField(
                  label: 'Current Password',
                  hintText: 'Required for changes',
                  controller: currentPasswordController,
                  obscureText: true,
                  validator: (val) {
                    final user = _auth.currentUser;
                    final needsValidation = newPasswordController.text.isNotEmpty ||
                        emailController.text.trim() != (user?.email ?? '');
                    if (needsValidation && (val == null || val.isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'New Password',
                  hintText: 'Leave blank to keep current',
                  controller: newPasswordController,
                  obscureText: true,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Password cannot be changed for this sign-in method',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}