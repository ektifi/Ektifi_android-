import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId; // Firebase conversation ID (for Firestore operations)
  final String? laravelConversationId; // Laravel database ID (for API calls)
  final String institutionName;
  final String? institutionAvatar;
  final int? institutionId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.laravelConversationId,
    required this.institutionName,
    this.institutionAvatar,
    this.institutionId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _token;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication token
      _token = await _authService.getToken();
      
      // Ensure conversation document exists in Firestore
      final currentUser = await _authService.getCurrentUser();
      final userId = currentUser?.id?.toString() ?? '';
      
      await _chatService.ensureConversationExists(
        conversationId: widget.conversationId,
        userId: userId,
        institutionId: widget.institutionId,
        institutionName: widget.institutionName,
      );
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(widget.conversationId);
      
      setState(() {
        _isLoading = false;
      });

      // Scroll to bottom after messages load
      _scrollToBottom();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_token == null) {
      _showError('Please login to send messages');
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Use Laravel DB ID for API calls, fallback to Firebase ID if not available
      final apiConversationId = widget.laravelConversationId ?? widget.conversationId;
      final firebaseConversationId = widget.conversationId;
      
      print('Sending message - Laravel ID: $apiConversationId, Firebase ID: $firebaseConversationId');
      
      // Send message via Laravel API
      // Laravel will handle saving to both database AND Firestore
      final response = await ApiService.sendMessage(
        conversationId: apiConversationId,
        message: messageText,
        senderType: 'user',
        token: _token!,
      );

      print('Laravel response: $response');
      
      // Check if Laravel saved to Firestore by waiting and checking
      // Only save from Flutter if Laravel didn't save it (fallback)
      try {
        // Wait a moment for Laravel to save to Firestore
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if message already exists in Firestore (Laravel saved it)
        final messagesSnapshot = await _firestore
            .collection('conversations')
            .doc(firebaseConversationId)
            .collection('messages')
            .where('text', isEqualTo: messageText)
            .where('sender_type', isEqualTo: 'user')
            .limit(1)
            .get();
        
        if (messagesSnapshot.docs.isEmpty) {
          // Laravel didn't save to Firestore, save it manually as fallback
          print('Message not found in Firestore, saving manually as fallback...');
          final currentUser = await _authService.getCurrentUser();
          final userId = currentUser?.id?.toString() ?? '';
          
          await _chatService.saveMessageToFirestore(
            conversationId: firebaseConversationId,
            text: messageText,
            senderId: userId,
            senderType: 'user',
            institutionId: widget.institutionId,
            institutionName: widget.institutionName,
          );
          
          print('Message saved to Firestore as fallback');
        } else {
          print('Message already exists in Firestore (saved by Laravel), skipping duplicate save');
        }
      } catch (e, stackTrace) {
        print('Error checking/saving to Firestore: $e');
        print('Stack trace: $stackTrace');
        // Don't show error - message is already in Laravel DB
      }
      
      // Wait a moment for Firestore to update, then scroll
      await Future.delayed(const Duration(milliseconds: 300));
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      _showError('Failed to send message. Please try again.');
      // Restore message text on error
      _messageController.text = messageText;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);
    final isRTL = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: AppTheme.primaryIndigo,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
              backgroundImage: widget.institutionAvatar != null
                  ? NetworkImage(widget.institutionAvatar!)
                  : null,
              child: widget.institutionAvatar == null
                  ? Text(
                      widget.institutionName.isNotEmpty
                          ? widget.institutionName[0].toUpperCase()
                          : 'I',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.institutionName,
                style: const TextStyle(
                  color: AppTheme.primaryIndigo,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.primaryIndigo),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: localizations?.translate('type_message') ?? 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : AppTheme.accentCyan,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    print('Listening to messages for conversation ID: ${widget.conversationId}');
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.listenToMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Start the conversation!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final messages = snapshot.data!;
        
        print('Chat messages count: ${messages.length}');
        if (messages.isNotEmpty) {
          print('Latest message: ${messages.last['text']}');
          print('All messages: ${messages.map((m) => m['text']).toList()}');
        }

        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message['isMe'] as bool? ?? false;
            final messageText = message['text'] as String? ?? '';
            final timestamp = message['timestamp'] as DateTime? ?? DateTime.now();

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
                        backgroundImage: widget.institutionAvatar != null
                            ? NetworkImage(widget.institutionAvatar!)
                            : null,
                        child: widget.institutionAvatar == null
                            ? Text(
                                widget.institutionName.isNotEmpty
                                    ? widget.institutionName[0].toUpperCase()
                                    : 'I',
                                style: const TextStyle(
                                  color: AppTheme.accentCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.accentCyan : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          size: 14,
                          color: AppTheme.primaryIndigo,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
