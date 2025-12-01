import 'contact.dart';

/// Group model for storing WhatsApp groups
class Group {
  final String id;
  final String name;
  final String? description;
  final String? groupPicture;
  final List<Contact> members;
  final List<String> adminIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.groupPicture,
    this.members = const [],
    this.adminIds = const [],
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      groupPicture: json['groupPicture'],
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => Contact.fromJson(e))
              .toList() ??
          [],
      adminIds: List<String>.from(json['adminIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'groupPicture': groupPicture,
      'members': members.map((e) => e.toJson()).toList(),
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get memberCount => members.length;

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? groupPicture,
    List<Contact>? members,
    List<String>? adminIds,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupPicture: groupPicture ?? this.groupPicture,
      members: members ?? this.members,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
