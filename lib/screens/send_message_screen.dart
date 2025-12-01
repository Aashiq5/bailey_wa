import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/groups_provider.dart';
import '../services/whatsapp_service.dart';

class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({super.key});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  final Set<String> _selectedGroupIds = {};
  bool _isSending = false;
  int _currentTab = 0; // 0: Quick send, 1: Contacts, 2: Groups

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
        actions: [
          if (_selectedContactIds.isNotEmpty || _selectedGroupIds.isNotEmpty)
            TextButton(
              onPressed: _isSending ? null : _sendToSelected,
              child: Text(
                'Send (${_selectedContactIds.length + _selectedGroupIds.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your message here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),

          // Tab bar
          Container(
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                _buildTab('Quick Send', 0),
                _buildTab('Contacts', 1),
                _buildTab('Groups', 2),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildQuickSendTab(),
                _buildContactsTab(),
                _buildGroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Send',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a phone number to send a message directly via WhatsApp.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1234567890',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _sendQuickMessage,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isSending ? 'Opening WhatsApp...' : 'Send via WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Bulk Send',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select contacts or groups from the tabs above to send messages in bulk.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = provider.contacts;

        if (contacts.isEmpty) {
          return const Center(
            child: Text('No contacts available'),
          );
        }

        return Column(
          children: [
            // Select all / Deselect all
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_selectedContactIds.length} selected'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedContactIds.addAll(
                              contacts.map((c) => c.id),
                            );
                          });
                        },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedContactIds.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isSelected = _selectedContactIds.contains(contact.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedContactIds.add(contact.id);
                        } else {
                          _selectedContactIds.remove(contact.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Text(contact.name[0].toUpperCase()),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return Consumer<GroupsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = provider.groups;

        if (groups.isEmpty) {
          return const Center(
            child: Text('No groups available'),
          );
        }

        return Column(
          children: [
            // Select all / Deselect all
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_selectedGroupIds.length} selected'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedGroupIds.addAll(
                              groups.map((g) => g.id),
                            );
                          });
                        },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedGroupIds.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = _selectedGroupIds.contains(group.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedGroupIds.add(group.id);
                        } else {
                          _selectedGroupIds.remove(group.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor: Colors.teal[300],
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    title: Text(group.name),
                    subtitle: Text('${group.memberCount} members'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendQuickMessage() async {
    final message = _messageController.text.trim();
    final phone = _phoneController.text.trim();

    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    if (phone.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    setState(() => _isSending = true);

    final success = await WhatsAppService.sendMessage(
      phoneNumber: phone,
      message: message,
    );

    setState(() => _isSending = false);

    if (!success) {
      _showError('Failed to open WhatsApp');
    }
  }

  Future<void> _sendToSelected() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    setState(() => _isSending = true);

    // Get selected contacts
    final contactsProvider = context.read<ContactsProvider>();
    final selectedContacts = contactsProvider.contacts
        .where((c) => _selectedContactIds.contains(c.id))
        .toList();

    // Send to each contact
    int successCount = 0;
    for (final contact in selectedContacts) {
      final success = await WhatsAppService.sendMessage(
        phoneNumber: contact.phoneNumber,
        message: message,
      );
      if (success) successCount++;
      
      // Small delay between messages
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent to $successCount of ${selectedContacts.length} contacts',
          ),
        ),
      );

      // Clear selections
      setState(() {
        _selectedContactIds.clear();
        _selectedGroupIds.clear();
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
