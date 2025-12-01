import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/database_service.dart';

/// Provider for managing contacts
class ContactsProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ContactsProvider() {
    loadContacts();
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contacts = await DatabaseService.getContacts();
      
      // Add some demo contacts if empty
      if (_contacts.isEmpty) {
        _contacts = _getDemoContacts();
        await DatabaseService.saveContacts(_contacts);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addContact(Contact contact) async {
    _contacts.add(contact);
    await DatabaseService.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await DatabaseService.saveContacts(_contacts);
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await DatabaseService.saveContacts(_contacts);
    notifyListeners();
  }

  Contact? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Contact> searchContacts(String query) {
    if (query.isEmpty) return _contacts;
    
    final lowerQuery = query.toLowerCase();
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowerQuery) ||
          contact.phoneNumber.contains(query);
    }).toList();
  }

  List<Contact> _getDemoContacts() {
    return [
      Contact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        isOnline: true,
      ),
      Contact(
        id: '2',
        name: 'Jane Smith',
        phoneNumber: '+0987654321',
        lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Contact(
        id: '3',
        name: 'Bob Wilson',
        phoneNumber: '+1122334455',
        lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
