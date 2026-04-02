import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_base.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  static const _primary = Color(0xFF13EC5B);
  static const _bg = Color(0xFFF6F8F6);
  static const _systemPrompt =
      'You are AtahBracha AI, an expert livestock management assistant for farmers. '
      'You help with animal health diagnostics, breeding advice, feeding plans, vaccination schedules, '
      'disease identification, market pricing, and general farm management. '
      'Keep responses concise, practical, and farmer-friendly. '
      'If asked about a specific animal issue, ask relevant follow-up questions to give better advice.';

  // Conversation history sent to the API for context (dynamic to support reasoning_details)
  final List<Map<String, dynamic>> _history = [];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isAi: true,
      text:
          "Hello! I'm your livestock assistant. How can I help you with your animals today? I can provide health diagnostics, breeding advice, or current market trends.",
      time: _timeNow(),
    ),
  ];

  static String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  final List<String> _suggestions = [
    'Check my cow\'s health',
    'Breeding tips for goats',
    'Market price for pigs',
    'Vaccination schedule',
    'Feed requirements',
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final content = (text ?? _inputController.text).trim();
    if (content.isEmpty || _isTyping) return;

    // Add user message to UI and history
    setState(() {
      _messages.add(_ChatMessage(isAi: false, text: content, time: _timeNow()));
      _inputController.clear();
      _isTyping = true;
    });
    _history.add({'role': 'user', 'content': content});
    _scrollToBottom();

    try {
      final response = await http.post(
        ApiBase.uri('/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': _history,
          'systemPrompt': _systemPrompt,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['data'] as Map<String, dynamic>;
        final reply = (message['content'] as String? ?? '').trim();
        // Preserve reasoning_details for multi-turn reasoning continuity
        final assistantEntry = <String, dynamic>{'role': 'assistant', 'content': reply};
        if (message['reasoning_details'] != null) {
          assistantEntry['reasoning_details'] = message['reasoning_details'];
        }
        _history.add(assistantEntry);
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(isAi: true, text: reply, time: _timeNow()));
        });
      } else {
        final err = jsonDecode(response.body);
        final errMsg = err['error'] ?? 'Request failed (${response.statusCode})';
        _history.removeLast(); // remove user message from history on failure
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            isAi: true,
            text: '⚠️ $errMsg',
            time: _timeNow(),
            isError: true,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      _history.removeLast();
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          isAi: true,
          text: '⚠️ Could not reach AtahBracha AI. Check your connection.',
          time: _timeNow(),
          isError: true,
        ));
      });
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return msg.isAi
                    ? _buildAiMessage(msg)
                    : _buildUserMessage(msg);
              },
            ),
          ),
          _buildBottomBar(bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: _primary.withOpacity(0.15)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AtahBracha AI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _primary.withOpacity(0.3)),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _primary.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATAHABRACAH AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: _primary.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    msg.time,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildUserMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.zero,
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    msg.time,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 22, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _primary.withOpacity(0.12))),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick suggestions
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _sendMessage(_suggestions[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primary.withOpacity(0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _suggestions[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file),
                        iconSize: 20,
                        color: Colors.grey[500],
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.image_outlined),
                        iconSize: 20,
                        color: Colors.grey[500],
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.black87, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Color(0xFF13EC5B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isAi;
  final String text;
  final String time;
  final bool isError;
  final bool isTyping;

  const _ChatMessage({
    required this.isAi,
    required this.text,
    required this.time,
    this.isError = false,
    this.isTyping = false,
  });
}
