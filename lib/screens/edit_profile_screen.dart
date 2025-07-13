import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit_profile';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  XFile? _imageFile;
  bool _isLoading = false;

  // To track if user signed in via email/password
  bool canChangeEmailPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && mounted) {
        usernameController.text = user.displayName ?? '';
        emailController.text = user.email ?? '';

        // Detect sign-in method(s)
        final providers = user.providerData.map((p) => p.providerId).toList();

        // Enable email/password edit only if signed in via 'password' provider
        canChangeEmailPassword = providers.contains('password');

        await _loadUserPhone(user.uid);

        setState(() {}); // Refresh UI with updated state
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadUserPhone(String uid) async {
    final profile = await _firestoreService.getUserProfile(uid);
    if (profile != null && mounted) {
      phoneController.text = profile['phone'] ?? '';
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
    if (url == null) return null;
    if (url.contains('googleusercontent.com')) {
      return url.replaceAll('s96-c', 's400-c');
    }
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
      await user.updateDisplayName(usernameController.text.trim());

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

      if (canChangeEmailPassword && newPasswordController.text.isNotEmpty) {
        await user.updatePassword(newPasswordController.text);
      }

      // Update profile picture
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');

        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final compressed = await _compressImage(_imageFile!);
          await storageRef.putData(
            compressed ?? await _imageFile!.readAsBytes(),
            SettableMetadata(contentType: 'image/jpeg'),
          );
        }

        final url = await storageRef.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      // Update Firestore with phone (allowed for all)
      await _firestoreService.saveUserProfile(user.uid, {
        'phone': phoneController.text.trim(),
      });

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

  Widget _buildProfileImage(String? currentPhotoUrl) {
    if (_imageFile != null) {
      return kIsWeb
          ? Image.network(_imageFile!.path, fit: BoxFit.cover)
          : Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    }

    if (currentPhotoUrl != null) {
      return CachedNetworkImage(
        imageUrl: _getSafeImageUrl(currentPhotoUrl) ?? '',
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => _buildDefaultIcon(),
      );
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return const Icon(Icons.person, size: 50, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final currentPhotoUrl = user?.photoURL;

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
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: _buildProfileImage(currentPhotoUrl),
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
              if (canChangeEmailPassword)
                CustomTextField(
                  label: 'Current Password',
                  hintText: 'Required for changes',
                  controller: currentPasswordController,
                  obscureText: true,
                  validator: (val) {
                    final needsValidation = newPasswordController.text.isNotEmpty ||
                        emailController.text.trim() != (user?.email ?? '');
                    if (needsValidation && (val == null || val.isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              if (canChangeEmailPassword) const SizedBox(height: 16),
              // New password allowed only if allowed
              if (canChangeEmailPassword)
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
              if (canChangeEmailPassword) const SizedBox(height: 24),
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
