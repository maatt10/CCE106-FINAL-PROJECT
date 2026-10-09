import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF14142B),
                  Color(0xFF0F0F1A),
                  Color(0xFF12122A),
                ]
              : const [
                  Color(0xFFF4F0FF),
                  Color(0xFFF8F8FC),
                  Color(0xFFF0F5FF),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: _Glow(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withOpacity(isDark ? 0.22 : 0.16),
              size: 280,
            ),
          ),
          Positioned(
            top: 240,
            left: -140,
            child: _Glow(
              color: (isDark ? AppColors.infoDark : AppColors.info)
                  .withOpacity(isDark ? 0.12 : 0.08),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -160,
            right: -100,
            child: _Glow(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withOpacity(isDark ? 0.14 : 0.07),
              size: 260,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white)
                          .withOpacity(isDark ? 0.15 : 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
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
            colors: [color, color.withOpacity(0.0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}