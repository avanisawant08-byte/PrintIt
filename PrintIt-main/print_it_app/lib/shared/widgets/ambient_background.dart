import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070B14),
              Color(0xFF090E1A),
              Color(0xFF0C1322),
            ],
          ),
        ),
      );
    }

    // Light Theme: Atmospheric 3-orb ambient backdrop
    return Stack(
      children: [
        // Base Light Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FCFF),
                Color(0xFFEEF6FC),
                Color(0xFFE8F2FA),
              ],
            ),
          ),
        ),

        // Glow Orb 1 (top-right: soft cyan)
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA5F3FC).withValues(alpha: 0.55),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA5F3FC).withValues(alpha: 0.60),
                  blurRadius: 90,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),

        // Glow Orb 2 (mid-left: soft sky blue)
        Positioned(
          top: 150,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBAE6FD).withValues(alpha: 0.50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.55),
                  blurRadius: 100,
                  spreadRadius: 45,
                ),
              ],
            ),
          ),
        ),

        // Glow Orb 3 (bottom-right: soft blue-lavender)
        Positioned(
          bottom: 100,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF93C5FD).withValues(alpha: 0.35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.40),
                  blurRadius: 90,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
