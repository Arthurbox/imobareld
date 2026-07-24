import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/responsive_layout.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/utils/app_page_route.dart';
import 'package:imobareld/core/widgets/offline_banner.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/shimmer_loading.dart';
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/core/constants/bf_locations.dart';

class SearchScreen extends StatefulWidget {
  final bool showFiltersInitially;
  final bool hideAppBar;
  const SearchScreen({
    super.key, 
    this.showFiltersInitially = false,
    this.hideAppBar = false,
  });

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedCategory = 'Tous';
  String _selectedCity = 'Toutes les villes';
  String _selectedQuartier = 'Tous';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  int _minPieces = 0;
  Set<String> _requiredAmenities = {};

  final List<String> _categories = [
    'Tous', 'Appartement', 'Cours Uniques', 'Cours Communes', 'Magasins', 'Boutiques', 'Terrains'
  ];

  /// L'option 'Toutes les villes' + toutes les villes du BF
  List<String> get _cities => ['Toutes les villes', ...BfLocations.cities];

  /// Quartiers disponibles selon la ville sélectionnée
  List<String> get _quartiers {
    if (_selectedCity == 'Toutes les villes') return ['Tous'];
    return ['Tous', ...BfLocations.quartiersOf(_selectedCity)];
  }

  /// Commodités filtrables affichées dans la fiche filtre
  final List<Map<String, dynamic>> _filterableAmenities = [
    {'label': 'Piscine', 'icon': Icons.pool},
    {'label': 'Parking', 'icon': Icons.local_parking},
    {'label': 'Wifi', 'icon': Icons.wifi},
    {'label': 'Climatisation', 'icon': Icons.ac_unit},
    {'label': 'Sécurité 24/7', 'icon': Icons.security},
    {'label': 'Sonabel', 'icon': Icons.lightbulb_outline},
    {'label': 'ONEA', 'icon': Icons.water_drop_outlined},
  ];

  bool get _hasActiveFilters =>
      _selectedCategory != 'Tous' ||
      _selectedCity != 'Toutes les villes' ||
      _selectedQuartier != 'Tous' ||
      _priceRange.start > 0 ||
      _priceRange.end < 1000000 ||
      _minPieces > 0 ||
      _requiredAmenities.isNotEmpty;

  Future<List<PropertyModel>>? _searchFuture;

  void _performSearch() {
    final controller = Provider.of<PropertyController>(context, listen: false);
    setState(() {
      _searchFuture = controller.getFilteredProperties(
        category: _selectedCategory,
        city: _selectedCity,
        quartier: _selectedQuartier,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        minPieces: _minPieces,
        requiredAmenities: _requiredAmenities.toList(),
        searchQuery: _searchController.text,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Tous';
      _selectedCity = 'Toutes les villes';
      _selectedQuartier = 'Tous';
      _priceRange = const RangeValues(0, 1000000);
      _minPieces = 0;
      _requiredAmenities = {};
    });
    _performSearch();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
      if (widget.showFiltersInitially && mounted) {
        showFilterOptions(context);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Rechercher un bien', style: TextStyle(color: AppColors.primaryBlue)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Réinitialiser', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
      body: ResponsiveLayout(
        child: OfflineBanner(
          child: Column(
            children: [
              // Barre de recherche et Bouton Filtre
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(const Duration(milliseconds: 600), () {
                              if (mounted) _performSearch();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Titre, quartier, description...',
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
                                  )
                                : null,
                          ),
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => showFilterOptions(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.tune, color: Colors.white),
                          ),
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
    
              // Chips des filtres actifs
              if (_hasActiveFilters) _buildActiveFilterChips(theme),
    
              Expanded(
                child: Consumer2<PropertyController, ConnectivityService>(
                  builder: (context, controller, connectivity, _) {
                    return FutureBuilder<List<PropertyModel>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && _searchFuture != null) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 5,
                            itemBuilder: (context, index) => PropertyCardShimmer(),
                          );
                        }
    
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Une erreur est survenue lors de la recherche',
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                ),
                                TextButton(
                                  onPressed: _performSearch,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          );
                        }
    
                        final properties = snapshot.data ?? [];
    
                        if (!snapshot.hasData && !connectivity.isOnline) {
                          return const OfflineEmptyState();
                        }
    
                        if (properties.isEmpty) {
                          return _buildEmptyState(theme);
                        }
    
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 700) {
                              int crossAxisCount = constraints.maxWidth > 1000 ? 2 : 2;
                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                cacheExtent: 1500,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 0, // margin is handled in the item
                                  mainAxisExtent: 155, // 120 image + paddings
                                ),
                                itemCount: properties.length,
                                itemBuilder: (context, index) {
                                  return AnimatedPropertyListItem(
                                    property: properties[index],
                                    index: index,
                                  );
                                },
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              cacheExtent: 1500, // PRÉ-CHARGEMENT pour fluidité extrême
                              itemCount: properties.length,
                              itemBuilder: (context, index) {
                                return AnimatedPropertyListItem(
                                  property: properties[index],
                                  index: index,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(ThemeData theme) {
    final chips = <Widget>[];

    if (_selectedCategory != 'Tous') {
      chips.add(_FilterChip(label: _selectedCategory, onRemove: () => setState(() => _selectedCategory = 'Tous')));
    }
    if (_selectedCity != 'Toutes les villes') {
      chips.add(_FilterChip(label: _selectedCity, onRemove: () => setState(() {
        _selectedCity = 'Toutes les villes';
        _selectedQuartier = 'Tous';
      })));
    }
    if (_selectedQuartier != 'Tous') {
      chips.add(_FilterChip(label: _selectedQuartier, onRemove: () => setState(() => _selectedQuartier = 'Tous')));
    }
    if (_minPieces > 0) {
      chips.add(_FilterChip(label: '≥ $_minPieces pièces', onRemove: () => setState(() => _minPieces = 0)));
    }
    if (_priceRange.start > 0 || _priceRange.end < 1000000) {
      chips.add(_FilterChip(
        label: '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} FCFA',
        onRemove: () => setState(() => _priceRange = const RangeValues(0, 1000000)),
      ));
    }
    for (final amenity in _requiredAmenities) {
      chips.add(_FilterChip(
        label: amenity,
        onRemove: () => setState(() => _requiredAmenities = Set.from(_requiredAmenities)..remove(amenity)),
      ));
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
          ),
          const SizedBox(height: 8),
          Text(
            'Modifiez vos filtres pour élargir la recherche',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser les filtres'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void showFilterOptions(BuildContext context) {
    final theme = Theme.of(context);
    // Copies locales pour le modal
    String localCategory = _selectedCategory;
    String localCity = _selectedCity;
    String localQuartier = _selectedQuartier;
    RangeValues localPriceRange = _priceRange;
    int localMinPieces = _minPieces;
    Set<String> localAmenities = Set.from(_requiredAmenities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poignée
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filtres avancés',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  localCategory = 'Tous';
                                  localQuartier = 'Tous';
                                  localPriceRange = const RangeValues(0, 1000000);
                                  localMinPieces = 0;
                                  localAmenities = {};
                                });
                              },
                              child: const Text('Tout effacer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        // ── Catégorie ──
                        _buildFilterSection(
                          theme,
                          icon: Icons.category_outlined,
                          title: 'Catégorie',
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: localCategory,
                            items: _categories.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                            )).toList(),
                            dropdownColor: theme.cardColor,
                            underline: Container(height: 1, color: theme.dividerColor),
                            onChanged: (value) => setModalState(() => localCategory = value!),
                          ),
                        ),

                        // ── Ville ──
                        _buildFilterSection(
                          theme,
                          icon: Icons.location_city_outlined,
                          title: 'Ville',
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: localCity,
                            items: _cities.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                            )).toList(),
                            dropdownColor: theme.cardColor,
                            underline: Container(height: 1, color: theme.dividerColor),
                            onChanged: (value) => setModalState(() {
                              localCity = value!;
                              localQuartier = 'Tous'; // reset quartier on city change
                            }),
                          ),
                        ),

                        // ── Quartier ──
                        _buildFilterSection(
                          theme,
                          icon: Icons.location_on_outlined,
                          title: 'Quartier',
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: localQuartier,
                            items: (localCity == 'Toutes les villes'
                              ? ['Tous']
                              : ['Tous', ...BfLocations.quartiersOf(localCity)]
                            ).map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                            )).toList(),
                            dropdownColor: theme.cardColor,
                            underline: Container(height: 1, color: theme.dividerColor),
                            onChanged: (value) => setModalState(() => localQuartier = value!),
                          ),
                        ),

                        // ── Prix ──
                        _buildFilterSection(
                          theme,
                          icon: Icons.attach_money_rounded,
                          title: 'Prix (FCFA) : ${localPriceRange.start.toInt()} – ${localPriceRange.end.toInt()}',
                          child: RangeSlider(
                            values: localPriceRange,
                            min: 0, max: 1000000, divisions: 20,
                            activeColor: AppColors.primaryBlue,
                            labels: RangeLabels(
                              localPriceRange.start.round().toString(),
                              localPriceRange.end.round().toString(),
                            ),
                            onChanged: (values) => setModalState(() => localPriceRange = values),
                          ),
                        ),

                        // ── Nombre de pièces ──
                        _buildFilterSection(
                          theme,
                          icon: Icons.king_bed_outlined,
                          title: 'Pièces minimum : $localMinPieces',
                          child: Slider(
                            value: localMinPieces.toDouble(),
                            min: 0, max: 10, divisions: 10,
                            activeColor: AppColors.primaryOrange,
                            label: localMinPieces.toString(),
                            onChanged: (value) => setModalState(() => localMinPieces = value.toInt()),
                          ),
                        ),

                        // ── Équipements ── (NEW)
                        _buildFilterSection(
                          theme,
                          icon: Icons.home_outlined,
                          title: 'Équipements souhaités',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _filterableAmenities.map((am) {
                              final label = am['label'] as String;
                              final icon = am['icon'] as IconData;
                              final isSelected = localAmenities.contains(label);
                              return GestureDetector(
                                onTap: () => setModalState(() {
                                  if (isSelected) {
                                    localAmenities = Set.from(localAmenities)..remove(label);
                                  } else {
                                    localAmenities = Set.from(localAmenities)..add(label);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryBlue : theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryBlue : theme.dividerColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))
                                    ] : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bouton Appliquer
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = localCategory;
                                _selectedCity = localCity;
                                _selectedQuartier = localQuartier;
                                _priceRange = localPriceRange;
                                _minPieces = localMinPieces;
                                _requiredAmenities = localAmenities;
                              });
                              _performSearch();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Appliquer les filtres',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(ThemeData theme, {required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.titleMedium?.color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Composants
// ─────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}

/// Item de liste animé avec délai d'index pour un effet cascade
class AnimatedPropertyListItem extends StatefulWidget {
  final PropertyModel property;
  final int index;

  const AnimatedPropertyListItem({super.key, required this.property, required this.index});

  @override
  State<AnimatedPropertyListItem> createState() => _AnimatedPropertyListItemState();
}

class _AnimatedPropertyListItemState extends State<AnimatedPropertyListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Décalage basé sur l'index pour effet cascade
    Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 300)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildPropertyCard(context),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context) {
    final theme = Theme.of(context);
    final property = widget.property;

    String formattedPrice = property.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} '
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          buildPropertyDetailRoute(PropertyDetailScreen(property: property)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Image avec Hero
            Hero(
              tag: 'prop_${property.id}_0',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: property.images.isNotEmpty
                      ? CachedImage(
                          imageUrl: property.images[0],
                          fit: BoxFit.cover,
                        )
                      : const ColoredBox(color: Color(0xFFEEEEEE), child: Icon(Icons.image_outlined, color: Colors.grey)),
                ),
              ),
            ),

            // Détails
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleLarge?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(property.quartier, style: const TextStyle(color: AppColors.textLight, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Badges
                    Wrap(
                      spacing: 4,
                      children: [
                        if (property.isCertified)
                          _buildBadge('✓ Certifié', Colors.purple),
                        if (property.isOwnerVerified)
                          _buildBadge('Vérifié', Colors.green),
                        _buildBadge(property.transactionType, AppColors.primaryBlue),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$formattedPrice FCFA',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer<AuthController>(
                              builder: (context, auth, _) {
                                final isFavorite = auth.currentUser?.favoritesIds.contains(property.id) ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 20,
                                    color: isFavorite ? Colors.red : AppColors.primaryBlue,
                                  ),
                                  onPressed: () => auth.toggleFavorite(property.id!),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${property.pieces} pcs',
                                style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

