import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Save user profile data to Firestore
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      print('User profile saved successfully for uid: $uid');
    } catch (e) {
      print('Error saving user profile: $e');
      throw e;
    }
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('User profile retrieved for uid: $uid');
        return doc.data();
      }
      print('No user profile found for uid: $uid');
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw e;
    }
  }

  // Create initial user profile (called during registration)
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? profileImageBase64,
  }) async {
    try {
      final profileData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phone': phoneNumber ?? '',
        'profileImageBase64': profileImageBase64,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(profileData);
      print('Initial user profile created for uid: $uid');
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Update user profile (called when editing profile)
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? profileImageBase64,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phone'] = phoneNumber;
      if (profileImageBase64 != null) updateData['profileImageBase64'] = profileImageBase64;

      await _firestore.collection('users').doc(uid).update(updateData);
      print('User profile updated for uid: $uid');
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Remove profile image
  Future<void> removeUserProfileImage(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Profile image removed for uid: $uid');
    } catch (e) {
      print('Error removing profile image: $e');
      throw e;
    }
  }

  // Convert XFile to base64 string
  Future<String?> convertImageToBase64(XFile imageFile) async {
    try {
      Uint8List bytes = await imageFile.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  // Upload profile image to Firebase Storage and get download URL
  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(imageFile.path);
        await ref.putFile(file);
      }

      final url = await ref.getDownloadURL();
      print('Profile image uploaded successfully for uid: $uid');
      return url;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      await ref.delete();
      print('Profile image deleted for uid: $uid');
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }

  // Listen to user profile changes
  Stream<Map<String, dynamic>?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // Delete user profile (for account deletion)
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('User profile deleted for uid: $uid');
    } catch (e) {
      print('Error deleting user profile: $e');
      throw e;
    }
  }
}