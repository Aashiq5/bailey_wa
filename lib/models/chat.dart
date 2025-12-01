import 'message.dart';

/// Chat model representing a conversation (either with contact or in a group)
class Chat {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isGroup;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  Chat({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isGroup = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      isGroup: json['isGroup'] ?? false,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isGroup': isGroup,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isGroup,
    Message? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGroup: isGroup ?? this.isGroup,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
