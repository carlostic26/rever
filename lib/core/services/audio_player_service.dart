import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Servicio encargado de la reproducción de audio local usando just_audio
class AudioPlayerService {
  final AudioPlayer _player;
  String? _loadedFilePath;

  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  String? get loadedFilePath => _loadedFilePath;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Carga el archivo de audio local para su reproducción
  Future<Duration?> loadAudioFile(String filePath) async {
    try {
      if (_player.playing) {
        await _player.stop();
      }
      _loadedFilePath = filePath;
      final duration = await _player.setFilePath(filePath);
      debugPrint(
        '[AudioPlayerService] Archivo cargado correctamente: $filePath (duración: $duration)',
      );
      return duration;
    } catch (e) {
      debugPrint(
        '[AudioPlayerService] Error al cargar archivo de audio ($filePath): $e',
      );
      _loadedFilePath = null;
      rethrow;
    }
  }

  /// Inicia o reanuda la reproducción. Si llegó al final, reinicia desde el segundo 0.
  Future<void> play() async {
    try {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } catch (e) {
      debugPrint('[AudioPlayerService] Error al reproducir audio: $e');
      rethrow;
    }
  }

  /// Pausa la reproducción activa
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('[AudioPlayerService] Error al pausar audio: $e');
      rethrow;
    }
  }

  /// Cambia la posición temporal de reproducción
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('[AudioPlayerService] Error en seek: $e');
    }
  }

  /// Detiene la reproducción y libera el descriptor del archivo en disco
  Future<void> stopAndRelease() async {
    try {
      if (_player.playing) {
        await _player.stop();
      }
      // Detener y resetear la fuente para desbloquear el archivo en plataformas como Windows/Android
      await _player.seek(Duration.zero);
      _loadedFilePath = null;
    } catch (e) {
      debugPrint('[AudioPlayerService] Error al detener y liberar: $e');
    }
  }

  /// Libera por completo el reproductor de audio
  Future<void> dispose() async {
    try {
      await stopAndRelease();
      await _player.dispose();
    } catch (e) {
      debugPrint('[AudioPlayerService] Error en dispose: $e');
    }
  }
}
