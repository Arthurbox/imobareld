import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerLoading.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = 12,
  }) : shapeBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Fix: Use min size
        children: [
          ShimmerLoading.rounded(
            height: 140, // Reduced from 160 to fit within 250px total
            borderRadius: 15,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerLoading.rectangular(height: 14, width: 150),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerLoading.rounded(height: 18, width: 60, borderRadius: 20),
                    const SizedBox(width: 8),
                    ShimmerLoading.rounded(height: 18, width: 80, borderRadius: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerLoading.rectangular(height: 14, width: 100),
                    Row(
                      children: const [
                        ShimmerLoading.circular(height: 24, width: 24),
                        SizedBox(width: 8),
                        ShimmerLoading.circular(height: 24, width: 24),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleCardShimmer extends StatelessWidget {
  const VehicleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading.rounded(
            height: 100,
            borderRadius: 12,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading.rectangular(height: 12, width: 100),
                const SizedBox(height: 4),
                const ShimmerLoading.rectangular(height: 10, width: 120),
                const SizedBox(height: 8),
                ShimmerLoading.rounded(height: 24, borderRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
