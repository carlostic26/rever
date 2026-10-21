import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountingAnimation extends StatefulWidget {
  final int endCount;
  final double textSize;
  final Duration duration;

  const CountingAnimation({
    super.key,
    required this.endCount,
    required this.textSize,
    this.duration = const Duration(seconds: 9),
  });

  @override
  State<CountingAnimation> createState() => _CountingAnimationState();
}

class _CountingAnimationState extends State<CountingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: widget.endCount.toDouble(),
    ).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Text(
          _animation.value.toInt().toString(),
          style: GoogleFonts.poppins(
            fontSize: widget.textSize + 3,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1,
          ),
        );
      },
    );
  }
}
