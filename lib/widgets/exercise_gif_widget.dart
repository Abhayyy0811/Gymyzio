import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Offline Asset Image & GIF loader widget for ExerciseDB.
/// Loads bundled local assets from assets/gifs/*.jpg or assets/gifs/*.gif with multi-stage fallback.
/// If an asset file is missing, gracefully shows a clean styled fallback without infinite loop or memory leak.
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
  bool _useNetwork = false;
  int _networkAttempt = 0;
  bool _hasFailedAll = false;

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

  List<String> _getNetworkCandidates() {
    final list = <String>[];
    if (widget.gifUrl != null && widget.gifUrl!.trim().isNotEmpty) {
      list.add(widget.gifUrl!.trim());
    }

    final id = widget.exerciseId?.trim();
    if (id != null && id.isNotEmpty) {
      final cleanId = id.padLeft(4, '0');
      list.add('https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$cleanId.gif');
    }

    return list.toSet().toList();
  }

  void _handleAssetError(int candidateCount) {
    if (!mounted || _hasFailedAll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_assetAttempt < candidateCount - 1) {
        setState(() {
          _assetAttempt++;
        });
      } else if (!_useNetwork) {
        setState(() {
          _useNetwork = true;
        });
      } else {
        setState(() {
          _hasFailedAll = true;
        });
      }
    });
  }

  void _handleNetworkError(int candidateCount) {
    if (!mounted || _hasFailedAll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_networkAttempt < candidateCount - 1) {
        setState(() {
          _networkAttempt++;
        });
      } else {
        setState(() {
          _hasFailedAll = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFailedAll) {
      return _buildDefaultFallback();
    }

    final assetCandidates = _getAssetCandidates();
    final networkCandidates = _getNetworkCandidates();

    if (!_useNetwork && assetCandidates.isNotEmpty && _assetAttempt < assetCandidates.length) {
      final currentAsset = assetCandidates[_assetAttempt];
      return Image.asset(
        currentAsset,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          _handleAssetError(assetCandidates.length);
          return _buildDefaultFallback();
        },
      );
    }

    if ((_useNetwork || assetCandidates.isEmpty) && networkCandidates.isNotEmpty && _networkAttempt < networkCandidates.length) {
      final currentUrl = networkCandidates[_networkAttempt];
      return Image.network(
        currentUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          _handleNetworkError(networkCandidates.length);
          return _buildDefaultFallback();
        },
      );
    }

    return _buildDefaultFallback();
  }

  Widget _buildDefaultFallback() {
    final initial = widget.exerciseName != null && widget.exerciseName!.isNotEmpty
        ? widget.exerciseName![0].toUpperCase()
        : 'E';

    return widget.fallbackWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.accent.withValues(alpha: 0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'EXERCISE DEMO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
