import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../services/database_service.dart';

/// Provider for managing messages and chats
class MessagesProvider extends ChangeNotifier {
  final Map<String, List<Message>> _messagesByChat = {};
  List<Chat> _chats = [];
  bool _isLoading = false;
  String? _error;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MessagesProvider() {
    loadChats();
  }

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await DatabaseService.getChats();
      
      // Add demo chats if empty
      if (_chats.isEmpty) {
        _chats = _getDemoChats();
        await DatabaseService.saveChats(_chats);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Message>> getMessages(String chatId) async {
    if (_messagesByChat.containsKey(chatId)) {
      return _messagesByChat[chatId]!;
    }

    final messages = await DatabaseService.getMessages(chatId);
    
    // Add demo messages if empty
    if (messages.isEmpty) {
      final demoMessages = _getDemoMessages(chatId);
      _messagesByChat[chatId] = demoMessages;
      await DatabaseService.saveMessages(chatId, demoMessages);
    } else {
      _messagesByChat[chatId] = messages;
    }

    return _messagesByChat[chatId]!;
  }

  Future<void> sendMessage(String chatId, String content) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'me',
      senderName: 'Me',
      content: content,
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      isFromMe: true,
    );

    _messagesByChat[chatId] ??= [];
    _messagesByChat[chatId]!.add(message);
    
    await DatabaseService.addMessage(message);
    
    // Update chat with last message
    _updateChatLastMessage(chatId, message);
    
    notifyListeners();
  }

  void _updateChatLastMessage(String chatId, Message message) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(lastMessage: message);
      DatabaseService.saveChats(_chats);
    }
  }

  Future<void> markAsRead(String chatId) async {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(unreadCount: 0);
      await DatabaseService.saveChats(_chats);
      notifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((c) => c.id == chatId);
    _messagesByChat.remove(chatId);
    await DatabaseService.saveChats(_chats);
    notifyListeners();
  }

  List<Chat> _getDemoChats() {
    return [
      Chat(
        id: '1',
        name: 'John Doe',
        isGroup: false,
        lastMessage: Message(
          id: 'm1',
          chatId: '1',
          senderId: '1',
          senderName: 'John Doe',
          content: 'Hey, how are you?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isFromMe: false,
        ),
        unreadCount: 2,
      ),
      Chat(
        id: '2',
        name: 'Jane Smith',
        isGroup: false,
        lastMessage: Message(
          id: 'm2',
          chatId: '2',
          senderId: 'me',
          senderName: 'Me',
          content: 'See you later!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isFromMe: true,
        ),
        unreadCount: 0,
      ),
      Chat(
        id: 'g1',
        name: 'Family Group',
        isGroup: true,
        lastMessage: Message(
          id: 'm3',
          chatId: 'g1',
          senderId: '1',
          senderName: 'John Doe',
          content: 'Dinner at 7?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isFromMe: false,
        ),
        unreadCount: 5,
      ),
    ];
  }

  List<Message> _getDemoMessages(String chatId) {
    final now = DateTime.now();
    return [
      Message(
        id: '${chatId}_1',
        chatId: chatId,
        senderId: chatId,
        senderName: 'Contact',
        content: 'Hello! 👋',
        timestamp: now.subtract(const Duration(hours: 2)),
        isFromMe: false,
      ),
      Message(
        id: '${chatId}_2',
        chatId: chatId,
        senderId: 'me',
        senderName: 'Me',
        content: 'Hi there! How are you?',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 55)),
        isFromMe: true,
      ),
      Message(
        id: '${chatId}_3',
        chatId: chatId,
        senderId: chatId,
        senderName: 'Contact',
        content: 'I\'m doing great, thanks for asking!',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
        isFromMe: false,
      ),
    ];
  }
}
