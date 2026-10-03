import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps any screen with a soft layered gradient + ambient glow blobs.
/// Gives the app visual depth without being busy.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F3FF), // lavender mist
            Color(0xFFF7F7FB), // base
            Color(0xFFF1F7FF), // ice blue
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glow — top right
          Positioned(
            top: -120,
            right: -100,
            child: _Glow(
              color: AppColors.primary.withOpacity(0.18),
              size: 260,
            ),
          ),
          // Ambient glow — mid left
          Positioned(
            top: 220,
            left: -120,
            child: _Glow(
              color: AppColors.info.withOpacity(0.10),
              size: 220,
            ),
          ),
          // Ambient glow — bottom right
          Positioned(
            bottom: -140,
            right: -80,
            child: _Glow(
              color: AppColors.primary.withOpacity(0.08),
              size: 240,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}