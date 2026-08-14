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

  const CategoryListingScreen(
      {super.key, required this.category, this.city});

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger la première page au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PropertyController>(context, listen: false)
          .fetchPagedProperties(refresh: true, category: widget.category);
    });
    // Détecter quand l'utilisateur approche du bas de la liste
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.offset >= threshold) {
      final ctrl = Provider.of<PropertyController>(context, listen: false);
      if (ctrl.hasMore && !ctrl.isFetchingMore) {
        ctrl.fetchPagedProperties(category: widget.category);
      }
    }
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
        title: Text(
          widget.category,
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Consumer<PropertyController>(
        builder: (context, controller, _) {
          final properties = controller.pagedProperties;

          // ── Premier chargement ──────────────────────────────────────────
          if (controller.isFetchingMore && properties.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: PropertyCardShimmer(),
              ),
            );
          }

          // ── Liste vide ──────────────────────────────────────────────────
          if (!controller.isFetchingMore && properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune annonce trouvée\ndans cette catégorie.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          // ── Liste paginée ───────────────────────────────────────────────
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Tablette / Web : grille
                final int crossCount = constraints.maxWidth > 900 ? 3 : 2;
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PropertyCard(
                            property: properties[index],
                            onCommentTap: () =>
                                _showCommentSheet(context, properties[index]),
                          ),
                          childCount: properties.length,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 260,
                        ),
                      ),
                    ),
                    _buildFooterSliver(context, controller),
                  ],
                );
              }

              // Mobile : liste verticale
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Container(
                          height: 260,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: PropertyCard(
                            property: properties[index],
                            onCommentTap: () =>
                                _showCommentSheet(context, properties[index]),
                          ),
                        ),
                        childCount: properties.length,
                      ),
                    ),
                  ),
                  _buildFooterSliver(context, controller),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Sliver de pied de liste ─────────────────────────────────────────────
  Widget _buildFooterSliver(
      BuildContext context, PropertyController controller) {
    if (controller.isFetchingMore && controller.pagedProperties.isNotEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!controller.hasMore && controller.pagedProperties.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Toutes les annonces sont affichées',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // ── Fiche de commentaires ───────────────────────────────────────────────
  void _showCommentSheet(BuildContext context, PropertyModel property) {
    final TextEditingController commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Commentaires',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // Liste des commentaires
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: Provider.of<PropertyController>(ctx,
                          listen: false)
                      .getCommentsStream(property.id!),
                  builder: (ctx2, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SkeletonList(
                          itemCount: 4, itemHeight: 70);
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Erreur: ${snapshot.error}'));
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Center(
                          child:
                              Text('Aucun commentaire pour le moment'));
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final c = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(ctx2).primaryColor.withValues(alpha: 0.1),
                            backgroundImage: (c.authorProfilePicture !=
                                        null &&
                                    c.authorProfilePicture!.isNotEmpty)
                                ? NetworkImage(c.authorProfilePicture!)
                                : null,
                            child: (c.authorProfilePicture == null ||
                                    c.authorProfilePicture!.isEmpty)
                                ? Text(c.authorName.isNotEmpty
                                    ? c.authorName[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                          title: Text(c.authorName),
                          subtitle: Text(c.content),
                          trailing: Text(
                            c.createdAt
                                .toIso8601String()
                                .substring(0, 10),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Champ d'envoi
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(ctx).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          filled: true,
                          fillColor: Theme.of(ctx).brightness ==
                                  Brightness.dark
                              ? Colors.white12
                              : const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send,
                          color: Theme.of(ctx).primaryColor),
                      onPressed: () async {
                        if (commentCtrl.text.trim().isEmpty) return;
                        final auth =
                            Provider.of<import_auth.AuthController>(
                                ctx,
                                listen: false);
                        if (auth.currentUser == null) return;
                        final newComment = CommentModel(
                          propertyId: property.id!,
                          authorId: auth.currentUser!.id,
                          authorName: auth.currentUser!.name,
                          content: commentCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        final success =
                            await Provider.of<PropertyController>(
                                    ctx,
                                    listen: false)
                                .addComment(newComment);
                        if (success) {
                          commentCtrl.clear();
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Échec de l'envoi du commentaire"),
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
