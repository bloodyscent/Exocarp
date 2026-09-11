import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? detectedDisease;
  final double? confidence;

  const AiChatScreen({super.key, this.detectedDisease, this.confidence});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late final AiChatService _aiChatService;

  final List<_ChatMessage> _messages = [];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _aiChatService = AiChatService(
      detectedDisease: widget.detectedDisease,
      confidence: widget.confidence,
    );

    _messages.add(
      _ChatMessage(
        text: widget.detectedDisease == null
            ? 'Hi! I’m EXOCARP AI. Ask me anything about mango leaf diseases, symptoms, causes, or your EXOCARP scan.'
            : 'Hi! I’m EXOCARP AI. I can help explain your ${widget.detectedDisease} scan, including possible causes, symptoms, and contributing conditions.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));

      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final response = await _aiChatService.sendMessage(message);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));

      _isSending = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _useSuggestion(String text) {
    _messageController.text = text;

    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        titleSpacing: 0,

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0B6B3A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 21),
            ),

            const SizedBox(width: 12),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXOCARP AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Mango Leaf Assistant',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B6B3A), Color(0xFF063D24), Color(0xFF050805)],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              if (widget.detectedDisease != null) _buildScanContext(),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isSending && index == _messages.length) {
                      return const _TypingIndicator();
                    }

                    final message = _messages[index];

                    return _buildMessageBubble(message);
                  },
                ),
              ),

              _buildSuggestions(),

              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanContext() {
    final confidence = widget.confidence;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFF0A2116),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF164D32)),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.document_scanner,
            color: Color(0xFF4CAF50),
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current scan',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),

                const SizedBox(height: 2),

                Text(
                  widget.detectedDisease!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                if (confidence != null)
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),

        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF0B6B3A)
              : const Color(0xFF0A2116),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),

          border: message.isUser
              ? null
              : Border.all(color: const Color(0xFF164D32)),
        ),

        child: message.isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  h1: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h4: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  listIndent: 20,
                  blockSpacing: 8,
                ),
              ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_messages.length > 1) {
      return const SizedBox.shrink();
    }

    final suggestions = widget.detectedDisease == null
        ? [
            'What mango leaf diseases can EXOCARP detect?',
            'What causes mango leaf diseases?',
          ]
        : [
            'Why might this leaf have this disease?',
            'What causes this disease?',
          ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            backgroundColor: const Color(0xFF0A2116),
            side: const BorderSide(color: Color(0xFF164D32)),
            label: Text(
              suggestions[index],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            onPressed: () {
              _useSuggestion(suggestions[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),

      decoration: const BoxDecoration(
        color: Color(0xFF050805),
        border: Border(top: BorderSide(color: Color(0xFF164D32))),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,

              decoration: InputDecoration(
                hintText: 'Ask EXOCARP AI...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0A2116),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),

              onSubmitted: (_) {
                _sendMessage();
              },
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 48,
            height: 48,

            decoration: const BoxDecoration(
              color: Color(0xFF0B6B3A),
              shape: BoxShape.circle,
            ),

            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2116),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF164D32)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4CAF50),
          ),
        ),
      ),
    );
  }
}
