import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/messages_provider.dart';
import '../models/message.dart';
import '../services/whatsapp_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? phoneNumber;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.phoneNumber,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messagesProvider = context.read<MessagesProvider>();
    final messages = await messagesProvider.getMessages(widget.chatId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messagesProvider = context.read<MessagesProvider>();
    await messagesProvider.sendMessage(widget.chatId, text);

    // Reload messages and scroll
    await _loadMessages();

    // If phone number is available, offer to send via WhatsApp
    if (widget.phoneNumber != null) {
      _showSendViaWhatsAppOption(text);
    }
  }

  void _showSendViaWhatsAppOption(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Send via WhatsApp?'),
        action: SnackBarAction(
          label: 'SEND',
          onPressed: () async {
            await WhatsAppService.sendMessage(
              phoneNumber: widget.phoneNumber!,
              message: message,
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: widget.isGroup ? Colors.teal[300] : Colors.grey[300],
              child: Icon(
                widget.isGroup ? Icons.group : Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.phoneNumber != null)
                  Text(
                    widget.phoneNumber!,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.phoneNumber != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                await WhatsAppService.openChat(widget.phoneNumber!);
              },
              tooltip: 'Open in WhatsApp',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.\nStart the conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final showDate = index == 0 ||
                                !_isSameDay(
                                  _messages[index - 1].timestamp,
                                  message.timestamp,
                                );

                            return Column(
                              children: [
                                if (showDate)
                                  _buildDateDivider(message.timestamp),
                                MessageBubble(message: message),
                              ],
                            );
                          },
                        ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
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
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              onPressed: () {
                                // TODO: Emoji picker
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message',
                                  border: InputBorder.none,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                maxLines: null,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () {
                                // TODO: Attachment picker
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF25D366),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final formatter = DateFormat('MMMM d, yyyy');
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (_isSameDay(date, today)) {
      dateText = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = formatter.format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will delete all messages in this chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
