import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/home_audio_state.dart';

class ReverseAudioPlayerPanel extends StatelessWidget {
  final HomeAudioState state;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback? onPlayPausePressed;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onRecordAnotherPressed;
  final VoidCallback? onDeletePressed;

  const ReverseAudioPlayerPanel({
    super.key,
    required this.state,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.onPlayPausePressed,
    this.onSeek,
    this.onRecordAnotherPressed,
    this.onDeletePressed,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasReversedAudio = state.hasReversedAudio;
    final bool isProcessing = state.isProcessing;

    final String? displayPath = state.reversedAudioPath;
    final String? fileName = displayPath != null
        ? File(displayPath).uri.pathSegments.last
        : null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasReversedAudio
              ? AppColors.violetAccent.withValues(alpha: 0.5)
              : (isProcessing
                  ? AppColors.violetAccent.withValues(alpha: 0.3)
                  : AppColors.darkSurfaceStrong),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasReversedAudio
                ? AppColors.violetAccent.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Encabezado del reproductor
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.violetAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fast_rewind_rounded,
                  color: AppColors.violetAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu audio en reversa',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasReversedAudio
                      ? AppColors.electricBlue.withValues(alpha: 0.15)
                      : (isProcessing
                          ? AppColors.violetAccent.withValues(alpha: 0.15)
                          : AppColors.darkSurfaceStrong.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasReversedAudio
                      ? 'Listo'
                      : (isProcessing ? 'Procesando' : 'En espera'),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: hasReversedAudio
                        ? AppColors.electricBlue
                        : (isProcessing
                            ? AppColors.violetAccent
                            : AppColors.darkTextMuted),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Contenido según el estado
          if (isProcessing)
            _buildProcessingIndicator()
          else if (hasReversedAudio)
            _buildActivePlayer(fileName)
          else
            _buildWaitingPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.violetAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.violetAccent),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Invirtiendo muestras de audio...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Procesando en segundo plano sin bloquear la pantalla',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkSurfaceStrong.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 38,
            color: AppColors.darkTextMuted.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            'Mantén presionado el micrófono para grabar',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El audio se invertirá automáticamente al soltar',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlayer(String? fileName) {
    final double maxMilliseconds = totalDuration.inMilliseconds > 0
        ? totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final double currentMilliseconds = currentPosition.inMilliseconds
        .clamp(0, totalDuration.inMilliseconds)
        .toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.darkSurfaceStrong,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del archivo invertido y duración total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.audio_file_rounded,
                      size: 16,
                      color: AppColors.electricBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fileName ?? 'rever_audio_invertido.wav',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceStrong,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(totalDuration),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progreso interactiva
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
              activeTrackColor: AppColors.violetAccent,
              inactiveTrackColor: AppColors.darkSurfaceStrong,
              thumbColor: AppColors.electricBlue,
              overlayColor: AppColors.electricBlue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentMilliseconds,
              max: maxMilliseconds,
              onChanged: (value) {
                onSeek?.call(Duration(milliseconds: value.toInt()));
              },
            ),
          ),

          // Tiempos: Transcurrido / Total
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentPosition),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(totalDuration),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón central de reproducir/pausar
          Center(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isPlaying
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.buttonMicGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violetAccent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: onPlayPausePressed,
                  child: Center(
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.darkSurfaceStrong, thickness: 1),
          const SizedBox(height: 6),

          // Botones inferiores: "Grabar otro" y "Descartar"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onRecordAnotherPressed,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.electricBlue,
                ),
                label: Text(
                  'Grabar otro',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppColors.darkSurfaceStrong.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDeletePressed,
                tooltip: 'Eliminar audio invertido',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.darkTextMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Alias para compatibilidad de código existente
typedef ReverseAudioPlayerPlaceholder = ReverseAudioPlayerPanel;
