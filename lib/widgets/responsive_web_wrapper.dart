import 'package:flutter/material.dart';

class ResponsiveWebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWebWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1000.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > maxWidth;

    if (!isWideScreen) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
