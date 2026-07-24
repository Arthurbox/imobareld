import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/skeleton_base.dart';

class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const SkeletonBase(
        width: double.infinity,
        height: 220,
        borderRadius: 20,
      ),
    );
  }
}
