import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Estados posibles y mutuamente excluyentes de la sesión de audio en la pantalla principal
enum AudioSessionStatus { idle, recording, processing, ready, playing, error }

/// Modelo inmutable y tipado que representa el estado visual y operativo del Home
class HomeAudioState {
  final AudioSessionStatus status;
  final String statusText;
  final Duration? recordedDuration;
  final String? audioPath;
  final String? reversedAudioPath;
  final String? errorMessage;

  const HomeAudioState({
    required this.status,
    required this.statusText,
    this.recordedDuration,
    this.audioPath,
    this.reversedAudioPath,
    this.errorMessage,
  });

  /// Estado inicial por defecto
  static const HomeAudioState initial = HomeAudioState(
    status: AudioSessionStatus.idle,
    statusText: 'Listo para grabar',
  );

  bool get isIdle => status == AudioSessionStatus.idle;
  bool get isRecording => status == AudioSessionStatus.recording;
  bool get isProcessing => status == AudioSessionStatus.processing;
  bool get isReady => status == AudioSessionStatus.ready;
  bool get isPlaying => status == AudioSessionStatus.playing;
  bool get isError => status == AudioSessionStatus.error;
  bool get hasReversedAudio => reversedAudioPath != null;
  bool get canPlay => (isReady || isPlaying) && hasReversedAudio;

  /// Retorna el color representativo del estado actual
  Color get statusColor {
    switch (status) {
      case AudioSessionStatus.idle:
        return AppColors.darkTextSecondary;
      case AudioSessionStatus.recording:
        return AppColors.statusRecording;
      case AudioSessionStatus.processing:
        return AppColors.violetAccent;
      case AudioSessionStatus.ready:
        return AppColors.electricBlue;
      case AudioSessionStatus.playing:
        return AppColors.statusSuccess;
      case AudioSessionStatus.error:
        return AppColors.statusRecording;
    }
  }

  /// Retorna el ícono representativo del estado actual
  IconData get statusIcon {
    switch (status) {
      case AudioSessionStatus.idle:
        return Icons.mic_none_rounded;
      case AudioSessionStatus.recording:
        return Icons.fiber_manual_record_rounded;
      case AudioSessionStatus.processing:
        return Icons.sync_rounded;
      case AudioSessionStatus.ready:
        return Icons.check_circle_outline_rounded;
      case AudioSessionStatus.playing:
        return Icons.volume_up_rounded;
      case AudioSessionStatus.error:
        return Icons.error_outline_rounded;
    }
  }

  HomeAudioState copyWith({
    AudioSessionStatus? status,
    String? statusText,
    Duration? recordedDuration,
    String? audioPath,
    String? reversedAudioPath,
    String? errorMessage,
  }) {
    return HomeAudioState(
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      recordedDuration: recordedDuration ?? this.recordedDuration,
      audioPath: audioPath ?? this.audioPath,
      reversedAudioPath: reversedAudioPath ?? this.reversedAudioPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
