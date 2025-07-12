import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  static const routeName = '/edit_profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService(); // instantiate or get via getIt
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  XFile? _imageFile;
  final _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      usernameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';
      // Fetch phone from Firestore if you store it separately
      _loadUserPhone(user.uid);
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reauthentication failed. Please check your current password.')),
      );
      return false;
    }
  }

  Future<Uint8List?> _compressImage(XFile file) async {
    return await FlutterImageCompress.compressWithFile(
      file.path,
      quality: 50, // try 30–60 for good compression
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Reauthenticate if changing sensitive info
      if (newPasswordController.text.isNotEmpty || emailController.text.trim() != user.email) {
        final success = await _reauthenticate(currentPasswordController.text);
        if (!success) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update displayName
      await user.updateDisplayName(usernameController.text.trim());

      // Update email if changed
      if (emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
      }

      // Update password if entered
      if (newPasswordController.text.isNotEmpty) {
        await user.updatePassword(newPasswordController.text);
      }

      // Update photoURL if new image selected
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');

        if (kIsWeb) {
          // For web, upload bytes
          final bytes = await _imageFile!.readAsBytes();
          await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          // For mobile, upload file
          if (kIsWeb) {
            final bytes = await _imageFile!.readAsBytes();
            await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          } else {
            final compressed = await _compressImage(_imageFile!);
            if (compressed != null) {
              await storageRef.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
            } else {
              // fallback
              await storageRef.putFile(File(_imageFile!.path));
            }
          }

        }

        final url = await storageRef.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      await user.reload();

      // Save phone to Firestore
      await _firestoreService.saveUserProfile(user.uid, {
        'phone': phoneController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

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
                  backgroundColor: Colors.grey,
                  backgroundImage: _imageFile != null
                      ? (kIsWeb
                      ? NetworkImage(_imageFile!.path)
                      : FileImage(File(_imageFile!.path)) as ImageProvider)
                      : (user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null),
                  child: (_imageFile == null && (user?.photoURL == null))
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectProfilePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Select Profile Picture'),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Username:',
                hintText: 'Enter your username',
                controller: usernameController,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Email:',
                hintText: 'Enter your email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty || !val.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Phone Number:',
                hintText: 'Enter your phone number',
                controller: phoneController,
              ),
              const SizedBox(height: 16),

              // Current password required if changing email/password
              CustomTextField(
                label: 'Current Password:',
                hintText: 'Enter current password to confirm changes',
                controller: currentPasswordController,
                obscureText: true,
                validator: (val) {
                  if ((newPasswordController.text.isNotEmpty || emailController.text.trim() != (user?.email ?? '')) &&
                      (val == null || val.isEmpty)) {
                    return 'Current password required to change email or password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'New Password:',
                hintText: 'Enter new password',
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
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
