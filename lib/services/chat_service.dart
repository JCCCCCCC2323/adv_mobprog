import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Enhancement 1: Stream all registered users except the current user.
  //Ocray do this completed//
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    return _firestore.collection('Users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((document) {
            final storedUid = (document.data()['uid'] ?? '').toString().trim();
            final uid = storedUid.isEmpty ? document.id : storedUid;
            return uid != currentUserId;
          })
          .map((document) {
            final user = Map<String, dynamic>.from(document.data());
            final storedUid = (user['uid'] ?? '').toString().trim();
            user['uid'] = storedUid.isEmpty ? document.id : storedUid;
            return user;
          })
          .toList();
      users.sort(
        (first, second) => _userName(first).compareTo(_userName(second)),
      );
      return users;
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw StateError('You must sign in before sending a message.');
    }

    final newMessage = MessageModel(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      receiverId: receiverId,
      message: message.trim(),
      timestamp: Timestamp.now(),
      status: 'delivered',
    );

    await _messagesReference(
      currentUser.uid,
      receiverId,
    ).add(newMessage.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String userId,
    String otherUserId,
  ) {
    return _messagesReference(
      userId,
      otherUserId,
    ).orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> markMessagesAsSeen(
    String currentUserId,
    String otherUserId,
  ) async {
    final snapshot = await _messagesReference(currentUserId, otherUserId).get();
    final batch = _firestore.batch();
    var hasUpdates = false;

    for (final document in snapshot.docs) {
      final data = document.data();
      final isIncoming =
          data['senderId'] == otherUserId &&
          data['receiverId'] == currentUserId;
      if (isIncoming && data['status'] != 'seen') {
        batch.update(document.reference, {
          'status': 'seen',
          'seenAt': FieldValue.serverTimestamp(),
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final query = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return (query.docs.first.data()['uid'] ?? query.docs.first.id).toString();
  }

  CollectionReference<Map<String, dynamic>> _messagesReference(
    String firstUserId,
    String secondUserId,
  ) {
    final ids = [firstUserId, secondUserId]..sort();
    return _firestore
        .collection('chat_rooms')
        .doc(ids.join('_'))
        .collection('messages');
  }

  String _userName(Map<String, dynamic> user) {
    final firstName = (user['firstName'] ?? '').toString();
    final lastName = (user['lastName'] ?? '').toString();
    return '$firstName $lastName'.trim().toLowerCase();
  }
}
