import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/chat.dart';

/// Database service for local storage of contacts, groups, and messages
class DatabaseService {
  static const String _contactsKey = 'contacts';
  static const String _groupsKey = 'groups';
  static const String _messagesKey = 'messages';
  static const String _chatsKey = 'chats';

  // Contacts
  static Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_contactsKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Contact.fromJson(e)).toList();
  }

  static Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await prefs.setString(_contactsKey, data);
  }

  static Future<void> addContact(Contact contact) async {
    final contacts = await getContacts();
    contacts.add(contact);
    await saveContacts(contacts);
  }

  static Future<void> deleteContact(String id) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveContacts(contacts);
  }

  // Groups
  static Future<List<Group>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_groupsKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Group.fromJson(e)).toList();
  }

  static Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(groups.map((e) => e.toJson()).toList());
    await prefs.setString(_groupsKey, data);
  }

  static Future<void> addGroup(Group group) async {
    final groups = await getGroups();
    groups.add(group);
    await saveGroups(groups);
  }

  static Future<void> deleteGroup(String id) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == id);
    await saveGroups(groups);
  }

  // Messages
  static Future<List<Message>> getMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_messagesKey}_$chatId');
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Message.fromJson(e)).toList();
  }

  static Future<void> saveMessages(String chatId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(messages.map((e) => e.toJson()).toList());
    await prefs.setString('${_messagesKey}_$chatId', data);
  }

  static Future<void> addMessage(Message message) async {
    final messages = await getMessages(message.chatId);
    messages.add(message);
    await saveMessages(message.chatId, messages);
  }

  // Chats
  static Future<List<Chat>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_chatsKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Chat.fromJson(e)).toList();
  }

  static Future<void> saveChats(List<Chat> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(chats.map((e) => e.toJson()).toList());
    await prefs.setString(_chatsKey, data);
  }

  static Future<void> updateChat(Chat chat) async {
    final chats = await getChats();
    final index = chats.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      chats[index] = chat;
    } else {
      chats.add(chat);
    }
    await saveChats(chats);
  }

  // Last check timestamp for hourly polling
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('lastCheckTime');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> setLastCheckTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCheckTime', time.toIso8601String());
  }
}
