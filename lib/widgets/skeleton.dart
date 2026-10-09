import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark ? const Color(0xFF23233D) : const Color(0xFFE8E3F5);
    final highlight = isDark ? const Color(0xFF2D2D48) : const Color(0xFFF4F1FB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = (bounds.width * 2) * (_controller.value - 0.5);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF23233D) : const Color(0xFFE8E3F5);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonSummaryCard extends StatelessWidget {
  final bool gradient;

  const SkeletonSummaryCard({super.key, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gradient
            ? (isDark ? const Color(0xFF23233D) : const Color(0xFFE8E3F5))
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: gradient || isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Row(
            children: [
              SkeletonBox(width: 13, height: 13, radius: 3),
              SizedBox(width: 6),
              SkeletonBox(width: 48, height: 10),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(width: 90, height: 22, radius: 6),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 10),
        ],
      ),
    );
  }
}

class SkeletonSubscriptionCard extends StatelessWidget {
  const SkeletonSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 52, height: 52, radius: AppRadius.md),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 130, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 11),
                  SizedBox(height: 8),
                  SkeletonBox(width: 110, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SkeletonBox(width: 66, height: 15),
                SizedBox(height: 6),
                SkeletonBox(width: 26, height: 10),
              ],
            ),
            const SizedBox(width: 8),
            const SkeletonBox(width: 18, height: 18, radius: 4),
          ],
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 90, height: 11),
              SizedBox(height: 8),
              SkeletonBox(width: 160, height: 28, radius: 6),
              SizedBox(height: 8),
              SkeletonBox(width: 200, height: 12),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SkeletonSummaryCard(gradient: true)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonSummaryCard(gradient: true)),
                ],
              ),
              SizedBox(height: 12),
              SkeletonSummaryCard(),
              SizedBox(height: 20),
              SkeletonSummaryCard(gradient: true),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SkeletonBox(height: 48, radius: AppRadius.md),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SkeletonBox(height: 48, radius: AppRadius.md),
                  ),
                ],
              ),
              SizedBox(height: 28),
              SkeletonBox(width: 130, height: 16),
              SizedBox(height: 12),
              SkeletonBox(
                width: double.infinity,
                height: 56,
                radius: AppRadius.md,
              ),
              SizedBox(height: 14),
              SkeletonSubscriptionCard(),
              SkeletonSubscriptionCard(),
              SkeletonSubscriptionCard(),
            ],
          ),
        ),
      ),
    );
  }
}