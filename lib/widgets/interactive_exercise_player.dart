import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_gif_widget.dart';

/// Clean & Sleek Exercise Demonstration Player for Gymyzio.
/// Displays high quality exercise GIFs/Videos continuously at original speed
/// without extra overlays, play/pause controls, or skeleton filters.
class InteractiveExercisePlayer extends StatefulWidget {
  final Exercise exercise;
  final double height;
  final BoxFit fit;

  const InteractiveExercisePlayer({
    super.key,
    required this.exercise,
    this.height = 300.0,
    this.fit = BoxFit.contain,
  });

  @override
  State<InteractiveExercisePlayer> createState() => _InteractiveExercisePlayerState();
}

class _InteractiveExercisePlayerState extends State<InteractiveExercisePlayer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  @override
  void didUpdateWidget(covariant InteractiveExercisePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id ||
        oldWidget.exercise.videoPath != widget.exercise.videoPath) {
      _disposeVideoController();
      _initVideoController();
    }
  }

  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  Future<void> _initVideoController() async {
    final nameSanitized = widget.exercise.name
        .toLowerCase()
        .replaceAll('°', '')
        .replaceAll('/', '_')
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');

    final candidatePaths = <String>[];

    if (widget.exercise.videoPath != null && widget.exercise.videoPath!.trim().isNotEmpty) {
      candidatePaths.add(widget.exercise.videoPath!.trim());
    }
    candidatePaths.add('assets/videos/$nameSanitized.mp4');

    for (final path in candidatePaths) {
      try {
        final controller = VideoPlayerController.asset(path);
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0.0);
        await controller.play();

        if (mounted) {
          setState(() {
            _videoController = controller;
            _isVideoInitialized = true;
          });
          return;
        }
      } catch (_) {}
    }

    if (widget.exercise.videoPath != null && widget.exercise.videoPath!.startsWith('http')) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(widget.exercise.videoPath!));
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0.0);
        await controller.play();

        if (mounted) {
          setState(() {
            _videoController = controller;
            _isVideoInitialized = true;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    final primaryTarget = widget.exercise.target?.isNotEmpty == true
        ? widget.exercise.target!.toUpperCase()
        : widget.exercise.muscleGroup.toUpperCase();

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context), width: 1.0),
        boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Direct GIF / Video Player Layer (Normal original speed & quality)
          Positioned.fill(
            child: _isVideoInitialized && _videoController != null
                ? FittedBox(
                    fit: widget.fit,
                    child: SizedBox(
                      width: _videoController!.value.size.width > 0
                          ? _videoController!.value.size.width
                          : 400,
                      height: _videoController!.value.size.height > 0
                          ? _videoController!.value.size.height
                          : 300,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : ExerciseGifWidget(
                    assetPath: widget.exercise.assetPath,
                    gifUrl: widget.exercise.gifUrl,
                    exerciseId: widget.exercise.id,
                    exerciseName: widget.exercise.name,
                    fit: widget.fit,
                  ),
          ),

          // 2. Muscle Target Tag Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    primaryTarget,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
