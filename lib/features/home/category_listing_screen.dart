import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/shimmer_loading.dart';
import 'package:imobareld/core/widgets/property_card.dart';
import 'package:imobareld/features/auth/auth_controller.dart' as import_auth;
import 'package:imobareld/models/comment_model.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

class CategoryListingScreen extends StatefulWidget {
  final String category;
  final String? city;

  const CategoryListingScreen({super.key, required this.category, this.city});

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<PropertyModel>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = Provider.of<PropertyController>(context, listen: false)
        .getFilteredProperties(category: widget.category, city: widget.city);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.category, style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: FutureBuilder<List<PropertyModel>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: PropertyCardShimmer(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Erreur: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(child: Text("Aucune annonce trouvée."));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            cacheExtent: 1500, // PRÉ-CHARGEMENT pour une fluidité maximale
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return Container(
                height: 260,
                margin: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(
                  property: properties[index],
                  onCommentTap: () => _showCommentSheet(context, properties[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCommentSheet(BuildContext context, PropertyModel property) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: Provider.of<PropertyController>(context, listen: false).getCommentsStream(property.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList(itemCount: 4, itemHeight: 70);
                    if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) return const Center(child: Text('Aucun commentaire pour le moment'));
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            backgroundImage: (comment.authorProfilePicture != null && comment.authorProfilePicture!.isNotEmpty)
                                    ? NetworkImage(comment.authorProfilePicture!)
                                    : null,
                            child: (comment.authorProfilePicture == null || comment.authorProfilePicture!.isEmpty)
                                ? Text(comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Text(comment.authorName),
                          subtitle: Text(comment.content),
                          trailing: Text(comment.createdAt.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 10)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;
                        // On doit importer auth_controller et comment_model
                        final auth = Provider.of<import_auth.AuthController>(context, listen: false);
                        if (auth.currentUser == null) return;
                        final newComment = CommentModel(
                          propertyId: property.id!,
                          authorId: auth.currentUser!.id,
                          authorName: auth.currentUser!.name,
                          content: commentController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        final success = await Provider.of<PropertyController>(context, listen: false).addComment(newComment);
                        if (success) {
                          commentController.clear();
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Échec de l'envoi du commentaire"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

