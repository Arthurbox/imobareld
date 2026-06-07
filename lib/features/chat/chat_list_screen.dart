import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/chat/chat_controller.dart';
import 'package:imobareld/features/chat/chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mes Messages', style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: const ChatListContent(),
    );
  }
}

class ChatListContent extends StatefulWidget {
  const ChatListContent({super.key});

  @override
  State<ChatListContent> createState() => _ChatListContentState();
}

class _ChatListContentState extends State<ChatListContent> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthController>(context);
    final chatController = Provider.of<ChatController>(context);

    if (auth.currentUser == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 20,
      color: theme.primaryColor,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: chatController.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text('Aucune conversation en cours.')),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherUserId = conv['id'] as String;
              final otherUserName = conv['other_user_name'] as String? ?? 'Utilisateur';
              final otherUserPicture = conv['other_user_picture'] as String?;
              final lastMessage = conv['last_message'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: theme.brightness == Brightness.dark ? [] : AppColors.softShadow,
                ),
                child: ListTile(
                  leading: CachedAvatar(
                    imageUrl: otherUserPicture,
                    name: otherUserName,
                    radius: 20,
                  ),
                  title: Text(otherUserName, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          otherUserId: otherUserId,
                          otherUserName: otherUserName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

}

