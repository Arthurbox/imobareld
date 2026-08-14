import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/bf_locations.dart';
import 'package:imobareld/features/admin/views/content/admin_immo_sub_view.dart';


// ===== VUE ADMIN : IMMOBILIER =====
class AdminContentView extends StatefulWidget {
  const AdminContentView({super.key});

  @override
  State<AdminContentView> createState() => _AdminContentViewState();
}

class _AdminContentViewState extends State<AdminContentView> {
  // 0 = Immobilier
  int _subIndex = 0;
  String _selectedCity = 'Toutes les villes';
  late PageController _pageController;

  static const List<String> _subLabels = ['Immobilier'];
  static const List<IconData> _subIcons = [
    Icons.apartment,
  ];
  bool _filterVideosOnly = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _subIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Barre de sous-catégories ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(_subLabels.length, (i) {
                  final selected = _subIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? theme.primaryColor : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? theme.primaryColor : theme.dividerColor,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _subIcons[i],
                              size: 16,
                              color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _subLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bouton Filtre Vidéos (Uniquement pour Immobilier)
              if (_subIndex == 0)
                GestureDetector(
                  onTap: () => setState(() => _filterVideosOnly = !_filterVideosOnly),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filterVideosOnly ? theme.primaryColor : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filterVideosOnly ? theme.primaryColor : theme.dividerColor,
                      ),
                      boxShadow: _filterVideosOnly
                          ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 4)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          size: 15,
                          color: _filterVideosOnly ? Colors.white : theme.primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Vidéos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _filterVideosOnly ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Sélecteur de ville
              GestureDetector(
                onTap: _showCitySelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: theme.primaryColor),
                      const SizedBox(width: 5),
                      Text(
                        _selectedCity,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 18, color: theme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Contenu selon la sous-catégorie ─────────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _subIndex = index);
            },
            children: [
              AdminImmoSubView(city: _selectedCity, filterVideosOnly: _filterVideosOnly),
            ],
          ),
        ),
      ],
    );
  }

  void _showCitySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionnez une ville'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: BfLocations.cities.length + 1,
            itemBuilder: (context, index) {
              final c = index == 0 ? 'Toutes les villes' : BfLocations.cities[index - 1];
              return ListTile(
                title: Text(
                  c,
                  style: TextStyle(
                    color: _selectedCity == c ? Theme.of(context).primaryColor : null,
                    fontWeight: _selectedCity == c ? FontWeight.bold : null,
                  ),
                ),
                trailing: _selectedCity == c
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor, size: 18)
                    : null,
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
}
