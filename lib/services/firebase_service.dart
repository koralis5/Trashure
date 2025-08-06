import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Client ID is no longer needed for mobile platforms (Android/iOS)
    // For web, you need to configure through Firebase or Google Cloud Console
    scopes: ['email'],
  );

  // Register with email and password
  Future<UserCredential> register(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create initial Firestore profile
    if (userCredential.user != null) {
      await _firestoreService.createUserProfile(
        uid: userCredential.user!.uid,
        email: email,
        displayName: userCredential.user!.displayName ?? '',
      );
    }

    return userCredential;
  }

  // Login with email and password
  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Google Sign-In with Firestore integration
  Future<UserCredential> googleSignIn() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google sign-in aborted by user');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // Handle Firestore profile for Google sign-in
      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if user profile exists in Firestore
        final existingProfile = await _firestoreService.getUserProfile(user.uid);

        if (existingProfile == null) {
          // Create new profile for Google user
          String? base64Image;
          if (user.photoURL != null) {
            base64Image = await _downloadImageAsBase64(user.photoURL!);
          }

          await _firestoreService.createUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            profileImageBase64: base64Image,
          );
        } else {
          // Update existing profile with latest Google info
          await _firestoreService.updateUserProfile(
            uid: user.uid,
            displayName: user.displayName,
          );
        }

        // Handle profile image storage
        if (user.photoURL != null && !user.photoURL!.contains('firebase')) {
          await _storeProfileImage(user);
        }
      }

      return userCredential;
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  // Helper method to download image from URL and convert to base64
  Future<String?> _downloadImageAsBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('Error downloading image as base64: $e');
      return null;
    }
  }

  // Helper method to store profile image from URL (legacy - not used with base64)
  Future<void> _storeProfileImage(User user) async {
    // This method is no longer needed with base64 approach
    // Keeping for backward compatibility
  }

  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // Logout with Firestore cleanup if needed
  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> getAuthUser() {
    return _auth.authStateChanges();
  }

  // Upload profile image and store as base64 in Firestore
  Future<String?> uploadProfileImageAsBase64(String uid, XFile imageFile) async {
    try {
      final base64String = await _firestoreService.convertImageToBase64(imageFile);
      if (base64String != null) {
        await _firestoreService.updateUserProfile(
          uid: uid,
          profileImageBase64: base64String,
        );
        print('Profile image uploaded as base64 for uid: $uid');
        return base64String;
      }
      return null;
    } catch (e) {
      print('Error uploading profile image as base64: $e');
      return null;
    }
  }

  // Remove profile image from Firestore
  Future<void> removeProfileImage(String uid) async {
    try {
      await _firestoreService.removeUserProfileImage(uid);
      print('Profile image removed for uid: $uid');
    } catch (e) {
      print('Error removing profile image: $e');
    }
  }

  // Get profile image URL from Firebase Storage
  Future<String?> getProfileImageUrl(String uid) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting profile image URL: $e');
      return null;
    }
  }

  // Delete profile image (legacy - keeping for backward compatibility)
  Future<void> deleteProfileImage(String uid) async {
    try {
      await removeProfileImage(uid);
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }

  // =====================
  // PHONE AUTHENTICATION
  // =====================

  // Send verification code
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) onError,
    required Function(User user) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            // Create/update Firestore profile for phone user
            await _handlePhoneUserProfile(userCredential.user!, phoneNumber);
            onAutoVerified(userCredential.user!);
          }
        } catch (e) {
          print('Auto sign-in failed: $e');
        }
      },
      verificationFailed: onError,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Optionally handle auto retrieval timeout
      },
    );
  }

  // Verify SMS code
  Future<UserCredential> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    // Handle Firestore profile for phone sign-in
    if (userCredential.user != null) {
      await _handlePhoneUserProfile(userCredential.user!, userCredential.user!.phoneNumber ?? '');
    }

    return userCredential;
  }

  // Helper method to handle phone user profile
  Future<void> _handlePhoneUserProfile(User user, String phoneNumber) async {
    final existingProfile = await _firestoreService.getUserProfile(user.uid);

    if (existingProfile == null) {
      // Create new profile for phone user
      await _firestoreService.createUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Phone User',
        phoneNumber: phoneNumber,
      );
    } else {
      // Update existing profile
      await _firestoreService.updateUserProfile(
        uid: user.uid,
        phoneNumber: phoneNumber,
      );
    }
  }

  // Send verification email (async)
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if email is verified (async)
  Future<bool> isEmailVerified([User? user]) async {
    user ??= _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Stream for email verification changes
  Stream<bool> get emailVerificationStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    });
  }

  // Reauthenticate user
  Future<void> reauthenticateUser(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // Change Email
  Future<void> changeEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    await user.verifyBeforeUpdateEmail(newEmail);
  }

  // Get Firestore service instance
  FirestoreService get firestoreService => _firestoreService;
}