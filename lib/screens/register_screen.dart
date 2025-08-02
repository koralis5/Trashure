import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashure/models/colours.dart';
import 'package:trashure/widgets/custom_text_field.dart';
import 'package:trashure/services/firebase_service.dart';
import 'package:get_it/get_it.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final fbService = GetIt.I<FirebaseService>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

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
                final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() => _imageFile = pickedFile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() => _imageFile = pickedFile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String username = usernameController.text.trim();
    final String phone = phoneController.text.trim();

    if (password != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Register user
      final userCredential = await fbService.register(email, password);
      final user = userCredential.user!;

      // Update display name in Firebase Auth
      await user.updateDisplayName(username);

      // Handle profile picture upload if selected
      String? profileImageBase64;
      if (_imageFile != null) {
        profileImageBase64 = await fbService.firestoreService.convertImageToBase64(_imageFile!);
      }

      // Update Firestore profile with complete information
      await fbService.firestoreService.updateUserProfile(
        uid: user.uid,
        displayName: username,
        phoneNumber: phone.isNotEmpty ? phone : null,
        profileImageBase64: profileImageBase64,
      );

      // Send email verification
      await fbService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Verification email sent. Please verify your email.')),
        );

        Navigator.pushReplacementNamed(context, '/email_verification');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(e.code))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password too weak.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Registration failed.';
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _imageFile != null
                        ? (kIsWeb
                        ? NetworkImage(_imageFile!.path)
                        : FileImage(File(_imageFile!.path)) as ImageProvider)
                        : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person, size: 64, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _selectProfilePicture,
                    child: const Text('Select Profile Picture'),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Username',
                    hintText: 'John Doe',
                    controller: usernameController,
                    enabled: !_isLoading,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Email',
                    hintText: 'johndoe@gmail.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (!val.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Phone Number',
                    hintText: '98761234',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isLoading,
                    // Note: Made phone optional for registration
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Password',
                    hintText: '********',
                    controller: passwordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Confirm Password',
                    hintText: '********',
                    controller: confirmPasswordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    validator: (val) =>
                    val != passwordController.text ? 'Passwords don\'t match' : null,
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _isLoading ? null : () => register(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}