import 'package:flutter/material.dart';

class ThreeDotsIndicator extends StatefulWidget {
  final Color dotColor;
  final double size;

  const ThreeDotsIndicator({
    super.key,
    this.dotColor = Colors.white,
    this.size = 10.0,
  });

  @override
  State<ThreeDotsIndicator> createState() => _ThreeDotsIndicatorState();
}

class _ThreeDotsIndicatorState extends State<ThreeDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Desfase para cada punto (0.0, 0.2, 0.4)
        final double delay = index * 0.2;
        final double progress = (_controller.value - delay) % 1.0;
        final double scale = 0.6 + (0.5 * (1.0 - (progress - 0.5).abs() * 2));
        final double opacity = 0.3 + (0.7 * (1.0 - (progress - 0.5).abs() * 2));

        return Transform.scale(
          scale: scale.clamp(0.6, 1.2),
          child: Opacity(
            opacity: opacity.clamp(0.3, 1.0),
            child: Container(
              width: widget.size,
              height: widget.size,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.dotColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildDot(0), _buildDot(1), _buildDot(2)],
    );
  }
}
