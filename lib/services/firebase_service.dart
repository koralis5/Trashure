import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? null : '210302117157-ek2ngodb5hg99id20ctec3cvmll0rce0.apps.googleusercontent.com',
    scopes: ['email'],
  );

  // Register with email and password
  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Login with email and password
  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Google Sign-In with profile image handling
  Future<UserCredential> googleSignIn() async {
    try {
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        final userCredential = await _auth.signInWithPopup(googleProvider);

        // Handle profile image for web
        if (userCredential.user?.photoURL != null) {
          await _storeProfileImage(userCredential.user!);
        }
        return userCredential;
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google sign-in aborted by user');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        // Handle profile image for mobile
        if (userCredential.user?.photoURL != null) {
          await _storeProfileImage(userCredential.user!);
        }
        return userCredential;
      }
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  // Helper method to store profile image from URL
  Future<void> _storeProfileImage(User user) async {
    try {
      if (user.photoURL == null) return;

      // Download the image
      final response = await http.get(Uri.parse(user.photoURL!));
      if (response.statusCode == 200) {
        // Upload to Firebase Storage
        final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
        await ref.putData(response.bodyBytes);

        // Get new download URL
        final newUrl = await ref.getDownloadURL();

        // Update user profile
        await user.updatePhotoURL(newUrl);
      }
    } catch (e) {
      print('Error storing profile image: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
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

  // Upload profile image from file and return URL
  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(imageFile.path);
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user's photoURL if they're logged in
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.updatePhotoURL(downloadUrl);
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
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

  // Delete profile image
  Future<void> deleteProfileImage(String uid) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.delete();
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
          onAutoVerified(userCredential.user!);
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
    return await _auth.signInWithCredential(credential);
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

  //reauthenticate user
  Future<void> reauthenticateUser(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  //Change Email
  Future<void> changeEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    await user.verifyBeforeUpdateEmail(newEmail);
  }
}