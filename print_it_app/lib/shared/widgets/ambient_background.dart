import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Stack(
      children: [
        // Background color
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        
        // Top-left glowing blob
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.25),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.3),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),

        // Bottom-right glowing blob
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withValues(alpha: isDark ? 0.1 : 0.2),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: isDark ? 0.15 : 0.25),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
