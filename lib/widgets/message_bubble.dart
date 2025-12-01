import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

/// Widget for displaying a message bubble in chat
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFromMe = message.isFromMe;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isFromMe ? 50 : 8,
          right: isFromMe ? 8 : 50,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isFromMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromMe ? 12 : 0),
            bottomRight: Radius.circular(isFromMe ? 0 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name (for group chats)
            if (showSenderName && !isFromMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getSenderColor(message.senderId),
                  ),
                ),
              ),

            // Message content
            _buildMessageContent(),

            // Time and status
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(),
                    size: 14,
                    color: _getStatusColor(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: const TextStyle(fontSize: 15),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: message.mediaUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.mediaUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message.content),
            ],
          ],
        );

      case MessageType.video:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.video_library, size: 50, color: Colors.grey),
              CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ],
          ),
        );

      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: () {},
              color: const Color(0xFF25D366),
            ),
            Expanded(
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:00',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );

      case MessageType.document:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Color(0xFF25D366)),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content.isNotEmpty ? message.content : 'Document',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.location:
        return Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 40, color: Colors.red),
              SizedBox(height: 8),
              Text('Location'),
            ],
          ),
        );
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSenderColor(String senderId) {
    // Generate a consistent color based on sender ID
    final colors = [
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[senderId.hashCode.abs() % colors.length];
  }
}
