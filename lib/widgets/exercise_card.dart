import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import 'exercise_gif_widget.dart';

/// Reusable ExerciseCard widget displaying exercise info and animated GIF via ExerciseGifWidget
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isFavorite;
  final Color accentColor;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isFavorite = false,
    this.accentColor = AppColors.libraryAccent,
    this.isCompact = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return AppBouncyTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: exercise.themeColor.withValues(alpha: 0.3)),
            boxShadow: AppColors.softGlow(exercise.themeColor, opacity: 0.08, blur: 6),
          ),
          child: Row(
            children: [
              // Small Thumbnail GIF
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ExerciseGifWidget(
                    assetPath: exercise.assetPath,
                    gifUrl: exercise.gifUrl,
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Spec Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: exercise.themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exercise.muscleGroup,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: exercise.themeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exercise.equipment,
                          style: TextStyle(fontSize: 10, color: AppColors.textMutedOf(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Action & Arrow
              if (onFavoriteToggle != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isFavorite ? accentColor : AppColors.textMutedOf(context),
                    size: 18,
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMutedOf(context)),
            ],
          ),
        ),
      );
    }
    return AppBouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _buildBadgeChip(exercise.muscleGroup, accentColor),
                        _buildBadgeChip(exercise.difficulty, AppColors.secondary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Equipment: ${exercise.equipment}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMutedOf(context)),
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
                color: isFavorite ? accentColor : AppColors.textMutedOf(context),
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
