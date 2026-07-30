import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shimmer Loading Skeleton for Exercise Library Cards
class ExerciseSkeletonWidget extends StatefulWidget {
  final int itemCount;

  const ExerciseSkeletonWidget({
    super.key,
    this.itemCount = 6,
  });

  @override
  State<ExerciseSkeletonWidget> createState() => _ExerciseSkeletonWidgetState();
}

class _ExerciseSkeletonWidgetState extends State<ExerciseSkeletonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = Colors.white.withValues(alpha: _animation.value * 0.15);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // GIF Thumbnail Skeleton
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text Info Skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Exercise Name Skeleton
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Muscle Group Skeleton
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Chips Skeleton
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 70,
                              height: 20,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
