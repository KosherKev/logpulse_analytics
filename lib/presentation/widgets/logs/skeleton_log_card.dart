import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shimmer-style skeleton placeholder matching the shape of [EnhancedLogCard].
/// Used during loadMore() instead of a bottom spinner.
class SkeletonLogCard extends StatefulWidget {
  const SkeletonLogCard({super.key});

  @override
  State<SkeletonLogCard> createState() => _SkeletonLogCardState();
}

class _SkeletonLogCardState extends State<SkeletonLogCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final shimmerColor = c.border.withValues(alpha: _shimmerAnim.value);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: shimmerColor, width: 3),
              top: BorderSide(color: c.border, width: 1),
              right: BorderSide(color: c.border, width: 1),
              bottom: BorderSide(color: c.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: level chip + service name
              Row(
                children: [
                  _Box(width: 48, height: 22, color: shimmerColor, radius: 6),
                  const SizedBox(width: 8),
                  _Box(width: 120, height: 14, color: shimmerColor, radius: 4),
                  const Spacer(),
                  _Box(width: 36, height: 20, color: shimmerColor, radius: 6),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: method + path bar
              _Box(
                width: double.infinity,
                height: 28,
                color: shimmerColor,
                radius: 6,
              ),
              const SizedBox(height: 8),
              // Row 3: meta row
              Row(
                children: [
                  _Box(width: 80, height: 12, color: shimmerColor, radius: 4),
                  const SizedBox(width: 12),
                  _Box(width: 50, height: 12, color: shimmerColor, radius: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
