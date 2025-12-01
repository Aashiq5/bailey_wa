import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../models/contact.dart';
import '../services/database_service.dart';

/// Provider for managing groups
class GroupsProvider extends ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GroupsProvider() {
    loadGroups();
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await DatabaseService.getGroups();
      
      // Add demo groups if empty
      if (_groups.isEmpty) {
        _groups = _getDemoGroups();
        await DatabaseService.saveGroups(_groups);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGroup(Group group) async {
    _groups.add(group);
    await DatabaseService.saveGroups(_groups);
    notifyListeners();
  }

  Future<void> updateGroup(Group group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      await DatabaseService.saveGroups(_groups);
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    await DatabaseService.saveGroups(_groups);
    notifyListeners();
  }

  Group? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Group> searchGroups(String query) {
    if (query.isEmpty) return _groups;
    
    final lowerQuery = query.toLowerCase();
    return _groups.where((group) {
      return group.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Group> _getDemoGroups() {
    return [
      Group(
        id: 'g1',
        name: 'Family Group',
        description: 'Family chat group',
        members: [
          Contact(id: '1', name: 'John Doe', phoneNumber: '+1234567890'),
          Contact(id: '2', name: 'Jane Smith', phoneNumber: '+0987654321'),
        ],
        adminIds: ['1'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Group(
        id: 'g2',
        name: 'Work Team',
        description: 'Work related discussions',
        members: [
          Contact(id: '1', name: 'John Doe', phoneNumber: '+1234567890'),
          Contact(id: '3', name: 'Bob Wilson', phoneNumber: '+1122334455'),
        ],
        adminIds: ['1'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Group(
        id: 'g3',
        name: 'Friends Forever',
        description: 'Besties group',
        members: [],
        adminIds: [],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
