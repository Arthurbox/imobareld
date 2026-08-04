import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/property_model.dart';

/// Section carte de l'écran de détail. Affiche une Google Map sur mobile
/// et un placeholder cliquable sur Web. Retourne [SizedBox.shrink()] si
/// les coordonnées GPS sont manquantes.
class DetailMapSection extends StatelessWidget {
  final PropertyModel property;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onLaunchNavigation;

  const DetailMapSection({
    super.key,
    required this.property,
    required this.onMapCreated,
    required this.onLaunchNavigation,
  });

  @override
  Widget build(BuildContext context) {
    if (property.latitude == null || property.longitude == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emplacement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),

        // ── Fallback Web ──
        if (kIsWeb)
          GestureDetector(
            onTap: onLaunchNavigation,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.cardColor,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: AppColors.primaryBlue),
                  const SizedBox(height: 12),
                  Text(
                    '${property.latitude!.toStringAsFixed(5)}, ${property.longitude!.toStringAsFixed(5)}',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onLaunchNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Voir sur Google Maps'),
                  ),
                ],
              ),
            ),
          )

        // ── Google Map native ──
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(property.latitude!, property.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: LatLng(property.latitude!, property.longitude!),
                        infoWindow: InfoWindow(
                          title: property.title,
                          snippet: property.quartier,
                        ),
                      ),
                    },
                    onMapCreated: onMapCreated,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: onLaunchNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.navigation, color: Colors.white, size: 16),
                    label: const Text(
                      'Itinéraire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}
