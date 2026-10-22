import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget que dibuja un espectro de barras de audio animado estilo ecualizador.
/// El color de las barras es una tonalidad más oscura del contenedor que lo aloja.
class AudioSpectrumWave extends StatefulWidget {
  final Color barColor;
  final bool isActive;
  final int barCount;
  final double height;

  const AudioSpectrumWave({
    super.key,
    required this.barColor,
    this.isActive = false,
    this.barCount = 28,
    this.height = 44,
  });

  @override
  State<AudioSpectrumWave> createState() => _AudioSpectrumWaveState();
}

class _AudioSpectrumWaveState extends State<AudioSpectrumWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioSpectrumWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 400));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SpectrumPainter(
              barColor: widget.barColor,
              progress: _controller.value,
              isActive: widget.isActive,
              barCount: widget.barCount,
            ),
          );
        },
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final Color barColor;
  final double progress;
  final bool isActive;
  final int barCount;

  _SpectrumPainter({
    required this.barColor,
    required this.progress,
    required this.isActive,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final double totalWidth = size.width;
    final double barSpacing = 3.0;
    final double totalSpacing = barSpacing * (barCount - 1);
    final double barWidth = math.max(
      2.0,
      (totalWidth - totalSpacing) / barCount,
    );

    final double maxHeight = size.height;
    final double minHeight = 4.0;
    final double twoPi = 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      double normalizedHeight;

      if (isActive) {
        // Combinación armónica de senos para simular ondas de audio naturales y variadas
        final double phase1 = progress * twoPi;
        final double wave1 = math.sin(phase1 + (i * 0.45));
        final double wave2 = math.cos(phase1 * 1.5 + (i * 0.28));
        final double wave3 = math.sin(phase1 * 0.8 + (i * 0.7));

        final double combined = (wave1 * 0.45 + wave2 * 0.35 + wave3 * 0.20)
            .abs();
        normalizedHeight = (minHeight + combined * (maxHeight - minHeight))
            .clamp(minHeight, maxHeight);
      } else {
        // En reposo: barras bajas y suaves
        final double subtle = (math.sin(i * 0.3) * 0.3 + 0.5).abs();
        normalizedHeight = (minHeight + subtle * 4.0).clamp(minHeight, 10.0);
      }

      final double left = i * (barWidth + barSpacing);
      final double top = size.height - normalizedHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, normalizedHeight),
        const Radius.circular(2.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.barColor != barColor;
  }
}
