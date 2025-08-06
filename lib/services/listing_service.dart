import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new listing
  Future<String?> createListing({
    required String userId,
    required String title,
    required double price,
    required String description,
    required String sellerName,
    String? imageBase64,
  }) async {
    try {
      final listingData = {
        'userId': userId,
        'title': title,
        'price': price,
        'description': description,
        'sellerName': sellerName,
        'imageBase64': imageBase64,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore.collection('listings').add(listingData);
      print('Listing created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating listing: $e');
      throw e;
    }
  }

  // Get all active listings
  Future<List<Map<String, dynamic>>> getAllListings() async {
    try {
      // Try the optimized query first
      try {
        final querySnapshot = await _firestore
            .collection('listings')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID
          return data;
        }).toList();
      } catch (indexError) {
        print('Index not ready, using fallback query: $indexError');

        // Fallback: Get all active listings without ordering
        final querySnapshot = await _firestore
            .collection('listings')
            .where('isActive', isEqualTo: true)
            .get();

        final listings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort locally by createdAt
        listings.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return listings;
      }
    } catch (e) {
      print('Error getting all listings: $e');
      throw e;
    }
  }

  // Get listings for a specific user
  Future<List<Map<String, dynamic>>> getUserListings(String userId) async {
    try {
      // Try the optimized query first
      try {
        final querySnapshot = await _firestore
            .collection('listings')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID
          return data;
        }).toList();
      } catch (indexError) {
        print('Index not ready, using fallback query: $indexError');

        // Fallback: Get user listings without ordering
        final querySnapshot = await _firestore
            .collection('listings')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .get();

        final listings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort locally by createdAt
        listings.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return listings;
      }
    } catch (e) {
      print('Error getting user listings: $e');
      throw e;
    }
  }

  // Get a single listing by ID
  Future<Map<String, dynamic>?> getListingById(String listingId) async {
    try {
      final docSnapshot = await _firestore.collection('listings').doc(listingId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting listing by ID: $e');
      throw e;
    }
  }

  // Update a listing
  Future<void> updateListing({
    required String listingId,
    String? title,
    double? price,
    String? description,
    String? imageBase64,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (price != null) updateData['price'] = price;
      if (description != null) updateData['description'] = description;
      if (imageBase64 != null) updateData['imageBase64'] = imageBase64;

      await _firestore.collection('listings').doc(listingId).update(updateData);
      print('Listing updated: $listingId');
    } catch (e) {
      print('Error updating listing: $e');
      throw e;
    }
  }

  // Delete a listing (soft delete)
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Listing deleted: $listingId');
    } catch (e) {
      print('Error deleting listing: $e');
      throw e;
    }
  }

  // Hard delete a listing (permanent)
  Future<void> permanentlyDeleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
      print('Listing permanently deleted: $listingId');
    } catch (e) {
      print('Error permanently deleting listing: $e');
      throw e;
    }
  }

  // Convert XFile to base64 string for listing images
  Future<String?> convertImageToBase64(XFile imageFile) async {
    try {
      Uint8List bytes = await imageFile.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error converting listing image to base64: $e');
      return null;
    }
  }

  // Search listings by title
  Future<List<Map<String, dynamic>>> searchListings(String searchQuery) async {
    try {
      // Get all active listings (without ordering to avoid index issues)
      final querySnapshot = await _firestore
          .collection('listings')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter and sort results locally
      final filteredResults = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final title = data['title']?.toString().toLowerCase() ?? '';
        return title.contains(searchQuery.toLowerCase());
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by createdAt locally
      filteredResults.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return filteredResults;
    } catch (e) {
      print('Error searching listings: $e');
      throw e;
    }
  }

  // Stream for real-time listings updates (simplified to avoid index issues)
  Stream<List<Map<String, dynamic>>> getListingsStream() {
    return _firestore
        .collection('listings')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort locally by createdAt
      listings.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return listings;
    });
  }

  // Stream for real-time user listings updates (simplified to avoid index issues)
  Stream<List<Map<String, dynamic>>> getUserListingsStream(String userId) {
    return _firestore
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort locally by createdAt
      listings.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return listings;
    });
  }
}