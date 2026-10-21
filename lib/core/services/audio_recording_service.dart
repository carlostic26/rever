import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Resultado del chequeo o solicitud de permisos
enum MicrophonePermissionStatus { granted, denied, permanentlyDenied }

/// Resultado de una sesión de grabación finalizada
class AudioRecordingResult {
  final bool isSuccess;
  final String? filePath;
  final Duration duration;
  final int fileSizeBytes;
  final String? errorMessage;

  const AudioRecordingResult._({
    required this.isSuccess,
    this.filePath,
    this.duration = Duration.zero,
    this.fileSizeBytes = 0,
    this.errorMessage,
  });

  factory AudioRecordingResult.success({
    required String filePath,
    required Duration duration,
    required int fileSizeBytes,
  }) {
    return AudioRecordingResult._(
      isSuccess: true,
      filePath: filePath,
      duration: duration,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory AudioRecordingResult.failure(String errorMessage) {
    return AudioRecordingResult._(isSuccess: false, errorMessage: errorMessage);
  }
}

/// Servicio encargado de la gestión de permisos, captura y archivo de audio
class AudioRecordingService {
  final AudioRecorder _recorder;
  bool _isRecording = false;
  bool _isTransitioning = false;
  DateTime? _recordStartTime;
  String? _currentRecordingPath;

  AudioRecordingService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  bool get isRecording => _isRecording;
  bool get isTransitioning => _isTransitioning;

  /// Verifica y solicita el permiso de micrófono si es necesario
  Future<MicrophonePermissionStatus> checkAndRequestPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return MicrophonePermissionStatus.granted;
      }

      if (status.isPermanentlyDenied) {
        return MicrophonePermissionStatus.permanentlyDenied;
      }

      final requestStatus = await Permission.microphone.request();
      if (requestStatus.isGranted) {
        return MicrophonePermissionStatus.granted;
      } else if (requestStatus.isPermanentlyDenied) {
        return MicrophonePermissionStatus.permanentlyDenied;
      } else {
        return MicrophonePermissionStatus.denied;
      }
    } catch (e) {
      debugPrint('[AudioRecordingService] Error verificando permisos: $e');
      // Fallback a hasPermission del recorder
      final hasPerm = await _recorder.hasPermission();
      return hasPerm
          ? MicrophonePermissionStatus.granted
          : MicrophonePermissionStatus.denied;
    }
  }

  /// Abre la pantalla de ajustes de la aplicación en el dispositivo
  Future<bool> openDeviceSettings() async {
    return openAppSettings();
  }

  /// Inicia la grabación en formato PCM WAV (16-bit, 44.1kHz, mono)
  Future<bool> startRecording() async {
    if (_isRecording || _isTransitioning) return false;

    _isTransitioning = true;
    try {
      final permStatus = await checkAndRequestPermission();
      if (permStatus != MicrophonePermissionStatus.granted) {
        _isTransitioning = false;
        return false;
      }

      // Directorio de almacenamiento local
      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String targetPath = '${dir.path}/rever_rec_$timestamp.wav';
      _currentRecordingPath = targetPath;

      const RecordConfig config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      );

      await _recorder.start(config, path: targetPath);
      _isRecording = true;
      _recordStartTime = DateTime.now();
      debugPrint('[AudioRecordingService] Grabación iniciada en: $targetPath');
      return true;
    } catch (e) {
      debugPrint('[AudioRecordingService] Error al iniciar grabación: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      _recordStartTime = null;
      return false;
    } finally {
      _isTransitioning = false;
    }
  }

  /// Detiene la grabación y valida el archivo generado
  Future<AudioRecordingResult> stopRecording() async {
    if (!_isRecording && !_isTransitioning) {
      return AudioRecordingResult.failure('No hay grabación activa.');
    }

    _isTransitioning = true;
    try {
      final Duration duration = _recordStartTime != null
          ? DateTime.now().difference(_recordStartTime!)
          : Duration.zero;

      final String? finalPath = await _recorder.stop();
      _isRecording = false;
      _recordStartTime = null;

      final String? pathToCheck = finalPath ?? _currentRecordingPath;
      if (pathToCheck == null) {
        return AudioRecordingResult.failure('No se obtuvo ruta de archivo.');
      }

      final File file = File(pathToCheck);
      if (!file.existsSync()) {
        return AudioRecordingResult.failure('El archivo de audio no existe.');
      }

      final int size = file.lengthSync();
      if (size <= 44) {
        // Un archivo WAV con solo cabecera o vacío
        try {
          file.deleteSync();
        } catch (_) {}
        return AudioRecordingResult.failure('La grabación está vacía.');
      }

      debugPrint(
        '[AudioRecordingService] Grabación exitosa: $pathToCheck ($size bytes)',
      );
      return AudioRecordingResult.success(
        filePath: pathToCheck,
        duration: duration,
        fileSizeBytes: size,
      );
    } catch (e) {
      debugPrint('[AudioRecordingService] Error al detener grabación: $e');
      return AudioRecordingResult.failure('Error al detener la grabación: $e');
    } finally {
      _isRecording = false;
      _isTransitioning = false;
      _currentRecordingPath = null;
    }
  }

  /// Cancela y descarta la grabación en curso eliminando el archivo temporal
  Future<void> cancelRecording() async {
    if (!_isRecording && !_isTransitioning) return;

    _isTransitioning = true;
    try {
      await _recorder.cancel();
      if (_currentRecordingPath != null) {
        final File file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
      debugPrint('[AudioRecordingService] Grabación cancelada y descartada.');
    } catch (e) {
      debugPrint('[AudioRecordingService] Error al cancelar grabación: $e');
    } finally {
      _isRecording = false;
      _isTransitioning = false;
      _currentRecordingPath = null;
      _recordStartTime = null;
    }
  }

  /// Libera recursos del grabador
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      await _recorder.dispose();
    } catch (e) {
      debugPrint('[AudioRecordingService] Error en dispose: $e');
    }
  }
}
