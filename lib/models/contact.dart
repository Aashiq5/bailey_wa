/// Contact model for storing WhatsApp contacts
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profilePicture;
  final DateTime? lastSeen;
  final bool isOnline;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profilePicture,
    this.lastSeen,
    this.isOnline = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profilePicture: json['profilePicture'],
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? profilePicture,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
