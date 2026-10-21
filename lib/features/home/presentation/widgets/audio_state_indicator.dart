import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/home_audio_state.dart';

class AudioStateIndicator extends StatelessWidget {
  final HomeAudioState state;

  const AudioStateIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color = state.statusColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de luz pulsante / Ícono de estado o Spinner indeterminado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: state.isProcessing
                ? SizedBox(
                    key: const ValueKey('processing_spinner'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    state.statusIcon,
                    key: ValueKey(state.status),
                    size: 16,
                    color: color,
                  ),
          ),
          const SizedBox(width: 8),

          // Texto de estado
          Text(
            state.statusText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.darkTextPrimary,
            ),
          ),

          // Si hay duración de grabación/reproducción registrada
          if (state.recordedDuration != null && !state.isProcessing) ...[
            const SizedBox(width: 8),
            Text(
              '(${_formatDuration(state.recordedDuration!)})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
