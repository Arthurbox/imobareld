import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/utils/app_page_route.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/property_card.dart';
import 'package:imobareld/core/widgets/shimmer_loading.dart';
import 'package:imobareld/core/widgets/error_retry_widget.dart';
import 'package:imobareld/features/home/category_listing_screen.dart';

class CitySection extends StatelessWidget {
  final String title;
  final String city;
  final Function(PropertyModel) onCommentTap;

  const CitySection({
    super.key,
    required this.title,
    required this.city,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PropertyController>(
      builder: (context, propertyController, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          page: CategoryListingScreen(
                            category: 'Toutes', 
                            city: city,
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
            FutureBuilder<List<PropertyModel>>(
              future: propertyController.getFilteredProperties(
                city: city,
                limit: 5,
              ),
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
                      onRetry: () {},
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink(); // Ne pas afficher la section si vide
                }

                final properties = snapshot.data!;
                return SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: PropertyCard(
                            property: properties[index],
                            onCommentTap: () => onCommentTap(properties[index]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
