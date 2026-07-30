import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';

class RestTimerWidget extends ConsumerWidget {
  final bool compact;

  const RestTimerWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);

    final progress = timerState.totalDuration > 0
        ? timerState.secondsRemaining / timerState.totalDuration
        : 0.0;

    final minutes = (timerState.secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerState.secondsRemaining % 60).toString().padLeft(2, '0');
    final timeFormatted = '$minutes:$seconds';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: timerState.isRunning
              ? AppColors.secondary.withValues(alpha: 0.6)
              : AppColors.border,
          width: timerState.isRunning ? 1.5 : 1.0,
        ),
        boxShadow: timerState.isRunning
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header title & status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.secondary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Rest Timer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: timerState.isRunning
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: timerState.isRunning
                        ? AppColors.secondary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: timerState.isRunning ? AppColors.secondary : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timerState.isRunning
                          ? 'Resting...'
                          : timerState.secondsRemaining == 0
                              ? 'Finished'
                              : 'Paused',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: timerState.isRunning ? AppColors.secondary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Centerpiece Large Circular Countdown Display
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE2E8F0)),
                  ),
                ),
                // Animated Progress Ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      timerState.secondsRemaining <= 10 && timerState.secondsRemaining > 0
                          ? Colors.redAccent
                          : AppColors.secondary,
                    ),
                  ),
                ),
                // Timer Text Display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeFormatted,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'REMAINING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Controls Row below clock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // -15s Button
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                label: '-15s',
                onTap: () => notifier.adjustTime(-15),
              ),

              // Play / Pause Button
              AppBouncyTap(
                onTap: () => notifier.togglePauseResume(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // +15s Button
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                label: '+15s',
                onTap: () => notifier.adjustTime(15),
              ),

              // Skip Button
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                label: 'Skip',
                color: Colors.redAccent,
                onTap: () => notifier.skip(),
              ),

              // Lap Button
              _buildControlButton(
                icon: Icons.flag_rounded,
                label: 'Lap',
                color: AppColors.primary,
                onTap: () => notifier.addLap(),
              ),
            ],
          ),

          // Laps List below clock if any recorded
          if (timerState.laps.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Laps / Split Times (${timerState.laps.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 110),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: timerState.laps.length,
                itemBuilder: (context, index) {
                  final lapText = timerState.laps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.outlined_flag_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${lapText.split(' ')[0]} ${lapText.split(' ')[1]}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            lapText.contains('(') ? lapText.split('(')[1].replaceAll(')', '') : '',
                            style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return AppBouncyTap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
