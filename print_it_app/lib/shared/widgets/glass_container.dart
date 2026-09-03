import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ] : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.4),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
