import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Save user profile data to Firestore
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Upload profile image to Firebase Storage and get download URL
  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    final File file = File(imageFile.path);
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
}
