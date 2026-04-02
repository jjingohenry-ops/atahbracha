import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatConversation> conversations = <ChatConversation>[];
  List<ChatUserPreview> searchResults = <ChatUserPreview>[];
  List<ChatMessage> activeMessages = <ChatMessage>[];

  bool isLoadingConversations = false;
  bool isSearchingUsers = false;
  bool isSending = false;
  String? error;
  String? activeConversationId;

  Timer? _conversationsPollingTimer;
  Timer? _messagesPollingTimer;

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      isLoadingConversations = true;
      error = null;
      notifyListeners();
    }

    try {
      conversations = await _chatService.getConversations();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingConversations = false;
      notifyListeners();
    }
  }

  void startConversationsPolling() {
    _conversationsPollingTimer?.cancel();
    _conversationsPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadConversations(silent: true);
    });
  }

  void stopConversationsPolling() {
    _conversationsPollingTimer?.cancel();
    _conversationsPollingTimer = null;
  }

  Future<void> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      searchResults = <ChatUserPreview>[];
      notifyListeners();
      return;
    }

    isSearchingUsers = true;
    error = null;
    notifyListeners();

    try {
      searchResults = await _chatService.searchUsers(trimmed);
    } catch (e) {
      error = e.toString();
      searchResults = <ChatUserPreview>[];
    } finally {
      isSearchingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> createChatRequest({required String recipientUserId, required String message}) async {
    isSending = true;
    error = null;
    notifyListeners();

    try {
      await _chatService.createChatRequest(
        recipientUserId: recipientUserId,
        message: message,
      );
      await loadConversations(silent: true);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<bool> respondToRequest({required String conversationId, required bool accept}) async {
    isSending = true;
    error = null;
    notifyListeners();

    try {
      await _chatService.respondToChatRequest(
        conversationId: conversationId,
        accept: accept,
      );
      await loadConversations(silent: true);
      if (activeConversationId == conversationId) {
        await loadMessages(conversationId: conversationId, silent: true);
      }
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages({required String conversationId, bool silent = false}) async {
    if (!silent) {
      error = null;
      notifyListeners();
    }

    try {
      activeConversationId = conversationId;
      activeMessages = await _chatService.getConversationMessages(conversationId);
    } catch (e) {
      error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void startMessagesPolling(String conversationId) {
    _messagesPollingTimer?.cancel();
    _messagesPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadMessages(conversationId: conversationId, silent: true);
    });
  }

  void stopMessagesPolling() {
    _messagesPollingTimer?.cancel();
    _messagesPollingTimer = null;
  }

  Future<bool> sendMessage({required String conversationId, required String content}) async {
    isSending = true;
    error = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(conversationId: conversationId, content: content);
      await loadMessages(conversationId: conversationId, silent: true);
      await loadConversations(silent: true);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    searchResults = <ChatUserPreview>[];
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    super.dispose();
  }
}
