import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.loadConversations();
      provider.startConversationsPolling();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    Provider.of<ChatProvider>(context, listen: false).stopConversationsPolling();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      Provider.of<ChatProvider>(context, listen: false).searchUsers(value);
    });
  }

  Future<void> _openNewChatDialog() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    _searchController.clear();
    provider.clearSearchResults();

    ChatUserPreview? selectedUser;
    final messageController = TextEditingController();
    bool isSubmitting = false;

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start a chat',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        labelText: 'Search by username',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Consumer<ChatProvider>(
                        builder: (context, chatProvider, _) {
                          if (chatProvider.isSearchingUsers) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (chatProvider.searchResults.isEmpty) {
                            return const Center(
                              child: Text('Type at least 2 characters to search users'),
                            );
                          }

                          return ListView.builder(
                            itemCount: chatProvider.searchResults.length,
                            itemBuilder: (context, index) {
                              final user = chatProvider.searchResults[index];
                              final isSelected = selectedUser?.id == user.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                  ),
                                ),
                                title: Text(user.username),
                                subtitle: Text(user.email),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                onTap: () {
                                  setModalState(() {
                                    selectedUser = user;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'First message (chat request)',
                        hintText: 'Hi, can we chat about livestock operations?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          final selected = selectedUser;
                          final message = messageController.text.trim();
                          if (selected == null || message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select a user and enter your first message')),
                            );
                            return;
                          }

                          setModalState(() {
                            isSubmitting = true;
                          });

                          final ok = await provider.createChatRequest(
                            recipientUserId: selected.id,
                            message: message,
                          );

                          if (!mounted) return;
                          if (ok) {
                            Navigator.of(context).pop(true);
                          } else {
                            setModalState(() {
                              isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.error ?? 'Failed to send request')),
                            );
                          }
                        },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Request'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              );
          },
        );
      },
    );

    messageController.dispose();

    if (!mounted) return;
    if (sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat request sent successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingConversations && provider.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 10),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: provider.loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text('No chats yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Search for users and send a chat request to begin.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openNewChatDialog,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Start Chat'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: RefreshIndicator(
            onRefresh: provider.loadConversations,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemBuilder: (context, index) {
                final conversation = provider.conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  currentUserId: currentUserId,
                  onAccept: () async {
                    await provider.respondToRequest(
                      conversationId: conversation.id,
                      accept: true,
                    );
                  },
                  onReject: () async {
                    await provider.respondToRequest(
                      conversationId: conversation.id,
                      accept: false,
                    );
                  },
                  onOpen: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(conversation: conversation),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: provider.conversations.length,
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 56),
            child: FloatingActionButton.extended(
              onPressed: _openNewChatDialog,
              icon: const Icon(Icons.add_comment),
              label: const Text('New Chat'),
              backgroundColor: const Color(0xFF13EC5B),
              foregroundColor: Colors.black87,
            ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String currentUserId;
  final VoidCallback onOpen;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPendingIncoming = conversation.isPending && conversation.requestedToId == currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.18)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF13EC5B).withOpacity(0.2),
          child: Text(
            conversation.otherUser.username.isNotEmpty
                ? conversation.otherUser.username[0].toUpperCase()
                : '?',
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.otherUser.username,
                  style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
            ),
            _StatusChip(status: conversation.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              conversation.lastMessage?.content ?? 'No message yet',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPendingIncoming) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      onReject();
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    Color bg;
    Color fg;

    if (upper == 'ACCEPTED') {
      bg = Colors.green.withOpacity(0.15);
      fg = Colors.green.shade800;
    } else if (upper == 'PENDING') {
      bg = Colors.orange.withOpacity(0.15);
      fg = Colors.orange.shade800;
    } else {
      bg = Colors.red.withOpacity(0.15);
      fg = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        upper,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
