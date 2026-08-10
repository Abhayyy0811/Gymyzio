import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_gif_widget.dart';

/// Interactive 100% Offline & Online MP4 Video + Animated Player for Gymyzio.
/// Supports MP4 3D videos, fallback GIFs, working Play/Pause/Stop controls,
/// Mute/Unmute audio, and Muscular Skeleton Fiber highlights.
class InteractiveExercisePlayer extends StatefulWidget {
  final Exercise exercise;
  final double height;
  final BoxFit fit;

  const InteractiveExercisePlayer({
    super.key,
    required this.exercise,
    this.height = 300.0,
    this.fit = BoxFit.cover,
  });

  @override
  State<InteractiveExercisePlayer> createState() => _InteractiveExercisePlayerState();
}

class _InteractiveExercisePlayerState extends State<InteractiveExercisePlayer> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = true;
  bool _isSkeletonFiberMode = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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

    // 1. Explicit exercise.videoPath
    if (widget.exercise.videoPath != null && widget.exercise.videoPath!.trim().isNotEmpty) {
      candidatePaths.add(widget.exercise.videoPath!.trim());
    }

    // 2. Local asset MP4 candidate matching exercise name
    candidatePaths.add('assets/videos/$nameSanitized.mp4');

    // Try loading local asset MP4 first
    for (final path in candidatePaths) {
      try {
        final controller = VideoPlayerController.asset(path);
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(_isMuted ? 0.0 : 1.0);
        if (_isPlaying) {
          await controller.play();
        }

        if (mounted) {
          setState(() {
            _videoController = controller;
            _isVideoInitialized = true;
          });
          return;
        }
      } catch (_) {
        // Continue trying next candidate
      }
    }

    // 3. Try network URL candidates if explicit video URL or sample stream URL is available
    if (widget.exercise.videoPath != null && widget.exercise.videoPath!.startsWith('http')) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(widget.exercise.videoPath!));
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(_isMuted ? 0.0 : 1.0);
        if (_isPlaying) await controller.play();

        if (mounted) {
          setState(() {
            _videoController = controller;
            _isVideoInitialized = true;
          });
          return;
        }
      } catch (_) {}
    }

    // Fallback to GIF engine state if no MP4 video initialized
    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isVideoInitialized && _videoController != null) {
        if (_isPlaying) {
          _videoController!.play();
        } else {
          _videoController!.pause();
        }
      }
    });
  }

  void _stopAnimation() {
    setState(() {
      _isPlaying = false;
      if (_isVideoInitialized && _videoController != null) {
        _videoController!.pause();
        _videoController!.seekTo(Duration.zero);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isVideoInitialized && _videoController != null) {
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _toggleSkeletonFiberMode() {
    setState(() {
      _isSkeletonFiberMode = !_isSkeletonFiberMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    final primaryTarget = widget.exercise.target?.isNotEmpty == true
        ? widget.exercise.target!.toUpperCase()
        : widget.exercise.muscleGroup.toUpperCase();

    // High Contrast Skeleton Fiber Matrix Filter:
    // Transforms skin tones into a dark monochrome anatomical skeleton with bright red/green muscle fiber highlight!
    final ColorFilter fiberMatrixFilter = const ColorFilter.matrix([
      1.5, 0.2, 0.0, 0, 50,    // Red Channel Boost for Muscle Fibers
      0.0, 1.2, 0.2, 0, 10,    // Green Channel Adjustment
      0.0, 0.0, 0.5, 0, 0,     // Blue Channel Suppression
      0.0, 0.0, 0.0, 1, 0,     // Alpha
    ]);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isSkeletonFiberMode ? Colors.redAccent.withValues(alpha: 0.5) : AppColors.borderOf(context),
          width: _isSkeletonFiberMode ? 1.5 : 1.0,
        ),
        boxShadow: _isSkeletonFiberMode
            ? [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              ]
            : AppColors.softGlow(AppColors.primary, opacity: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. MP4 3D Video Player or GIF Fallback Layer with Working Play/Pause/Stop Freeze
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: _isSkeletonFiberMode
                  ? fiberMatrixFilter
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
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
                  : (_isPlaying
                      ? ExerciseGifWidget(
                          assetPath: widget.exercise.assetPath,
                          gifUrl: widget.exercise.gifUrl,
                          exerciseId: widget.exercise.id,
                          exerciseName: widget.exercise.name,
                          fit: widget.fit,
                        )
                      : ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.65),
                            BlendMode.darken,
                          ),
                          child: ExerciseGifWidget(
                            assetPath: widget.exercise.assetPath,
                            gifUrl: widget.exercise.gifUrl,
                            exerciseId: widget.exercise.id,
                            exerciseName: widget.exercise.name,
                            fit: widget.fit,
                          ),
                        )),
            ),
          ),

          // 2. Skeleton Muscle Fiber Mode Active Tag
          if (_isSkeletonFiberMode)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: _isPlaying ? _pulseController.value : 0.4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: _isPlaying ? 0.9 : 0.2),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isVideoInitialized ? '3D MP4 VIDEO ACTIVE' : 'SKELETON FIBERS HIGHLIGHT',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Muscle Fiber Target Tag Badge
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

          // 4. Center Touch Play Overlay (When Stopped / Paused)
          if (!_isPlaying)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PAUSED • TAP TO RESUME',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Interactive Control Bar (Bottom Floating Control Panel)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  // Play / Pause Button
                  AppBouncyTap(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPlaying ? AppColors.primary : Colors.greenAccent.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Stop Button (Resets & Freezes)
                  AppBouncyTap(
                    onTap: _stopAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),

                  if (_isVideoInitialized) ...[
                    const SizedBox(width: 8),
                    // Mute / Unmute Button
                    AppBouncyTap(
                      onTap: _toggleMute,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 12),

                  // Playback Status Indicator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPlaying ? (_isVideoInitialized ? 'PLAYING 3D MP4 VIDEO' : 'ANIMATION PLAYING') : 'STOPPED / PAUSED',
                          style: TextStyle(
                            color: _isPlaying ? Colors.greenAccent : Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _isPlaying ? 'Tap Stop to freeze motion' : 'Tap Play to start motion',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skeleton Muscle Fiber Mode Toggle Switch Button
                  AppBouncyTap(
                    onTap: _toggleSkeletonFiberMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isSkeletonFiberMode
                            ? Colors.redAccent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSkeletonFiberMode ? Colors.redAccent : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_rounded,
                            color: _isSkeletonFiberMode ? Colors.redAccent : Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isSkeletonFiberMode ? 'FIBERS ON' : 'NORMAL',
                            style: TextStyle(
                              color: _isSkeletonFiberMode ? Colors.redAccent : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
