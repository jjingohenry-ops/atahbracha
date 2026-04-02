import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ConversationScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.loadMessages(conversationId: widget.conversation.id);
      provider.startMessagesPolling(widget.conversation.id);
      provider.loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    Provider.of<ChatProvider>(context, listen: false).stopMessagesPolling();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final ok = await provider.sendMessage(
      conversationId: widget.conversation.id,
      content: message,
    );

    if (!mounted) return;

    if (ok) {
      _messageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        ChatConversation? latestConversation;
        for (final item in provider.conversations) {
          if (item.id == widget.conversation.id) {
            latestConversation = item;
            break;
          }
        }

        final conversation = latestConversation ?? widget.conversation;
        final canSend = conversation.isAccepted;
        final isIncomingPending = conversation.isPending && conversation.requestedToId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text(conversation.otherUser.username),
            actions: [
              _statusBadge(conversation.status),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              if (conversation.isPending)
                Container(
                  width: double.infinity,
                  color: Colors.orange.withOpacity(0.15),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncomingPending
                            ? 'This is a chat request. Accept to continue normal live chat.'
                            : 'Chat request sent. Waiting for acceptance before normal chat starts.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isIncomingPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await provider.respondToRequest(
                                  conversationId: conversation.id,
                                  accept: true,
                                );
                                await provider.loadConversations(silent: true);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await provider.respondToRequest(
                                  conversationId: conversation.id,
                                  accept: false,
                                );
                                if (!mounted) return;
                                Navigator.of(context).pop();
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              Expanded(
                child: provider.activeMessages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.activeMessages.length,
                        itemBuilder: (context, index) {
                          final message = provider.activeMessages[provider.activeMessages.length - 1 - index];
                          final isMine = message.senderId == currentUserId;
                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMine ? const Color(0xFF13EC5B) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(color: isMine ? Colors.black : Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMine ? Colors.black54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: canSend,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: canSend ? 'Type a message...' : 'Waiting for chat acceptance',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: canSend ? const Color(0xFF13EC5B) : Colors.grey.shade400,
                        child: IconButton(
                          onPressed: canSend ? _sendMessage : null,
                          icon: const Icon(Icons.send, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    final upper = status.toUpperCase();
    Color color;

    if (upper == 'ACCEPTED') {
      color = Colors.green;
    } else if (upper == 'PENDING') {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Chip(
      label: Text(upper),
      side: BorderSide.none,
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
    );
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
