import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rever/core/services/audio_reverse_service.dart';

/// Utilidad para construir archivos WAV sintéticos en memoria para pruebas
Uint8List createSyntheticPcmWav({
  required int numChannels,
  required int sampleRate,
  required int bitsPerSample,
  required List<List<int>>
  channelFrames, // Cada elemento es una lista de muestras por canal [L, R] o [Mono]
}) {
  final int bytesPerSample = bitsPerSample ~/ 8;
  final int blockAlign = numChannels * bytesPerSample;
  final int totalFrames = channelFrames.length;
  final int dataSize = totalFrames * blockAlign;

  final Uint8List payload = Uint8List(dataSize);
  final ByteData payloadData = ByteData.sublistView(payload);

  for (int f = 0; f < totalFrames; f++) {
    final frame = channelFrames[f];
    for (int ch = 0; ch < numChannels; ch++) {
      final int offset = (f * blockAlign) + (ch * bytesPerSample);
      final int sampleValue = frame[ch];

      if (bitsPerSample == 16) {
        payloadData.setInt16(offset, sampleValue, Endian.little);
      } else if (bitsPerSample == 8) {
        payloadData.setUint8(offset, sampleValue);
      }
    }
  }

  final metadata = AudioMetadata(
    audioFormat: 1, // PCM
    numChannels: numChannels,
    sampleRate: sampleRate,
    byteRate: sampleRate * blockAlign,
    blockAlign: blockAlign,
    bitsPerSample: bitsPerSample,
    dataSize: dataSize,
    totalFrames: totalFrames,
    duration: Duration(milliseconds: (totalFrames * 1000) ~/ sampleRate),
  );

  return AudioReverseService.buildCanonicalWav(
    metadata: metadata,
    pcmPayload: payload,
  );
}

void main() {
  const service = AudioReverseService();

  group('AudioReverseService - Procesamiento Digital de Señales (DSP)', () {
    test(
      'Invierte temporalmente muestras PCM mono de 16 bits sin corromper bytes',
      () {
        // 4 muestras mono conocidas: 100, 200, 300, 400
        final List<int> originalSamples = [100, 200, 300, 400];
        final List<List<int>> frames = originalSamples.map((s) => [s]).toList();

        final Uint8List wavBytes = createSyntheticPcmWav(
          numChannels: 1,
          sampleRate: 44100,
          bitsPerSample: 16,
          channelFrames: frames,
        );

        final wavInfo = AudioReverseService.parseWavStructure(wavBytes);
        final Uint8List reversedWavBytes =
            AudioReverseService.reversePcmSamples(
              fileBytes: wavBytes,
              wavInfo: wavInfo,
            );

        // Decodificar el WAV resultante
        final reversedWavInfo = AudioReverseService.parseWavStructure(
          reversedWavBytes,
        );
        final ByteData reversedData = ByteData.sublistView(reversedWavBytes);

        final List<int> extractedReversedSamples = [];
        for (int i = 0; i < reversedWavInfo.metadata.totalFrames; i++) {
          final int offset = reversedWavInfo.dataOffset + (i * 2);
          extractedReversedSamples.add(
            reversedData.getInt16(offset, Endian.little),
          );
        }

        // Verificación 1: Muestras exactamente invertidas en el tiempo
        expect(extractedReversedSamples, [400, 300, 200, 100]);

        // Verificación 2: El orden Little-Endian de cada muestra individual se preserva intacto
        // 400 en 16 bits = 0x0190 -> low byte 0x90 (144), high byte 0x01 (1)
        final int firstSampleOffset = reversedWavInfo.dataOffset;
        expect(reversedWavBytes[firstSampleOffset], 0x90);
        expect(reversedWavBytes[firstSampleOffset + 1], 0x01);
      },
    );

    test(
      'Invierte audio estéreo conservando canales L/R sin intercambiarlos',
      () {
        // 3 frames estéreo [L, R]
        // Frame 0: [1000, -1000]
        // Frame 1: [2000, -2000]
        // Frame 2: [3000, -3000]
        final List<List<int>> stereoFrames = [
          [1000, -1000],
          [2000, -2000],
          [3000, -3000],
        ];

        final Uint8List wavBytes = createSyntheticPcmWav(
          numChannels: 2,
          sampleRate: 44100,
          bitsPerSample: 16,
          channelFrames: stereoFrames,
        );

        final wavInfo = AudioReverseService.parseWavStructure(wavBytes);
        final Uint8List reversedWavBytes =
            AudioReverseService.reversePcmSamples(
              fileBytes: wavBytes,
              wavInfo: wavInfo,
            );

        final reversedWavInfo = AudioReverseService.parseWavStructure(
          reversedWavBytes,
        );
        final ByteData reversedData = ByteData.sublistView(reversedWavBytes);

        final List<List<int>> extractedStereoFrames = [];
        for (int i = 0; i < reversedWavInfo.metadata.totalFrames; i++) {
          final int frameOffset = reversedWavInfo.dataOffset + (i * 4);
          final int left = reversedData.getInt16(frameOffset, Endian.little);
          final int right = reversedData.getInt16(
            frameOffset + 2,
            Endian.little,
          );
          extractedStereoFrames.add([left, right]);
        }

        // Verificación: El orden temporal es [Frame 2, Frame 1, Frame 0]
        // y en cada frame, Left sigue siendo positivo y Right sigue siendo negativo
        expect(extractedStereoFrames, [
          [3000, -3000],
          [2000, -2000],
          [1000, -1000],
        ]);
      },
    );

    test(
      'Conserva con exactitud frecuencia de muestreo, canales, bit depth y duración',
      () {
        const int expectedSampleRate = 48000;
        const int expectedChannels = 1;
        const int expectedBits = 16;
        final frames = List.generate(
          480,
          (i) => [i * 10],
        ); // 480 frames a 48000 Hz = 10ms

        final Uint8List wavBytes = createSyntheticPcmWav(
          numChannels: expectedChannels,
          sampleRate: expectedSampleRate,
          bitsPerSample: expectedBits,
          channelFrames: frames,
        );

        final wavInfo = AudioReverseService.parseWavStructure(wavBytes);
        final Uint8List reversedWavBytes =
            AudioReverseService.reversePcmSamples(
              fileBytes: wavBytes,
              wavInfo: wavInfo,
            );

        final reversedWavInfo = AudioReverseService.parseWavStructure(
          reversedWavBytes,
        );
        final meta = reversedWavInfo.metadata;

        expect(meta.sampleRate, expectedSampleRate);
        expect(meta.numChannels, expectedChannels);
        expect(meta.bitsPerSample, expectedBits);
        expect(meta.totalFrames, 480);
        expect(meta.duration.inMilliseconds, 10);
      },
    );

    test('Detecta y arroja excepción en archivos corruptos o no WAV', () {
      final Uint8List randomBytes = Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
      ]);

      expect(
        () => AudioReverseService.parseWavStructure(randomBytes),
        throwsA(isA<FormatException>()),
      );

      // Archivo con cabecera no-RIFF
      final Uint8List fakeRiff = Uint8List(44);
      fakeRiff.setRange(0, 4, 'MP3!'.codeUnits);
      expect(
        () => AudioReverseService.parseWavStructure(fakeRiff),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'reverseAudioFile procesa archivo en disco de extremo a extremo sin sobrescribir original',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('rever_dsp_test_');
        final inputPath = '${tempDir.path}/original.wav';
        final outputPath = '${tempDir.path}/reversed.wav';

        final sampleFrames = [
          [50],
          [150],
          [250],
          [350],
        ];
        final wavBytes = createSyntheticPcmWav(
          numChannels: 1,
          sampleRate: 44100,
          bitsPerSample: 16,
          channelFrames: sampleFrames,
        );

        File(inputPath).writeAsBytesSync(wavBytes);

        final result = await service.reverseAudioFile(
          inputPath,
          outputPath: outputPath,
        );

        expect(result.isSuccess, isTrue);
        expect(result.originalPath, inputPath);
        expect(result.reversedPath, outputPath);
        expect(File(outputPath).existsSync(), isTrue);

        // El archivo original permanece intacto
        expect(File(inputPath).existsSync(), isTrue);
        expect(File(inputPath).readAsBytesSync(), wavBytes);

        // Validar muestras del archivo invertido en disco
        final reversedBytes = File(outputPath).readAsBytesSync();
        final reversedInfo = AudioReverseService.parseWavStructure(
          reversedBytes,
        );
        final ByteData data = ByteData.sublistView(reversedBytes);

        final List<int> samples = [];
        for (int i = 0; i < reversedInfo.metadata.totalFrames; i++) {
          samples.add(
            data.getInt16(reversedInfo.dataOffset + (i * 2), Endian.little),
          );
        }
        expect(samples, [350, 250, 150, 50]);

        // Limpieza
        tempDir.deleteSync(recursive: true);
      },
    );
  });
}
