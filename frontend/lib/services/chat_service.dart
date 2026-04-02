import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../core/network/api_base.dart';

class ChatService {
  String get _baseUrl => '${ApiBase.api}/chat';

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to use chat');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Unable to get auth token');
    }
    return token;
  }

  Future<List<ChatUserPreview>> searchUsers(String query) async {
    final token = await _requireToken();
    final uri = Uri.parse('$_baseUrl/users/search?q=${Uri.encodeQueryComponent(query)}');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to search users');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception((decoded['error'] ?? 'Failed to search users').toString());
    }

    final raw = (decoded['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return raw.map(ChatUserPreview.fromJson).toList();
  }

  Future<List<ChatConversation>> getConversations() async {
    final token = await _requireToken();
    final response = await http.get(Uri.parse('$_baseUrl/conversations'), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch conversations');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception((decoded['error'] ?? 'Failed to fetch conversations').toString());
    }

    final raw = (decoded['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return raw.map(ChatConversation.fromJson).toList();
  }

  Future<void> createChatRequest({
    required String recipientUserId,
    required String message,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipientUserId': recipientUserId,
        'message': message,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception((decoded['error'] ?? 'Failed to send chat request').toString());
    }
  }

  Future<void> respondToChatRequest({
    required String conversationId,
    required bool accept,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/$conversationId/respond'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': accept ? 'ACCEPT' : 'REJECT',
      }),
    );

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception((decoded['error'] ?? 'Failed to respond to request').toString());
    }
  }

  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch messages');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception((decoded['error'] ?? 'Failed to fetch messages').toString());
    }

    final data = (decoded['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final raw = (data['messages'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return raw.map((item) {
      final withConversationId = <String, dynamic>{
        ...item,
        'conversationId': conversationId,
      };
      return ChatMessage.fromJson(withConversationId);
    }).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception((decoded['error'] ?? 'Failed to send message').toString());
    }
  }
}
