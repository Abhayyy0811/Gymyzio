import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import 'exercise_gif_widget.dart';

/// Reusable ExerciseCard widget displaying exercise info and animated GIF via ExerciseGifWidget
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isFavorite;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isFavorite = false,
    this.accentColor = AppColors.libraryAccent,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: exercise.themeColor.withValues(alpha: 0.4)),
          boxShadow: AppColors.softGlow(exercise.themeColor, opacity: 0.15, blur: 12),
        ),
        child: Row(
          children: [
            // GIF Thumbnail Container using ExerciseGifWidget (Primary + GitHub mirror fallback)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: ExerciseGifWidget(
                  assetPath: exercise.assetPath,
                  gifUrl: exercise.gifUrl,
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Exercise Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBadgeChip(exercise.muscleGroup, accentColor),
                        const SizedBox(width: 6),
                        _buildBadgeChip(exercise.difficulty, AppColors.secondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Equipment: ${exercise.equipment}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Favorite Action Button
            IconButton(
              icon: Icon(
                isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isFavorite ? accentColor : AppColors.textMuted,
              ),
              onPressed: onFavoriteToggle,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
