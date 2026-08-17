import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/utils/app_page_route.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/property_card.dart';
import 'package:imobareld/core/widgets/shimmer_loading.dart';
import 'package:imobareld/core/widgets/error_retry_widget.dart';
import 'package:imobareld/features/home/category_listing_screen.dart';

class PropertySection extends StatefulWidget {
  final String title;
  final String category;
  final String? city;
  final Function(PropertyModel) onCommentTap;

  const PropertySection({
    super.key,
    required this.title,
    required this.category,
    this.city,
    required this.onCommentTap,
  });

  @override
  State<PropertySection> createState() => _PropertySectionState();
}

class _PropertySectionState extends State<PropertySection> {
  late Stream<List<PropertyModel>> _propertiesStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final propertyController = Provider.of<PropertyController>(context, listen: false);
    _propertiesStream = propertyController.getPropertiesForSectionStream(
      category: widget.category,
      city: widget.city,
      limit: 20,
    );
  }

  @override
  void didUpdateWidget(PropertySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category || oldWidget.city != widget.city) {
      setState(() {
        _initStream();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          page: CategoryListingScreen(
                            category: widget.category,
                            city: widget.city,
                          ),
                          transition: RouteTransition.slideUp,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Voir plus',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<PropertyModel>>(
              stream: _propertiesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) => const PropertyCardShimmer(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 250,
                    child: ErrorRetryWidget(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _initStream();
                        });
                      },
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: Text(
                        'Aucune annonce disponible',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    ),
                  );
                }

                final properties = snapshot.data!;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      final displayProperties = properties.take(8).toList();
                      int crossAxisCount = constraints.maxWidth > 900 ? 4 : 3;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 260,
                          ),
                          itemCount: displayProperties.length,
                          itemBuilder: (context, index) {
                            return PropertyCard(
                              property: displayProperties[index],
                              onCommentTap: () => widget.onCommentTap(displayProperties[index]),
                            );
                          },
                        ),
                      );
                    }
                    return SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final cardWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.85;
                          return SizedBox(
                            width: cardWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: PropertyCard(
                                property: properties[index],
                                onCommentTap: () => widget.onCommentTap(properties[index]),
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
          ],
        );
  }
}
