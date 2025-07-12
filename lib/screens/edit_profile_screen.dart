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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      usernameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';
      await _loadUserPhone(user.uid);
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
      // Handle reauthentication if needed
      if (newPasswordController.text.isNotEmpty ||
          emailController.text.trim() != user.email) {
        if (!await _reauthenticate(currentPasswordController.text)) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update profile information
      await user.updateDisplayName(usernameController.text.trim());

      if (emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
      }

      if (newPasswordController.text.isNotEmpty) {
        await user.updatePassword(newPasswordController.text);
      }

      // Handle profile image update
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

      // Update Firestore data
      await _firestoreService.saveUserProfile(user.uid, {
        'phone': phoneController.text.trim(),
      });

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
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  return val.contains('@') ? null : 'Enter valid email';
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                hintText: 'Enter your phone number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
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