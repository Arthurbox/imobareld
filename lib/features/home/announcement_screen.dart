import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/announcement_model.dart';
import 'package:imobareld/core/widgets/shimmer_loading.dart';
import 'announcement_controller.dart';

class AnnouncementScreen extends StatefulWidget {
  final bool hideAppBar;
  const AnnouncementScreen({super.key, this.hideAppBar = false});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  AnnouncementModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final controller = Provider.of<AnnouncementController>(context, listen: false);
      
      auth.updateLastReadAnnouncement();
      controller.fetchAnnouncements();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onReply(AnnouncementModel item) {
    setState(() {
      _replyingTo = item;
    });
  }

  Future<void> _handleRefresh() async {
    await Provider.of<AnnouncementController>(context, listen: false).fetchAnnouncements();
  }

  void _postMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final auth = Provider.of<AuthController>(context, listen: false);
    final controller = Provider.of<AnnouncementController>(context, listen: false);

    if (auth.currentUser == null) return;

    final newAnnouncement = AnnouncementModel(
      authorId: auth.currentUser!.id,
      authorName: auth.currentUser!.name,
      content: _messageController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await controller.postAnnouncement(newAnnouncement.copyWith(
      replyToId: _replyingTo?.id,
      replyToContent: _replyingTo?.content,
      replyToAuthorName: _replyingTo?.authorName,
    ));

    if (success) {
      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Échec de l'envoi de l'actualité"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Scroll vers le haut car les nouveaux messages sont en haut
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final controller = Provider.of<AnnouncementController>(context);

    final theme = Theme.of(context);
    final announcements = controller.announcements;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text('Annonces & Recherche', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color ?? AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveLayout(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<AnnouncementModel>>(
                stream: controller.announcementsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Align(
                          alignment: index % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
                          child: ShimmerLoading.rounded(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 80,
                            borderRadius: 16,
                          ),
                        ),
                      ),
                    );
                  }
    
                  final announcements = snapshot.data ?? [];
                  
                  if (announcements.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('Aucune annonce pour le moment.')),
                      ],
                    );
                  }
    
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final item = announcements[index];
                      final isMe = item.authorId == auth.currentUser?.id;
                      
                      // Assigner une clé pour le défilement
                      if (item.id != null) {
                        _messageKeys[item.id!] = GlobalKey();
                      }
                      
                      return Container(
                        key: item.id != null ? _messageKeys[item.id!] : null,
                        child: _buildAnnouncementBubble(item, isMe, controller),
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyingTo != null) _buildReplyPreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBubble(AnnouncementModel item, bool isMe, AnnouncementController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Dismissible(
      key: Key('announcement_${item.id ?? item.createdAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _onReply(item);
        }
        return false; // Prevent actual dismissal
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: AppColors.primaryBlue),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showOptionsDialog(item, controller, isMe),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryBlue : theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: isDark ? [] : AppColors.softShadow,
              border: isDark && !isMe ? Border.all(color: theme.dividerColor, width: 0.5) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.replyToId != null) _buildQuotedContent(item),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMe ? 'Moi' : item.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMe ? Colors.white70 : AppColors.primaryBlue,
                      ),
                    ),
                    if (!isMe)
                      GestureDetector(
                        onTap: () => _onReply(item),
                        child: const Icon(
                          Icons.reply,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white60 : AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToMessage(String? id) {
    if (id == null || !_messageKeys.containsKey(id)) return;
    final context = _messageKeys[id]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showOptionsDialog(AnnouncementModel item, AnnouncementController controller, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Que voulez-vous faire ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleMedium?.color),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.primaryBlue),
                title: Text('Répondre', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  _onReply(item);
                },
              ),
              if (isMe) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  title: Text('Modifier', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(item, controller);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: Text('Supprimer', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(item, controller);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(AnnouncementModel item, AnnouncementController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette annonce ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              controller.deleteAnnouncement(item.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Partagez une actualité avec la communauté...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: isDark ? const Color(0xFF2C2C2C) : AppColors.inputBackground,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _postMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(AnnouncementModel item, AnnouncementController controller) {
    final editController = TextEditingController(text: item.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'annonce'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              controller.editAnnouncement(item.id!, editController.text);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.9),
        border: const Border(left: BorderSide(color: AppColors.primaryBlue, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingTo!.authorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedContent(AnnouncementModel item) {
    bool isMe = item.authorId == Provider.of<AuthController>(context, listen: false).currentUser?.id;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _scrollToMessage(item.replyToId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1),
          border: Border(left: BorderSide(color: isMe ? Colors.white38 : AppColors.primaryBlue, width: 3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.replyToAuthorName ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isMe ? Colors.white70 : AppColors.primaryBlue,
              ),
            ),
            Text(
              item.replyToContent ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white60 : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
