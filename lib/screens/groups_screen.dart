import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/groups_provider.dart';
import '../models/group.dart';
import 'chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
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
              hintText: 'Search groups...',
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
        
        // Groups list
        Expanded(
          child: Consumer<GroupsProvider>(
            builder: (context, groupsProvider, child) {
              if (groupsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = groupsProvider.searchGroups(_searchQuery);

              if (groups.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No groups found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: groups.length + 1, // +1 for create group button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreateGroupTile(context);
                  }
                  
                  final group = groups[index - 1];
                  return _buildGroupTile(context, group, groupsProvider);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupTile(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      title: const Text('Create new group'),
      onTap: () => _showCreateGroupDialog(context),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    Group group,
    GroupsProvider provider,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal[300],
        child: const Icon(Icons.group, color: Colors.white),
      ),
      title: Text(group.name),
      subtitle: Text(
        group.description ?? '${group.memberCount} members',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.message, color: Color(0xFF25D366)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: group.id,
                chatName: group.name,
                isGroup: true,
              ),
            ),
          );
        },
      ),
      onTap: () {
        _showGroupOptions(context, group, provider);
      },
    );
  }

  void _showGroupOptions(
    BuildContext context,
    Group group,
    GroupsProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Open chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: group.id,
                      chatName: group.name,
                      isGroup: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Group info'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfoDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit group'),
              onTap: () {
                Navigator.pop(context);
                _showEditGroupDialog(context, group, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Delete group', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete group?'),
                    content: Text('Are you sure you want to delete "${group.name}"?'),
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
                  await provider.deleteGroup(group.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfoDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(group.description!),
              const SizedBox(height: 16),
            ],
            Text(
              'Members: ${group.memberCount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(group.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (nameController.text.isNotEmpty) {
                final group = Group(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  createdAt: DateTime.now(),
                );
                context.read<GroupsProvider>().addGroup(group);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(
    BuildContext context,
    Group group,
    GroupsProvider provider,
  ) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (nameController.text.isNotEmpty) {
                final updatedGroup = group.copyWith(
                  name: nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );
                provider.updateGroup(updatedGroup);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
