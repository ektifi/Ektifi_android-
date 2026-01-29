import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Listen to real-time messages for a conversation
  Stream<List<Map<String, dynamic>>> listenToMessages(String conversationId) {
    print('ChatService: Listening to conversations/$conversationId/messages');
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        // Don't use orderBy here - we'll sort manually to support both 'timestamp' and 'created_at'
        .snapshots()
        .asyncMap((snapshot) async {
      print('ChatService: Received ${snapshot.docs.length} messages from Firestore');
      
      // Get current user to determine if message is from current user
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id?.toString() ?? '';

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final senderId = data['sender_id']?.toString() ?? '';
        final senderType = data['sender_type'] ?? '';
        
        // Support both 'text' and 'message' field names (backend uses 'message', Flutter uses 'text')
        final text = data['text'] ?? data['message'] ?? '';
        
        // Determine if message is from current user
        // Check both by sender_id and sender_type
        final isMe = senderType == 'user' || senderId == currentUserId;
        
        // Handle timestamp - support both 'timestamp' and 'created_at' field names
        DateTime timestamp;
        if (data['timestamp'] != null) {
          if (data['timestamp'] is Timestamp) {
            timestamp = (data['timestamp'] as Timestamp).toDate();
          } else {
            timestamp = DateTime.now();
          }
        } else if (data['created_at'] != null) {
          // Backend uses 'created_at' field
          if (data['created_at'] is Timestamp) {
            timestamp = (data['created_at'] as Timestamp).toDate();
          } else {
            timestamp = DateTime.now();
          }
        } else {
          // Fallback to current time if no timestamp field exists
          timestamp = DateTime.now();
        }
        
        print('Message: $text, Sender: $senderId, Type: $senderType, IsMe: $isMe, Timestamp: $timestamp');
        
        return {
          'id': doc.id,
          'text': text,
          'senderId': senderId,
          'senderType': senderType,
          'timestamp': timestamp,
          'isMe': isMe,
        };
      }).toList();
      
      // Sort messages by timestamp manually (oldest first, newest at bottom)
      messages.sort((a, b) {
        final timeA = a['timestamp'] as DateTime;
        final timeB = b['timestamp'] as DateTime;
        return timeA.compareTo(timeB);
      });
      
      print('ChatService: Processed ${messages.length} messages');
      return messages;
    });
  }

  /// Get conversation document
  Future<DocumentSnapshot> getConversation(String conversationId) async {
    return await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
  }

  /// Update conversation last message and timestamp
  Future<void> updateConversationLastMessage(
    String conversationId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
      'last_message': lastMessage,
      'last_message_timestamp': Timestamp.fromDate(timestamp),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return;

    final messagesSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('sender_type', isNotEqualTo: 'user')
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Check if conversation exists
  Future<bool> conversationExists(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    return doc.exists;
  }

  /// Ensure conversation document exists in Firestore
  Future<void> ensureConversationExists({
    required String conversationId,
    required String userId,
    int? institutionId,
    String? institutionName,
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      
      final doc = await conversationRef.get();
      if (!doc.exists) {
        print('Creating conversation document: $conversationId');
        await conversationRef.set({
          'user_id': userId,
          'institution_id': institutionId?.toString() ?? '',
          'institution_name': institutionName ?? 'Institution',
          'last_message': '',
          'last_message_timestamp': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Conversation document created successfully');
      } else {
        print('Conversation document already exists');
      }
    } catch (e) {
      print('Error ensuring conversation exists: $e');
      rethrow;
    }
  }

  /// Save message to Firestore manually (fallback if Laravel doesn't save)
  Future<void> saveMessageToFirestore({
    required String conversationId,
    required String text,
    required String senderId,
    required String senderType,
    int? institutionId,
    String? institutionName,
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      
      // Check if conversation document exists, create if not
      final conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        print('Conversation document does not exist, creating it...');
        await conversationRef.set({
          'user_id': senderId,
          'institution_id': institutionId?.toString() ?? '',
          'institution_name': institutionName ?? 'Institution',
          'last_message': text,
          'last_message_timestamp': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // Add message to messages subcollection with explicit timestamp
      final now = DateTime.now();
      await conversationRef.collection('messages').add({
        'text': text,
        'sender_id': senderId,
        'sender_type': senderType,
        'timestamp': Timestamp.fromDate(now), // Use explicit timestamp
      });
      
      print('Message saved to Firestore: conversations/$conversationId/messages');
      print('Message text: $text, Sender: $senderId, Type: $senderType');
      
      // Update conversation last message
      try {
        await conversationRef.update({
          'last_message': text,
          'last_message_timestamp': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });
      } catch (e) {
        // If update fails, try set with merge
        print('Update failed, trying set with merge: $e');
        await conversationRef.set({
          'last_message': text,
          'last_message_timestamp': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
      }
      
      print('Conversation metadata updated successfully');
    } catch (e, stackTrace) {
      print('Error saving message to Firestore: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Listen to all conversations for the current user
  /// Returns a stream of conversations with last message info
  Stream<List<Map<String, dynamic>>> listenToConversations() {
    final currentUser = _authService.getCurrentUser();
    
    return _firestore
        .collection('conversations')
        .orderBy('last_message_timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['user_id']?.toString();
        final currentUserData = await currentUser;
        final currentUserId = currentUserData?.id?.toString();
        
        // Only include conversations for the current user
        if (userId == currentUserId) {
          final lastMessageTimestamp = data['last_message_timestamp'] as Timestamp?;
          
          conversations.add({
            'id': doc.id, // Firebase conversation ID
            'firebase_conversation_id': doc.id,
            'conversation_id': data['conversation_id']?.toString(), // Laravel DB ID if available
            'institution_id': data['institution_id']?.toString(),
            'user_id': userId,
            'last_message': data['last_message'] ?? '',
            'last_message_timestamp': lastMessageTimestamp?.toDate() ?? DateTime.now(),
            'institution_name': data['institution_name'] ?? '',
            'institution_avatar': data['institution_avatar'] ?? data['institution_logo'] ?? '',
            'updated_at': (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          });
        }
      }
      
      return conversations;
    });
  }
}
