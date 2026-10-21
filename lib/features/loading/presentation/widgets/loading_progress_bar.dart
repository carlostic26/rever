import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/theme/app_colors.dart';

class LoadingProgressBar extends StatelessWidget {
  final double width;
  final double lineHeight;
  final int animationDurationMs;
  final Color progressColor;
  final Color backgroundColor;
  final VoidCallback? onAnimationEnd;

  const LoadingProgressBar({
    super.key,
    required this.width,
    this.lineHeight = 7.0,
    this.animationDurationMs = 10000,
    this.progressColor = AppColors.darkAccent,
    this.backgroundColor = AppColors.darkSurfaceStrong,
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
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      barRadius: const Radius.circular(10),
      alignment: MainAxisAlignment.center,
      onAnimationEnd: onAnimationEnd,
    );
  }
}
