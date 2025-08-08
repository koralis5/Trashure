import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO: Implement full chat functionality

  // Placeholder for chat room creation
  Future<String?> createChatRoom({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required String listingTitle,
  }) async {
    try {
      // Create chat room ID from listing and user IDs
      final participants = [sellerId, buyerId]..sort();
      final chatRoomId = '${listingId}_${participants.join('_')}';

      final chatRoomData = {
        'id': chatRoomId,
        'listingId': listingId,
        'listingTitle': listingTitle,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore.collection('chatRooms').doc(chatRoomId).set(
        chatRoomData,
        SetOptions(merge: true),
      );

      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      return null;
    }
  }

  // Placeholder for sending messages
  Future<bool> sendMessage({
    required String chatRoomId,
    required String message,
    String? imageBase64,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown',
        'message': message,
        'imageBase64': imageBase64,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add message to messages subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Placeholder for getting user's chat rooms
  Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  // Placeholder for getting messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Placeholder for marking messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    try {
      final messages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}