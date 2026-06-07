import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool usePadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && 
        Theme.of(context).platform != TargetPlatform.windows && 
        Theme.of(context).platform != TargetPlatform.linux && 
        Theme.of(context).platform != TargetPlatform.macOS) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) {
          return child;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (constraints.maxWidth > maxWidth + 40)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: ClipRRect(
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
