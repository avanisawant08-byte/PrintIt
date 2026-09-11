import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.borderRadius = 22,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor1 = isDark
        ? const Color(0xFF131C2E).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.90);
    final surfaceColor2 = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.80);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.85);

    final defaultShadow = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.40)
            : const Color(0x180F172A),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ];

    final effectiveBorder = border;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: color != null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [surfaceColor1, surfaceColor2],
                    ),
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: effectiveBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
