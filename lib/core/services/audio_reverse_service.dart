import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Metadatos técnicos extraídos de un archivo de audio WAV PCM
class AudioMetadata {
  final int audioFormat;
  final int numChannels;
  final int sampleRate;
  final int byteRate;
  final int blockAlign;
  final int bitsPerSample;
  final int dataSize;
  final int totalFrames;
  final Duration duration;

  const AudioMetadata({
    required this.audioFormat,
    required this.numChannels,
    required this.sampleRate,
    required this.byteRate,
    required this.blockAlign,
    required this.bitsPerSample,
    required this.dataSize,
    required this.totalFrames,
    required this.duration,
  });

  bool get isPcm => audioFormat == 1;
  bool get isMono => numChannels == 1;
  bool get isStereo => numChannels == 2;

  @override
  String toString() {
    return 'AudioMetadata(channels: $numChannels, sampleRate: ${sampleRate}Hz, '
        'bits: $bitsPerSample, frames: $totalFrames, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Información interna de estructura y ubicación de datos WAV
class WavStructureInfo {
  final AudioMetadata metadata;
  final int dataOffset;
  final int dataSize;

  const WavStructureInfo({
    required this.metadata,
    required this.dataOffset,
    required this.dataSize,
  });
}

/// Resultado de la operación de inversión de audio
class AudioReverseResult {
  final bool isSuccess;
  final String? originalPath;
  final String? reversedPath;
  final AudioMetadata? metadata;
  final String? errorMessage;

  const AudioReverseResult._({
    required this.isSuccess,
    this.originalPath,
    this.reversedPath,
    this.metadata,
    this.errorMessage,
  });

  factory AudioReverseResult.success({
    required String originalPath,
    required String reversedPath,
    required AudioMetadata metadata,
  }) {
    return AudioReverseResult._(
      isSuccess: true,
      originalPath: originalPath,
      reversedPath: reversedPath,
      metadata: metadata,
    );
  }

  factory AudioReverseResult.failure(
    String errorMessage, {
    String? originalPath,
  }) {
    return AudioReverseResult._(
      isSuccess: false,
      originalPath: originalPath,
      errorMessage: errorMessage,
    );
  }
}

/// Parámetros enviados al Isolate para no bloquear el hilo principal de la UI
class _ReverseTaskParams {
  final String inputPath;
  final String outputPath;

  const _ReverseTaskParams({required this.inputPath, required this.outputPath});
}

/// Servicio encargado del procesamiento digital de señales:
/// Validación, decodificación PCM, inversión temporal de muestras y generación de archivo WAV
class AudioReverseService {
  const AudioReverseService();

  /// Invierte temporalmente el archivo de audio [inputPath] y genera [outputPath]
  Future<AudioReverseResult> reverseAudioFile(
    String inputPath, {
    String? outputPath,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync()) {
        return AudioReverseResult.failure(
          'El archivo de audio original no existe: $inputPath',
          originalPath: inputPath,
        );
      }

      final int fileSize = inputFile.lengthSync();
      if (fileSize < 44) {
        return AudioReverseResult.failure(
          'El archivo de audio está vacío o corrupto (tamaño: $fileSize bytes).',
          originalPath: inputPath,
        );
      }

      // Si no se proporcionó ruta de salida, generar una única en documentos
      String targetOutputPath = outputPath ?? '';
      if (targetOutputPath.isEmpty) {
        final Directory dir = await getApplicationDocumentsDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        targetOutputPath = '${dir.path}/rever_rev_$timestamp.wav';
      }

      // Ejecución en Isolate para garantizar 0 bloqueos en la interfaz
      final result = await compute(
        _executeReversalInIsolate,
        _ReverseTaskParams(inputPath: inputPath, outputPath: targetOutputPath),
      );

      return result;
    } catch (e, stack) {
      debugPrint(
        '[AudioReverseService] Error durante la inversión: $e\n$stack',
      );
      return AudioReverseResult.failure(
        'Error al procesar el audio: $e',
        originalPath: inputPath,
      );
    }
  }

  /// Función estática ejecutada en segundo plano por el Isolate
  static AudioReverseResult _executeReversalInIsolate(
    _ReverseTaskParams params,
  ) {
    try {
      final inputFile = File(params.inputPath);
      final Uint8List fileBytes = inputFile.readAsBytesSync();

      // 1. Decodificar y validar estructura RIFF/WAVE
      final WavStructureInfo wavInfo = parseWavStructure(fileBytes);

      // 2. Procesar inversión temporal de las muestras
      final Uint8List reversedWavBytes = reversePcmSamples(
        fileBytes: fileBytes,
        wavInfo: wavInfo,
      );

      // 3. Escribir archivo resultante
      final outputFile = File(params.outputPath);
      outputFile.writeAsBytesSync(reversedWavBytes, flush: true);

      // 4. Validar archivo de salida
      if (!outputFile.existsSync() || outputFile.lengthSync() == 0) {
        return AudioReverseResult.failure(
          'No se pudo generar el archivo de audio invertido.',
          originalPath: params.inputPath,
        );
      }

      return AudioReverseResult.success(
        originalPath: params.inputPath,
        reversedPath: params.outputPath,
        metadata: wavInfo.metadata,
      );
    } catch (e) {
      return AudioReverseResult.failure(
        e.toString(),
        originalPath: params.inputPath,
      );
    }
  }

  /// Analiza la estructura RIFF WAVE e itera los chunks dinámicamente
  static WavStructureInfo parseWavStructure(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const FormatException(
        'Archivo demasiado pequeño para ser un archivo RIFF.',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes);

    // 1. Validar encabezado RIFF
    final String riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
    if (riffHeader != 'RIFF') {
      throw FormatException(
        'Formato de contenedor inválido: se esperaba "RIFF", pero se encontró "$riffHeader".',
      );
    }

    final String waveHeader = String.fromCharCodes(bytes.sublist(8, 12));
    if (waveHeader != 'WAVE') {
      throw FormatException(
        'Formato inválido: se esperaba "WAVE", pero se encontró "$waveHeader".',
      );
    }

    int offset = 12;
    int? audioFormat;
    int? numChannels;
    int? sampleRate;
    int? byteRate;
    int? blockAlign;
    int? bitsPerSample;
    int? dataOffset;
    int? dataSize;

    // 2. Iterar chunks sin suponer posiciones fijas de 44 bytes
    while (offset + 8 <= bytes.length) {
      final String chunkId = String.fromCharCodes(
        bytes.sublist(offset, offset + 4),
      );
      final int chunkSize = byteData.getUint32(offset + 4, Endian.little);
      final int chunkDataOffset = offset + 8;

      if (chunkId == 'fmt ') {
        if (chunkSize < 16) {
          throw const FormatException(
            'Subchunk "fmt " demasiado pequeño para PCM.',
          );
        }

        audioFormat = byteData.getUint16(chunkDataOffset, Endian.little);
        numChannels = byteData.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = byteData.getUint32(chunkDataOffset + 4, Endian.little);
        byteRate = byteData.getUint32(chunkDataOffset + 8, Endian.little);
        blockAlign = byteData.getUint16(chunkDataOffset + 12, Endian.little);
        bitsPerSample = byteData.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataOffset;
        dataSize = chunkSize;
      }

      // Los chunks en RIFF se alinean a 2 bytes (padding byte si chunkSize es impar)
      final int paddedSize = chunkSize + (chunkSize % 2);
      offset = chunkDataOffset + paddedSize;
    }

    if (audioFormat == null ||
        numChannels == null ||
        sampleRate == null ||
        byteRate == null ||
        blockAlign == null ||
        bitsPerSample == null) {
      throw const FormatException(
        'No se encontró el chunk "fmt " con los parámetros del audio.',
      );
    }

    if (dataOffset == null || dataSize == null) {
      throw const FormatException(
        'No se encontró el chunk "data" con las muestras del audio.',
      );
    }

    // Validar compatibilidad de formato (PCM lineal no comprimido = 1)
    if (audioFormat != 1) {
      throw FormatException(
        'Formato no compatible ($audioFormat). Rever Verbal procesa audio PCM sin pérdidas (formato 1).',
      );
    }

    // Ajustar dataSize si el archivo fue truncado o tiene bytes adicionales
    final int availableDataBytes = bytes.length - dataOffset;
    final int effectiveDataSize = dataSize > availableDataBytes
        ? availableDataBytes
        : dataSize;

    final int calculatedBlockAlign = numChannels * (bitsPerSample ~/ 8);
    final int finalBlockAlign = blockAlign > 0
        ? blockAlign
        : calculatedBlockAlign;

    final int totalFrames = effectiveDataSize ~/ finalBlockAlign;
    final int durationMs = (totalFrames * 1000) ~/ sampleRate;

    final metadata = AudioMetadata(
      audioFormat: audioFormat,
      numChannels: numChannels,
      sampleRate: sampleRate,
      byteRate: byteRate,
      blockAlign: finalBlockAlign,
      bitsPerSample: bitsPerSample,
      dataSize: totalFrames * finalBlockAlign,
      totalFrames: totalFrames,
      duration: Duration(milliseconds: durationMs),
    );

    return WavStructureInfo(
      metadata: metadata,
      dataOffset: dataOffset,
      dataSize: totalFrames * finalBlockAlign,
    );
  }

  /// Invierte temporalmente el orden de los instantes/frames conservando:
  /// - Canales (Left / Right no se intercambian).
  /// - Orden de bytes Little-Endian de cada muestra individual (no se corrompe el valor numérico).
  static Uint8List reversePcmSamples({
    required Uint8List fileBytes,
    required WavStructureInfo wavInfo,
  }) {
    final metadata = wavInfo.metadata;
    final int blockAlign = metadata.blockAlign;
    final int totalFrames = metadata.totalFrames;
    final int payloadSize = totalFrames * blockAlign;

    // Buffer para los datos invertidos
    final Uint8List reversedPayload = Uint8List(payloadSize);
    final int dataStart = wavInfo.dataOffset;

    // Inversión temporal: y[n] = x[N - 1 - n]
    // Se copia cada frame completo (con sus respectivos canales y bytes) en orden cronológico inverso
    for (int frame = 0; frame < totalFrames; frame++) {
      final int srcFrameOffset = dataStart + (frame * blockAlign);
      final int dstFrameOffset = (totalFrames - 1 - frame) * blockAlign;

      for (int b = 0; b < blockAlign; b++) {
        reversedPayload[dstFrameOffset + b] = fileBytes[srcFrameOffset + b];
      }
    }

    // Construcción de archivo WAV canónico final de 44 bytes + payload
    return buildCanonicalWav(metadata: metadata, pcmPayload: reversedPayload);
  }

  /// Construye un archivo WAV RIFF canónico estándar
  static Uint8List buildCanonicalWav({
    required AudioMetadata metadata,
    required Uint8List pcmPayload,
  }) {
    const int headerSize = 44;
    final int totalFileSize = headerSize + pcmPayload.length;
    final Uint8List wavBytes = Uint8List(totalFileSize);
    final ByteData byteData = ByteData.sublistView(wavBytes);

    // 1. Chunk "RIFF"
    wavBytes[0] = 0x52; // 'R'
    wavBytes[1] = 0x49; // 'I'
    wavBytes[2] = 0x46; // 'F'
    wavBytes[3] = 0x46; // 'F'
    byteData.setUint32(4, totalFileSize - 8, Endian.little);

    // 2. Format "WAVE"
    wavBytes[8] = 0x57; // 'W'
    wavBytes[9] = 0x41; // 'A'
    wavBytes[10] = 0x56; // 'V'
    wavBytes[11] = 0x45; // 'E'

    // 3. Subchunk "fmt "
    wavBytes[12] = 0x66; // 'f'
    wavBytes[13] = 0x6D; // 'm'
    wavBytes[14] = 0x74; // 't'
    wavBytes[15] = 0x20; // ' '
    byteData.setUint32(
      16,
      16,
      Endian.little,
    ); // Tamaño subchunk fmt PCM estándar
    byteData.setUint16(20, metadata.audioFormat, Endian.little); // 1 = PCM
    byteData.setUint16(22, metadata.numChannels, Endian.little);
    byteData.setUint32(24, metadata.sampleRate, Endian.little);
    byteData.setUint32(28, metadata.byteRate, Endian.little);
    byteData.setUint16(32, metadata.blockAlign, Endian.little);
    byteData.setUint16(34, metadata.bitsPerSample, Endian.little);

    // 4. Subchunk "data"
    wavBytes[36] = 0x64; // 'd'
    wavBytes[37] = 0x61; // 'a'
    wavBytes[38] = 0x74; // 't'
    wavBytes[39] = 0x61; // 'a'
    byteData.setUint32(40, pcmPayload.length, Endian.little);

    // 5. Payload de muestras
    wavBytes.setRange(44, totalFileSize, pcmPayload);

    return wavBytes;
  }
}
