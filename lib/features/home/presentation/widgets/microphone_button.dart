import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class MicrophoneButton extends StatefulWidget {
  final bool isRecording;
  final Duration recordingDuration;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerUpEvent>? onPointerUp;
  final ValueChanged<PointerCancelEvent>? onPointerCancel;
  final double size;

  const MicrophoneButton({
    super.key,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerCancel,
    this.size = 120.0,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  late final AnimationController _recordingWaveController;

  @override
  void initState() {
    super.initState();
    // Animación sutil de respiración cuando está en reposo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 12.0, end: 28.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación rápida de pulso cuando está grabando activamente
    _recordingWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _recordingWaveController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _recordingWaveController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingWaveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (duration.inMilliseconds % 1000 ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón con detector de puntero inmediato (sin retrasos tipo WhatsApp)
        Listener(
          onPointerDown: widget.onPointerDown,
          onPointerUp: widget.onPointerUp,
          onPointerCancel: widget.onPointerCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: widget.isRecording
                ? _recordingWaveController
                : _pulseController,
            builder: (context, child) {
              final double scale = widget.isRecording
                  ? 1.08 + (_recordingWaveController.value * 0.08)
                  : _pulseAnimation.value;

              final double glowRadius = widget.isRecording
                  ? 28.0 + (_recordingWaveController.value * 16.0)
                  : _glowAnimation.value;

              final Color glowColor = widget.isRecording
                  ? AppColors.statusRecording.withValues(alpha: 0.65)
                  : AppColors.violetAccent.withValues(alpha: 0.45);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: glowRadius,
                        spreadRadius: widget.isRecording ? 6 : 2,
                      ),
                      if (!widget.isRecording)
                        BoxShadow(
                          color: AppColors.electricBlue.withValues(alpha: 0.2),
                          blurRadius: glowRadius * 1.5,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isRecording
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.buttonMicGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isRecording
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      key: ValueKey(widget.isRecording),
                      color: Colors.white,
                      size: buttonSize * 0.44,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Indicador de duración / Texto de ayuda
        if (widget.isRecording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusRecording,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(widget.recordingDuration),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusRecording,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Suelta para finalizar la grabación',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ] else ...[
          Text(
            'Mantén pulsado para grabar',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.darkTextSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}
