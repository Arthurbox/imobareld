import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';
import 'package:imobareld/models/review_model.dart';

/// Section avis clients de l'écran de détail.
/// Utilise un [FutureBuilder] et affiche un skeleton pendant le chargement.
class DetailReviewsSection extends StatelessWidget {
  final Future<List<ReviewModel>>? reviewsFuture;

  const DetailReviewsSection({super.key, required this.reviewsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewModel>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 3, itemHeight: 80);
        }
        if (snapshot.hasError) {
          debugPrint('Erreur d\'affichage des avis: ${snapshot.error}');
          return Text('Erreur: ${snapshot.error}');
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Text('Aucun avis pour le moment.');
        }

        return Column(
          children: reviews.map((review) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CachedAvatar(
                imageUrl: review.userProfilePicture,
                name: review.userName,
                radius: 20,
              ),
              title: Row(
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 14,
                        color: index < review.rating
                            ? Colors.orange
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(review.comment),
            );
          }).toList(),
        );
      },
    );
  }
}
