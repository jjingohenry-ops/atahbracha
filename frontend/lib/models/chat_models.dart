class ChatUserPreview {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;

  ChatUserPreview({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ChatUserPreview.fromJson(Map<String, dynamic> json) {
    return ChatUserPreview(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class ChatConversation {
  final String id;
  final String status;
  final String requestedById;
  final String requestedToId;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? lastMessageAt;
  final ChatUserPreview otherUser;
  final ChatMessage? lastMessage;
  final bool isIncomingRequest;

  ChatConversation({
    required this.id,
    required this.status,
    required this.requestedById,
    required this.requestedToId,
    required this.createdAt,
    required this.acceptedAt,
    required this.lastMessageAt,
    required this.otherUser,
    required this.lastMessage,
    required this.isIncomingRequest,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestedById: (json['requestedById'] ?? '').toString(),
      requestedToId: (json['requestedToId'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt'].toString()) : null,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt'].toString()) : null,
      otherUser: ChatUserPreview.fromJson((json['otherUser'] ?? <String, dynamic>{}) as Map<String, dynamic>),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson((json['lastMessage'] as Map<String, dynamic>)..putIfAbsent('conversationId', () => (json['id'] ?? '').toString()))
          : null,
      isIncomingRequest: json['isIncomingRequest'] == true,
    );
  }
}
