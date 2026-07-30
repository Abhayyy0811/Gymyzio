import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShineButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final bool disabled;

  const ShineButton({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    this.borderRadius,
    this.gradient,
    this.disabled = false,
  });

  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton> with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shineAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.disabled || widget.onTap == null) return;
    _shineController.forward(from: 0.0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(AppRadius.card);
    final effectiveBg = widget.disabled
        ? AppColors.surfaceLight
        : (widget.backgroundColor ?? AppColors.primary);

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.disabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!widget.disabled) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (!widget.disabled) setState(() => _isPressed = false);
      },
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _shineAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.gradient == null ? effectiveBg : null,
                gradient: widget.gradient,
                borderRadius: effectiveRadius,
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!)
                    : null,
                boxShadow: (widget.glowColor != null && !widget.disabled)
                    ? AppColors.softGlow(widget.glowColor!, opacity: 0.25, blur: 14)
                    : [],
              ),
              child: ClipRRect(
                borderRadius: effectiveRadius,
                child: Stack(
                  children: [
                    Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                    if (_isPressed)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    if (_shineController.isAnimating)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FractionallySizedBox(
                            widthFactor: 0.6,
                            alignment: Alignment(_shineAnimation.value, 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-1.0, -1.0),
                                  end: const Alignment(1.0, 1.0),
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.4),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
