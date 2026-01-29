import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../api/api_service.dart';
import '../services/auth_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  Map<int, Map<String, dynamic>> _institutionCache = {};

  List<Map<String, dynamic>> _filterConversations(List<Map<String, dynamic>> conversations) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }
    return conversations.where((chat) {
      final institutionName = chat['institution_name'] as String? ?? '';
      return institutionName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<Map<String, dynamic>?> _fetchInstitutionDetails(int institutionId) async {
    // Check cache first
    if (_institutionCache.containsKey(institutionId)) {
      return _institutionCache[institutionId];
    }

    try {
      final response = await ApiService.fetchInstitutionDetails(institutionId);
      if (response['status'] == true && response['data'] != null) {
        final institutionData = response['data'] as Map<String, dynamic>;
        _institutionCache[institutionId] = institutionData;
        return institutionData;
      }
    } catch (e) {
      print('Error fetching institution details: $e');
    }
    return null;
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          localizations?.translate('chats') ?? 'Chats',
          style: const TextStyle(
            color: AppTheme.primaryIndigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations?.translate('search_chats') ?? 'Search chats...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Chats List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.listenToConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.translate('no_chats') ?? 'No chats yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = _filterConversations(snapshot.data!);

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.translate('no_results') ?? 'No results found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final firebaseConversationId = conversation['firebase_conversation_id'] as String;
                    final laravelConversationId = conversation['conversation_id'] as String?;
                    final institutionId = int.tryParse(conversation['institution_id']?.toString() ?? '');
                    final institutionName = conversation['institution_name'] as String? ?? 'Institution';
                    final institutionAvatar = conversation['institution_avatar'] as String?;
                    final lastMessage = conversation['last_message'] as String? ?? '';
                    final lastMessageTimestamp = conversation['last_message_timestamp'] as DateTime? ?? DateTime.now();

                    return InkWell(
                      onTap: () async {
                        // Fetch institution details if needed
                        Map<String, dynamic>? institutionData;
                        String finalInstitutionName = institutionName;
                        String? finalInstitutionAvatar = institutionAvatar;

                        if (institutionId != null && (institutionName.isEmpty || institutionName == 'Institution')) {
                          institutionData = await _fetchInstitutionDetails(institutionId);
                          if (institutionData != null) {
                            finalInstitutionName = institutionData['institution_name'] as String? ?? 
                                                   institutionData['name'] as String? ?? 
                                                   'Institution';
                            final about = institutionData['about'] as Map<String, dynamic>?;
                            finalInstitutionAvatar = about?['logo'] as String?;
                          }
                        }

                        if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversationId: firebaseConversationId,
                                laravelConversationId: laravelConversationId,
                                institutionName: finalInstitutionName,
                                institutionAvatar: finalInstitutionAvatar,
                                institutionId: institutionId,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
                              backgroundImage: institutionAvatar != null && institutionAvatar.isNotEmpty
                                  ? NetworkImage(institutionAvatar)
                                  : null,
                              child: institutionAvatar == null || institutionAvatar.isEmpty
                                  ? Text(
                                      institutionName.isNotEmpty
                                          ? institutionName[0].toUpperCase()
                                          : 'I',
                                      style: const TextStyle(
                                        color: AppTheme.accentCyan,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Chat Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          institutionName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(lastMessageTimestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
