import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/skeleton_base.dart';

class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = screenWidth > 800 ? 300.0 : 220.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SkeletonBase(
        width: double.infinity,
        height: bannerHeight,
        borderRadius: 20,
      ),
    );
  }
}
