import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/theme/app_colors.dart';

class LoadingProgressBar extends StatelessWidget {
  final double width;
  final double lineHeight;
  final int animationDurationMs;
  final LinearGradient? linearGradient;
  final Color backgroundColor;
  final Curve curve;
  final VoidCallback? onAnimationEnd;

  const LoadingProgressBar({
    super.key,
    required this.width,
    this.lineHeight = 18.0,
    this.animationDurationMs = 7000,
    this.linearGradient,
    this.backgroundColor = const Color(0xFF0E2536),
    this.curve = Curves.easeInOutCubic,
    this.onAnimationEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      width: width,
      lineHeight: lineHeight,
      percent: 1.0,
      animation: true,
      animationDuration: animationDurationMs,
      curve: curve,
      linearGradient: linearGradient ??
          const LinearGradient(
            colors: [
              AppColors.primaryBlue,
              AppColors.neonCyan,
              AppColors.secondaryGreen,
            ],
          ),
      backgroundColor: backgroundColor,
      barRadius: Radius.circular(lineHeight),
      alignment: MainAxisAlignment.center,
      onAnimationEnd: onAnimationEnd,
    );
  }
}
