import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated shimmer effect for loading placeholders.
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
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              colors: const [
                Color(0xFFEAE7F5),
                Color(0xFFF7F6FB),
                Color(0xFFEAE7F5),
              ],
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

/// Base skeleton block.
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAE7F5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for a summary card.
class SkeletonSummaryCard extends StatelessWidget {
  final bool gradient;

  const SkeletonSummaryCard({super.key, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gradient
            ? const Color(0xFFEAE7F5)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: gradient
            ? null
            : Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 34, height: 34, radius: AppRadius.sm),
              const SizedBox(width: 10),
              SkeletonBox(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SkeletonBox(width: 100, height: 22, radius: 6),
        ],
      ),
    );
  }
}

/// Skeleton for a subscription row.
class SkeletonSubscriptionCard extends StatelessWidget {
  const SkeletonSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            SkeletonBox(width: 52, height: 52, radius: AppRadius.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 11),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 60, height: 14),
                const SizedBox(height: 6),
                SkeletonBox(width: 30, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full dashboard loading view.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              SkeletonBox(width: 100, height: 12),
              const SizedBox(height: 10),
              SkeletonBox(width: 240, height: 24, radius: 6),
              const SizedBox(height: 8),
              SkeletonBox(width: 180, height: 12),

              const SizedBox(height: 24),

              // Summary row
              Row(
                children: const [
                  Expanded(child: SkeletonSummaryCard(gradient: true)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonSummaryCard(gradient: true)),
                ],
              ),

              const SizedBox(height: 12),

              const SkeletonSummaryCard(),

              const SizedBox(height: 20),

              // Spending insight
              const SkeletonSummaryCard(),

              const SizedBox(height: 28),

              // Section title
              SkeletonBox(width: 140, height: 16),

              const SizedBox(height: 12),

              // Search
              SkeletonBox(
                width: double.infinity,
                height: 52,
                radius: AppRadius.md,
              ),

              const SizedBox(height: 14),

              // List items
              const SkeletonSubscriptionCard(),
              const SkeletonSubscriptionCard(),
              const SkeletonSubscriptionCard(),
            ],
          ),
        ),
      ),
    );
  }
}