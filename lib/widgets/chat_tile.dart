import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';

/// Widget for displaying a chat in the list
class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatTile({
    super.key,
    required this.chat,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: chat.isGroup ? Colors.teal[300] : Colors.grey[300],
            backgroundImage: chat.avatarUrl != null
                ? NetworkImage(chat.avatarUrl!)
                : null,
            child: chat.avatarUrl == null
                ? Icon(
                    chat.isGroup ? Icons.group : Icons.person,
                    color: Colors.white,
                  )
                : null,
          ),
          if (chat.isMuted)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_off,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: TextStyle(
                fontWeight: chat.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.isPinned)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.push_pin, size: 16, color: Colors.grey),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chat.lastMessage?.isFromMe == true) ...[
            Icon(
              _getStatusIcon(chat.lastMessage!.status),
              size: 16,
              color: _getStatusColor(chat.lastMessage!.status),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              chat.lastMessage?.content ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessage?.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: chat.unreadCount > 0
                  ? const Color(0xFF25D366)
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  IconData _getStatusIcon(status) {
    switch (status.toString()) {
      case 'MessageStatus.sending':
        return Icons.access_time;
      case 'MessageStatus.sent':
        return Icons.check;
      case 'MessageStatus.delivered':
        return Icons.done_all;
      case 'MessageStatus.read':
        return Icons.done_all;
      case 'MessageStatus.failed':
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Color _getStatusColor(status) {
    if (status.toString() == 'MessageStatus.read') {
      return Colors.blue;
    } else if (status.toString() == 'MessageStatus.failed') {
      return Colors.red;
    }
    return Colors.grey;
  }
}
