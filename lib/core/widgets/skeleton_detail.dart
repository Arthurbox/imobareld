import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/skeleton_base.dart';

class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner/Image
          const SkeletonBase(width: double.infinity, height: 250, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const SkeletonBase(height: 28, width: 250),
                const SizedBox(height: 16),
                
                // Price & category
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBase(height: 24, width: 120),
                    SkeletonBase(height: 24, width: 100, borderRadius: 20),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Info row
                Row(
                  children: List.generate(3, (index) => const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: SkeletonBase(height: 60, borderRadius: 12),
                    ),
                  )),
                ),
                const SizedBox(height: 24),
                
                // Description title
                const SkeletonBase(height: 20, width: 150),
                const SizedBox(height: 12),
                
                // Description text lines
                const SkeletonBase(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBase(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBase(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBase(height: 14, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
