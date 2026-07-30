import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Offline Asset Image & GIF loader widget for ExerciseDB.
/// Loads bundled local assets from assets/gifs/*.jpg or assets/gifs/*.gif with multi-stage fallback.
/// If an asset file is missing (e.g., Burpee, Jumping Jacks), gracefully shows a clean styled dumbbell placeholder.
class ExerciseGifWidget extends StatefulWidget {
  final String? assetPath;
  final String? gifUrl;
  final String? exerciseId;
  final String? exerciseName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallbackWidget;
  final Widget? loadingWidget;

  const ExerciseGifWidget({
    super.key,
    this.assetPath,
    this.gifUrl,
    this.exerciseId,
    this.exerciseName,
    this.fallbackWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingWidget,
  });

  @override
  State<ExerciseGifWidget> createState() => _ExerciseGifWidgetState();
}

class _ExerciseGifWidgetState extends State<ExerciseGifWidget> {
  int _assetAttempt = 0;

  List<String> _getAssetCandidates() {
    final list = <String>[];

    final rawPath = widget.assetPath?.trim();
    if (rawPath != null && rawPath.isNotEmpty) {
      list.add(rawPath);
    }

    final name = widget.exerciseName?.trim();
    if (name != null && name.isNotEmpty) {
      final sanitized = name
          .toLowerCase()
          .replaceAll('°', '')
          .replaceAll('/', '_')
          .replaceAll('-', '_')
          .replaceAll(' ', '_')
          .replaceAll('__', '_');
      list.add('assets/gifs/$sanitized.gif');
    }

    return list.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _getAssetCandidates();

    if (_assetAttempt < candidates.length) {
      final currentAsset = candidates[_assetAttempt];
      return Image.asset(
        currentAsset,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _assetAttempt++;
              });
            }
          });
          return _buildDefaultFallback();
        },
      );
    }

    return _buildDefaultFallback();
  }

  Widget _buildDefaultFallback() {
    return widget.fallbackWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.8),
                AppColors.accent.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_rounded, size: 36, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'EXERCISE DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
