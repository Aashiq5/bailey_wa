import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../models/message.dart';
import 'database_service.dart';

/// WhatsApp service for sending messages and interacting with WhatsApp
class WhatsAppService {
  /// Opens WhatsApp to send a message to a contact
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create WhatsApp URL
      final url = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
      );
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Opens WhatsApp chat with a contact (without pre-filled message)
  static Future<bool> openChat(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = Uri.parse('https://wa.me/$cleanNumber');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening chat: $e');
      return false;
    }
  }

  /// Opens WhatsApp group by invite link
  static Future<bool> openGroup(String inviteLink) async {
    try {
      final url = Uri.parse(inviteLink);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening group: $e');
      return false;
    }
  }

  /// Send message to multiple contacts (bulk messaging)
  static Future<Map<String, bool>> sendBulkMessages({
    required List<Contact> contacts,
    required String message,
    Duration delay = const Duration(seconds: 2),
  }) async {
    final results = <String, bool>{};
    
    for (final contact in contacts) {
      final success = await sendMessage(
        phoneNumber: contact.phoneNumber,
        message: message,
      );
      results[contact.id] = success;
      
      // Add delay between messages to prevent rate limiting
      await Future.delayed(delay);
    }
    
    return results;
  }

  /// Create a new message record
  static Message createMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'me',
      senderName: 'Me',
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isFromMe: true,
    );
  }

  /// Save sent message to local database
  static Future<void> saveMessage(Message message) async {
    await DatabaseService.addMessage(message);
  }
}
