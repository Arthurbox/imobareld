import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/constants/user_roles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/services/notification_service.dart';
import 'package:imobareld/features/home/ad_controller.dart';
import 'package:imobareld/features/home/add_property_screen.dart';
import 'package:imobareld/features/home/favorites_screen.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/comment_model.dart';
import 'package:imobareld/features/search/search_screen.dart';
import 'package:imobareld/features/owner/owner_dashboard.dart';
import 'package:imobareld/features/home/announcement_screen.dart';
import 'package:imobareld/features/profile/profile_screen.dart';
import 'package:imobareld/features/profile/my_boosts_screen.dart';
import 'package:imobareld/features/owner/subscription_screen.dart';
import 'package:imobareld/features/admin/admin_dashboard.dart';
import 'package:imobareld/features/home/announcement_controller.dart';
import 'package:imobareld/models/announcement_model.dart';
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/features/settings/legal_documents_screen.dart';
import 'package:imobareld/features/settings/about_us_screen.dart';
import 'package:imobareld/features/settings/contact_us_screen.dart';
import 'package:imobareld/features/owner/boost_plans_screen.dart';
import 'package:imobareld/features/home/widgets/property_section.dart';
import 'package:imobareld/features/home/widgets/notification_badge.dart';
import 'package:imobareld/features/home/widgets/announcement_badge.dart';
import 'package:imobareld/features/home/widgets/banner_carousel.dart';
import 'package:imobareld/features/home/widgets/category_scroll_bar.dart';
import 'package:imobareld/features/home/new_properties_screen.dart';

import 'package:imobareld/core/constants/bf_locations.dart';
import 'package:imobareld/core/widgets/responsive_layout.dart';
import 'package:imobareld/features/home/widgets/realisation_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Appartements';
  String _selectedCity = 'Ouagadougou';
  int _refreshKey = 0; // Incrémenté pour forcer le rechargement des sections

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SearchScreenState> _searchKey = GlobalKey();
  final Map<String, GlobalKey> _categoryKeys = {
    'Appartements': GlobalKey(),
    'Cours Uniques': GlobalKey(),
    'Cours Communes': GlobalKey(),
    'Magasins': GlobalKey(),
    'Boutiques': GlobalKey(),
    'Terrains': GlobalKey(),
  };

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.weekend_outlined, 'label': 'Appartements'},
    {'icon': Icons.home_outlined, 'label': 'Cours Uniques'},
    {'icon': Icons.groups_outlined, 'label': 'Cours Communes'},
    {'icon': Icons.storefront_outlined, 'label': 'Magasins'},
    {'icon': Icons.business_outlined, 'label': 'Boutiques'},
    {'icon': Icons.landscape_outlined, 'label': 'Terrains'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUser != null) {
        NotificationService().listenToMessages(auth.currentUser!.id);
      }
      // Charger les favoris au démarrage de l'application
      Provider.of<PropertyController>(context, listen: false).loadFavorites();
      // Charger les pubs dès le démarrage (cache local d'abord, puis Supabase)
      Provider.of<AdController>(context, listen: false).getActiveAds();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().currentUser;
    final isOwner = user?.isOwner ?? false;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _buildDrawer(context),
        appBar: _buildAppBar(context, theme),
        body: _buildResponsiveBody(context, theme),
        bottomNavigationBar: _buildResponsiveBottomNav(context, theme),
        floatingActionButton: Consumer<AuthController>(
          builder: (context, authController, _) {
            final isProprio = authController.currentUser != null &&
                authController.currentUser!.isOwner;
            if (!isProprio || _selectedIndex != 0)
              return const SizedBox.shrink();
            return _buildFAB(context);
          },
        ),
        floatingActionButtonLocation: _isWebLargeScreen(context)
            ? FloatingActionButtonLocation.endFloat
            : FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  /// Retourne true si on est sur le web ET que la largeur d'écran est >= 600px
  bool _isWebLargeScreen(BuildContext context) {
    return kIsWeb && MediaQuery.of(context).size.width >= 600;
  }

  /// Corps principal : NavigationRail à gauche sur grand écran web,
  /// sinon le body seul (mobile natif ou web en petite fenêtre)
  Widget _buildResponsiveBody(BuildContext context, ThemeData theme) {
    if (_isWebLargeScreen(context)) {
      return Row(
        children: [
          Consumer<AuthController>(
            builder: (context, auth, _) => _buildWebNavRail(context, theme, auth),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: ResponsiveLayout(child: _buildBody())),
        ],
      );
    }
    return ResponsiveLayout(child: _buildBody());
  }

  /// Barre de navigation du bas : affichée sur mobile natif
  /// ET sur web en petite fenêtre (< 600px) — comportement identique à mobile
  Widget? _buildResponsiveBottomNav(BuildContext context, ThemeData theme) {
    if (_isWebLargeScreen(context)) {
      // Grand écran web → navigation assurée par le NavigationRail
      return null;
    }
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final isProprio = authController.currentUser != null &&
            authController.currentUser!.isOwner;
        return _buildBottomNav(context, theme, isProprio);
      },
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeBody(),
        SearchScreen(key: _searchKey, hideAppBar: true),
        const AnnouncementScreen(hideAppBar: true),
        const ProfileScreen(hideAppBar: true),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        return SizedBox(
          width: kIsWeb ? 280 : MediaQuery.of(context).size.width * 0.75,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // ferme le drawer
                          setState(() => _selectedIndex = 3); // ouvre le profil
                        },
                        child: CachedAvatar(
                          imageUrl: user?.profilePicture,
                          name: user?.name,
                          radius: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Utilisateur',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user != null && user.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blue, size: 18),
                          ],
                        ],
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(Icons.home_outlined, 'Accueil', () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                }),
                if ((user?.isOwner ?? false) || (user?.isAdmin ?? false))
                  _buildDrawerItem(Icons.dashboard_outlined, 'Tableau de Bord', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
                  }),
                _buildDrawerItem(Icons.favorite_outline, 'Favoris', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                }),
                if ((user?.isOwner ?? false) || (user?.isAdmin ?? false))
                  _buildDrawerItem(Icons.rocket_launch_outlined, 'Booster', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner la propriété à booster depuis votre tableau de bord.')),
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
                  }),
                if ((user?.isOwner ?? false) || (user?.isAdmin ?? false))
                  _buildDrawerItem(Icons.flash_on, 'Mes Boostes', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBoostsScreen()));
                  }),
                if ((user?.isOwner ?? false) || (user?.isAdmin ?? false))
                  _buildDrawerItem(Icons.card_membership, 'Abonnement', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                  }),


                _buildDrawerItem(Icons.description_outlined, 'Conditions Générales', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LegalDocumentsScreen(isTermsOfService: true)));
                }),
                _buildDrawerItem(Icons.privacy_tip_outlined, 'Politique de confidentialité', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LegalDocumentsScreen(isTermsOfService: false)));
                }),
                _buildDrawerItem(Icons.contact_support_outlined, 'Contactez-nous', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
                }),
                const Divider(),
                if (user?.isAdmin ?? false)
                  _buildDrawerItem(Icons.admin_panel_settings, 'Panneau Admin', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                  }, color: Colors.purple),
                const Divider(),
                _buildDrawerItem(Icons.logout, 'Déconnexion', () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }, color: Colors.redAccent),
                
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suivez-nous sur', 
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        )
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse('https://web.facebook.com/profile.php?id=61591986731308')),
                            child: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2), size: 28),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse('https://www.tiktok.com/@imobareld?_r=1&_t=ZS-95A3QbVS2q0')),
                            child: FaIcon(
                              FontAwesomeIcons.tiktok, 
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
                              size: 28
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse('https://www.youtube.com/@IMOBARELD')),
                            child: const FaIcon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000), size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryBlue),
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: color != null ? FontWeight.bold : null)),
      onTap: onTap,
    );
  }

  /// Barre de navigation latérale pour le Web
  Widget _buildWebNavRail(BuildContext context, ThemeData theme, AuthController auth) {
    final user = auth.currentUser;
    final isOwner = user?.isOwner ?? false;
    final isAdmin = user?.isAdmin ?? false;

    // Onglets toujours visibles
    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Accueil'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: Text('Recherche'),
      ),
      NavigationRailDestination(
        icon: AnnouncementBadge(child: const Icon(Icons.campaign_outlined)),
        selectedIcon: AnnouncementBadge(child: const Icon(Icons.campaign)),
        label: const Text('Annonces'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Profil'),
      ),
    ];

    return NavigationRail(
      extended: MediaQuery.of(context).size.width > 1100,
      backgroundColor: theme.cardColor,
      selectedIndex: _selectedIndex.clamp(0, 3),
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _searchKey.currentState?.showFilterOptions(context);
          });
        }
        if (index == 2) {
          Provider.of<AuthController>(context, listen: false)
              .updateLastReadAnnouncement();
        }
      },
      selectedIconTheme: IconThemeData(color: AppColors.primaryBlue),
      unselectedIconTheme: IconThemeData(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
      selectedLabelTextStyle:
          TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle:
          TextStyle(color: theme.textTheme.bodyMedium?.color),
      useIndicator: true,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      destinations: destinations,
      leading: const SizedBox(height: 8),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                if (isOwner || isAdmin)
                  _buildRailTrailingItem(
                    context,
                    Icons.dashboard_outlined,
                    'Tableau de bord',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OwnerDashboard()),
                    ),
                    extended: MediaQuery.of(context).size.width > 1100,
                  ),

                if (isAdmin)
                  _buildRailTrailingItem(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'Admin',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboard()),
                    ),
                    extended: MediaQuery.of(context).size.width > 1100,
                    color: Colors.purple,
                  ),
                _buildRailTrailingItem(
                  context,
                  Icons.logout,
                  'Déconnexion',
                  () {
                    auth.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  extended: MediaQuery.of(context).size.width > 1100,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailTrailingItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool extended = false,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primaryBlue;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: extended
              ? Row(
                  children: [
                    Icon(icon, size: 22, color: effectiveColor),
                    const SizedBox(width: 16),
                    Text(label,
                        style: TextStyle(
                            color: effectiveColor,
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : Icon(icon, size: 22, color: effectiveColor),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Menu principal',
          icon: const Icon(Icons.menu, color: AppColors.primaryBlue),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Consumer<AuthController>(
        builder: (context, authController, _) {
          final user = authController.currentUser;
          String title;
          switch (_selectedIndex) {
            case 1: title = 'Recherche'; break;
            case 2: title = 'Annonces'; break;
            case 3: title = 'Mon Profil'; break;
            default: title = ''; // Will show welcome message
          }
          
          if (_selectedIndex != 0) {
            return Text(title, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold));
          }
          final userName = user?.name ?? 'Utilisateur';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bienvenue,', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userName, 
                        style: const TextStyle(color: AppColors.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (user != null && user.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ],
              ),
            ],
          );
        },
      ),
      actions: _selectedIndex == 0 ? [
        _buildConnectivityIndicator(),
        IconButton(
          tooltip: 'Recherche avancée',
          icon: const Icon(Icons.search, color: AppColors.primaryBlue),
          onPressed: () => setState(() => _selectedIndex = 1),
        ),
        NotificationBadge(
          child: IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primaryBlue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPropertiesScreen()));
              Provider.of<AuthController>(context, listen: false).updateLastReadProperties();
            },
          ),
        ),
      ] : [
        _buildConnectivityIndicator(),
      ],
    );
  }

  Widget _buildConnectivityIndicator() {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (!connectivity.isOnline) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Hors ligne', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHomeBody() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshKey++);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CARROUSEL DE PUBLICITÉS
            // Utilise Consumer<AdController> + activeAds (ChangeNotifier)
            // Le listener connectivité dans AdController force un notifyListeners()
            // depuis le cache SQLite dès que la connexion est perdue → pas besoin d'actualiser
            Consumer<AdController>(
              builder: (context, adController, _) => BannerCarousel(
                ads: adController.activeAds,
                isLoading: adController.isLoading && adController.activeAds.isEmpty,
                onAdTap: (ad) {
                  if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) {
                    launchUrl(Uri.parse(ad.targetUrl!));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. SECTION DERNIÈRES ANNONCES SUPPRIMÉE
            CategoryScrollBar(
              categories: _categories,
              selectedCategory: _selectedCategory,
              categoryKeys: _categoryKeys,
              onCategorySelected: (cat) {
                setState(() => _selectedCategory = cat);
                final key = _categoryKeys[cat];
                if (key?.currentContext != null) {
                  final rb = key!.currentContext!.findRenderObject() as RenderBox;
                  final ancestor = _scrollController.position.context.storageContext.findRenderObject();
                  if (ancestor != null) {
                    final offset = rb.localToGlobal(Offset.zero, ancestor: ancestor);
                    _scrollController.animateTo(
                      (_scrollController.offset + offset.dy - 120.0).clamp(0.0, _scrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
            ),
            _buildFilters(),
            SizedBox(key: _categoryKeys['Appartements'], child: PropertySection(key: ValueKey('Appartements_${_selectedCity}_$_refreshKey'), title: 'Appartements', category: 'Appartements', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            SizedBox(key: _categoryKeys['Cours Uniques'], child: PropertySection(key: ValueKey('CoursUniques_${_selectedCity}_$_refreshKey'), title: 'Cours Uniques', category: 'Cours Uniques', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            SizedBox(key: _categoryKeys['Cours Communes'], child: PropertySection(key: ValueKey('CoursCommunes_${_selectedCity}_$_refreshKey'), title: 'Cours Communes', category: 'Cours Communes', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            SizedBox(key: _categoryKeys['Magasins'], child: PropertySection(key: ValueKey('Magasins_${_selectedCity}_$_refreshKey'), title: 'Magasins', category: 'Magasins', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            SizedBox(key: _categoryKeys['Boutiques'], child: PropertySection(key: ValueKey('Boutiques_${_selectedCity}_$_refreshKey'), title: 'Boutiques', category: 'Boutiques', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            SizedBox(key: _categoryKeys['Terrains'], child: PropertySection(key: ValueKey('Terrains_${_selectedCity}_$_refreshKey'), title: 'Terrains', category: 'Terrains', city: _selectedCity, onCommentTap: (p) => _showCommentSheet(context, p))),
            const RealisationSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showFilterBottomSheet(),
            icon: const Icon(Icons.tune, size: 20),
            label: const Text('Filtre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _showCitySelector(),
            icon: const Icon(Icons.location_on_outlined, size: 20),
            label: Text(_selectedCity),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Publier un bien',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: AppColors.primaryOrange,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, ThemeData theme, bool isProprio) {
    return BottomAppBar(
      shape: isProprio ? const CircularNotchedRectangle() : null,
      notchMargin: 6,
      color: theme.bottomAppBarTheme.color ?? theme.cardColor,
      child: SizedBox(
        height: 60,
        child: isProprio
            ? Row(
                children: [
                  // Groupe gauche — pousse vers l'extrémité gauche
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.home, 'Accueil')),
                        Expanded(child: _buildNavItem(1, Icons.tune, 'Filtre')),
                      ],
                    ),
                  ),
                  // Espace réservé pour le FAB au centre (taille FAB 60 + 2×notchMargin)
                  const SizedBox(width: 72),
                  // Groupe droite — pousse vers l'extrémité droite
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: AnnouncementBadge(child: _buildNavItem(2, Icons.campaign_outlined, 'Annonce'))),
                        Expanded(child: _buildNavItem(3, Icons.person_outline, 'Profil')),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: Center(child: _buildNavItem(0, Icons.home, 'Accueil'))),
                  Expanded(child: Center(child: _buildNavItem(1, Icons.tune, 'Filtre'))),
                  Expanded(child: Center(child: AnnouncementBadge(child: _buildNavItem(2, Icons.campaign_outlined, 'Annonce')))),
                  Expanded(child: Center(child: _buildNavItem(3, Icons.person_outline, 'Profil'))),
                ],
              ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Tooltip(
      message: label,
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minWidth: 40,
        onPressed: () {
          // Basculer vers l'onglet
          setState(() => _selectedIndex = index);
          
          if (index == 1) {
            // Attendre que l'IndexedStack ait fini de rendre la SearchScreen
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _searchKey.currentState?.showFilterOptions(context);
              }
            });
          }
          
          if (index == 2) {
            // Marquer les annonces comme lues
            Provider.of<AuthController>(context, listen: false).updateLastReadAnnouncement();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color),
            Text(
              label, 
              style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Text('Commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: Provider.of<PropertyController>(context, listen: false).getCommentsStream(property.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) return const Center(child: Text('Aucun commentaire pour le moment'));
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CachedAvatar(
                            imageUrl: comment.authorProfilePicture,
                            name: comment.authorName,
                            radius: 20,
                          ),
                          title: Text(comment.authorName), subtitle: Text(comment.content),
                          trailing: Text(comment.createdAt.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 10)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 8),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: commentController, decoration: InputDecoration(hintText: 'Ajouter un commentaire...', filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : AppColors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)))),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.send, color: AppColors.primaryBlue), onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;
                      final auth = Provider.of<AuthController>(context, listen: false);
                      if (auth.currentUser == null) return;
                      final newComment = CommentModel(propertyId: property.id!, authorId: auth.currentUser!.id, authorName: auth.currentUser!.name, content: commentController.text.trim(), createdAt: DateTime.now());
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
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Basculer vers l'onglet Recherche puis ouvrir le panneau de filtres
    setState(() => _selectedIndex = 1);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchKey.currentState?.showFilterOptions(context);
      }
    });
  }

  void _showCitySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionnez une ville'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite, height: 400,
          child: ListView.builder(
            itemCount: BfLocations.cities.length,
            itemBuilder: (context, index) {
              final c = BfLocations.cities[index];
              return ListTile(
                title: Text(c, style: TextStyle(color: _selectedCity == c ? Theme.of(context).primaryColor : null, fontWeight: _selectedCity == c ? FontWeight.bold : null)),
                onTap: () { 
                  setState(() => _selectedCity = c); 
                  Navigator.pop(context); 
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String profilePicture) {
    return CachedAvatar(
      imageUrl: profilePicture,
      name: Provider.of<AuthController>(context, listen: false).currentUser?.name,
      radius: 30,
    );
  }
}

