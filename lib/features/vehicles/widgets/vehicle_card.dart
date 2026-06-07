import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/models/vehicle_model.dart';

/// VehicleCard affiche les informations essentielles d'un véhicule.

/// VehicleCard avec décodage base64 en arrière-plan via compute()
class VehicleCard extends StatefulWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String imageUrl = widget.vehicle.imageUrl;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Nom de l'entreprise
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
              child: Text(
                widget.vehicle.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.indigo,
                ),
              ),
            ),
            const Divider(height: 1),
            // Corps : Image + Détails
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (Gauche)
                  GestureDetector(
                    onTap: widget.onTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 160,
                        height: 115,
                        child: imageUrl.isEmpty 
                          ? const Center(child: Icon(Icons.directions_car, size: 40, color: Colors.grey))
                          : CachedImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Détails (Droite)
                  Expanded(
                    child: SizedBox(
                      height: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Modèle :",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Text(
                            widget.vehicle.model,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Prix
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isDark ? Colors.white30 : Colors.grey),
                                  ),
                                  child: Text(
                                    "${widget.vehicle.pricePerDay.toStringAsFixed(0)} F/jour",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bouton Détail
                              InkWell(
                                onTap: widget.onTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Text(
                                    "Détail",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

