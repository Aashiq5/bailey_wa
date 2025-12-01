import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../models/contact.dart';
import '../services/whatsapp_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Contacts list
        Expanded(
          child: Consumer<ContactsProvider>(
            builder: (context, contactsProvider, child) {
              if (contactsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final contacts = contactsProvider.searchContacts(_searchQuery);

              if (contacts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No contacts found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: contacts.length + 1, // +1 for add contact button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddContactTile(context);
                  }
                  
                  final contact = contacts[index - 1];
                  return _buildContactTile(context, contact, contactsProvider);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddContactTile(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      title: const Text('Add new contact'),
      onTap: () => _showAddContactDialog(context),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    Contact contact,
    ContactsProvider provider,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(contact.name),
      subtitle: Text(contact.phoneNumber),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.isOnline)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.message, color: Color(0xFF25D366)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: contact.id,
                    chatName: contact.name,
                    phoneNumber: contact.phoneNumber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      onTap: () {
        _showContactOptions(context, contact, provider);
      },
    );
  }

  void _showContactOptions(
    BuildContext context,
    Contact contact,
    ContactsProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send message'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: contact.id,
                      chatName: contact.name,
                      phoneNumber: contact.phoneNumber,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open in WhatsApp'),
              onTap: () async {
                Navigator.pop(context);
                await WhatsAppService.openChat(contact.phoneNumber);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit contact'),
              onTap: () {
                Navigator.pop(context);
                _showEditContactDialog(context, contact, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete contact', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete contact?'),
                    content: Text('Are you sure you want to delete ${contact.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.deleteContact(contact.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1234567890',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final contact = Contact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                );
                context.read<ContactsProvider>().addContact(contact);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(
    BuildContext context,
    Contact contact,
    ContactsProvider provider,
  ) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final updatedContact = contact.copyWith(
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                );
                provider.updateContact(updatedContact);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
