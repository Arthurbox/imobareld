import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/skeleton_base.dart';

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool isGrid;
  final bool isHorizontal;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.isGrid = false,
    this.isHorizontal = false,
    this.itemHeight = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => _buildGridItem(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      itemCount: itemCount,
      itemBuilder: (_, __) => isHorizontal ? _buildHorizontalItem() : _buildListItem(),
    );
  }

  Widget _buildListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: itemHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBase(width: 100, height: 100, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBase(height: 20, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBase(height: 16, width: 150),
                const SizedBox(height: 16),
                const SkeletonBase(height: 16, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHorizontalItem() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBase(width: 160, height: 120, borderRadius: 12),
          const SizedBox(height: 8),
          const SkeletonBase(height: 16, width: double.infinity),
          const SizedBox(height: 4),
          const SkeletonBase(height: 14, width: 100),
        ],
      ),
    );
  }

  Widget _buildGridItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: SkeletonBase(width: double.infinity, height: double.infinity, borderRadius: 12)),
        const SizedBox(height: 8),
        const SkeletonBase(height: 16, width: double.infinity),
        const SizedBox(height: 4),
        const SkeletonBase(height: 14, width: 100),
      ],
    );
  }
}
