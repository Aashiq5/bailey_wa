import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';
import '../services/background_service.dart';
import 'contacts_screen.dart';
import 'groups_screen.dart';
import 'chat_screen.dart';
import 'send_message_screen.dart';
import '../widgets/chat_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _manualRefresh() async {
    await BackgroundService.manualCheck();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messages checked!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bailey WA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualRefresh,
            tooltip: 'Check messages now',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Text('Help'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'CONTACTS'),
            Tab(text: 'GROUPS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          const ContactsScreen(),
          const GroupsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendMessageScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildChatsTab() {
    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, child) {
        if (messagesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messagesProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${messagesProvider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: messagesProvider.loadChats,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final chats = messagesProvider.chats;

        if (chats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await messagesProvider.loadChats();
          },
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatTile(
                chat: chat,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chat.id,
                        chatName: chat.name,
                        isGroup: chat.isGroup,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bailey WA Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tap on a chat to open conversation'),
            SizedBox(height: 8),
            Text('• Use the message button to send new messages'),
            SizedBox(height: 8),
            Text('• Messages are checked hourly automatically'),
            SizedBox(height: 8),
            Text('• Pull down to refresh chats'),
            SizedBox(height: 8),
            Text('• Use the refresh button to check messages now'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
