import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Register with email and password
  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Login with email and password
  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Google Sign-In
  Future<UserCredential> googleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '210302117157-ek2ngodb5hg99id20ctec3cvmll0rce0.apps.googleusercontent.com',
      scopes: ['email'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted by user');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> logOut() {
    return _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> getAuthUser() {
    return _auth.authStateChanges();
  }
  // Upload profile image and return URL
  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');

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
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
}
