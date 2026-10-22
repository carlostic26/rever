import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rever/features/home/presentation/models/home_audio_state.dart';
import 'package:rever/features/home/presentation/screens/home_screen.dart';
import 'package:rever/features/home/presentation/widgets/audio_spectrum_wave.dart';
import 'package:rever/features/home/presentation/widgets/audio_state_indicator.dart';
import 'package:rever/features/home/presentation/widgets/microphone_button.dart';
import 'package:rever/features/home/presentation/widgets/reverse_audio_player_panel.dart';
import 'package:rever/features/home/presentation/widgets/three_dots_indicator.dart';
import 'package:rever/features/loading/presentation/widgets/counting_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CountingAnimation renders initial number 0', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CountingAnimation(endCount: 100, textSize: 10)),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('ThreeDotsIndicator renders animated dots', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThreeDotsIndicator())),
    );

    expect(find.byType(ThreeDotsIndicator), findsOneWidget);
  });

  testWidgets('AudioSpectrumWave renders and paints spectrum bars', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioSpectrumWave(barColor: Color(0xFF7F1D1D), isActive: true),
        ),
      ),
    );

    expect(find.byType(AudioSpectrumWave), findsOneWidget);
  });

  testWidgets(
    'HomeScreen renders 2 full sections: Comenzar and Grabaciones guardadas',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Grabaciones guardadas'), findsOneWidget);
      expect(find.text('Retrovoz'), findsOneWidget);
      expect(find.text('Sonidos en reversa'), findsOneWidget);
    },
  );

  testWidgets('AudioStateIndicator displays statusText', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioStateIndicator(state: HomeAudioState.initial),
        ),
      ),
    );

    expect(find.text('Listo para grabar'), findsOneWidget);
  });

  testWidgets('MicrophoneButton renders help text and idle icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MicrophoneButton(isRecording: false)),
      ),
    );

    expect(find.text('Mantén pulsado para grabar'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
  });

  testWidgets('MicrophoneButton renders recording state and duration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MicrophoneButton(
            isRecording: true,
            recordingDuration: Duration(seconds: 3, milliseconds: 400),
          ),
        ),
      ),
    );

    expect(find.text('Suelta para finalizar la grabación'), findsOneWidget);
    expect(find.text('00:03.4'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('ReverseAudioPlayerPanel renders waiting placeholder initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReverseAudioPlayerPanel(state: HomeAudioState.initial),
        ),
      ),
    );

    expect(find.text('Tu audio en reversa'), findsOneWidget);
    expect(find.text('En espera'), findsOneWidget);
    expect(
      find.text('Mantén presionado el micrófono para grabar'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ReverseAudioPlayerPanel renders player controls and "Grabar otro" when ready',
    (WidgetTester tester) async {
      const readyState = HomeAudioState(
        status: AudioSessionStatus.ready,
        statusText: '¡Audio invertido listo para escuchar!',
        audioPath: '/mock/path/original.wav',
        reversedAudioPath: '/mock/path/rever_rev_12345.wav',
        recordedDuration: Duration(seconds: 4),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReverseAudioPlayerPanel(
              state: readyState,
              isPlaying: false,
              currentPosition: Duration(seconds: 1),
              totalDuration: Duration(seconds: 4),
            ),
          ),
        ),
      );

      expect(find.text('Tu audio en reversa'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
      expect(find.text('rever_rev_12345.wav'), findsOneWidget);
      expect(find.text('Grabar otro'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'ReverseAudioPlayerPanel renders pause button when isPlaying is true',
    (WidgetTester tester) async {
      const playingState = HomeAudioState(
        status: AudioSessionStatus.playing,
        statusText: 'Reproduciendo en reversa...',
        audioPath: '/mock/path/original.wav',
        reversedAudioPath: '/mock/path/rever_rev_12345.wav',
        recordedDuration: Duration(seconds: 4),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReverseAudioPlayerPanel(
              state: playingState,
              isPlaying: true,
              currentPosition: Duration(seconds: 2),
              totalDuration: Duration(seconds: 4),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    },
  );
}
