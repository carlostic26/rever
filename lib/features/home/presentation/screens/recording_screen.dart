import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/admob_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/audio_recording_service.dart';
import '../../../../core/services/audio_reverse_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/home_audio_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/three_dots_indicator.dart';

enum CurrentlyPlaying { none, original, reverse }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Servicios
  late final AudioRecordingService _recordingService;
  late final AudioReverseService _reverseService;
  late final AudioPlayerService _playerService;

  // Suscripciones de reproducción
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Estado del flujo de audio
  HomeAudioState _audioState = HomeAudioState.initial;

  // Pista actualmente en reproducción
  CurrentlyPlaying _currentPlaying = CurrentlyPlaying.none;

  // Gestos táctiles y cronómetro (tipo WhatsApp)
  int? _activePointerId;
  DateTime? _pointerDownTime;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Banner Ad de AdMob para la pantalla de grabación
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _recordingService = InjectionContainer.createAudioRecordingService();
    _reverseService = InjectionContainer.createAudioReverseService();
    _playerService = InjectionContainer.createAudioPlayerService();

    _setupPlayerListeners();
    _loadBannerAd();
  }

  void _setupPlayerListeners() {
    _playerStateSubscription = _playerService.playerStateStream.listen((
      playerState,
    ) {
      if (!mounted) return;
      final bool isPlaying = playerState.playing;
      final bool isCompleted =
          playerState.processingState == ProcessingState.completed;

      if (!isPlaying || isCompleted) {
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[RecordingScreen] Error cargando BannerAd: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _recordingTimer?.cancel();
    _playerService.dispose();
    _recordingService.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mic_off_rounded, color: AppColors.violetAccent),
            const SizedBox(width: 10),
            Text(
              'Permiso de Micrófono',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.darkTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Rever Verbal requiere acceso al micrófono para grabar tu voz. '
          'Por favor, habilítalo manualmente desde los ajustes de la aplicación.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.darkTextSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: AppColors.darkTextMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _recordingService.openDeviceSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violetAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Abrir Ajustes',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gesto: Iniciar grabación en Container 1 (inmediato al tocar)
  Future<void> _handlePointerDown(PointerDownEvent event) async {
    // Si algún reproductor está activo, detenerlo
    if (_currentPlaying != CurrentlyPlaying.none) {
      await _playerService.stopAndRelease();
      setState(() {
        _currentPlaying = CurrentlyPlaying.none;
      });
    }

    if (_activePointerId != null ||
        _recordingService.isRecording ||
        _recordingService.isTransitioning) {
      return;
    }

    _activePointerId = event.pointer;
    _pointerDownTime = DateTime.now();

    final MicrophonePermissionStatus permStatus = await _recordingService
        .checkAndRequestPermission();

    if (!mounted) return;

    if (permStatus == MicrophonePermissionStatus.permanentlyDenied) {
      _activePointerId = null;
      _showPermanentlyDeniedDialog();
      return;
    } else if (permStatus != MicrophonePermissionStatus.granted) {
      _activePointerId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se requiere permiso de micrófono para grabar tu voz.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_activePointerId == null) return;

    final bool started = await _recordingService.startRecording();
    if (!mounted) return;

    if (!started) {
      _activePointerId = null;
      return;
    }

    _recordingDuration = Duration.zero;
    setState(() {
      _audioState = HomeAudioState(
        status: AudioSessionStatus.recording,
        statusText: 'Grabando audio...',
        recordedDuration: _recordingDuration,
      );
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) return;
      setState(() {
        _recordingDuration += const Duration(milliseconds: 100);
        _audioState = _audioState.copyWith(
          recordedDuration: _recordingDuration,
        );
      });
    });

    if (_activePointerId == null) {
      _finishOrCancelRecording();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _finishOrCancelRecording();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _recordingTimer?.cancel();
    _recordingService.cancelRecording();

    if (mounted) {
      setState(() {
        _audioState = HomeAudioState.initial;
      });
    }
  }

  // Al soltar el primer container: detener grabación y activar procesamiento con 3 puntos
  Future<void> _finishOrCancelRecording() async {
    _recordingTimer?.cancel();

    final DateTime now = DateTime.now();
    final Duration holdDuration = _pointerDownTime != null
        ? now.difference(_pointerDownTime!)
        : Duration.zero;

    if (holdDuration < const Duration(milliseconds: 400)) {
      await _recordingService.cancelRecording();
      if (mounted) {
        setState(() {
          _audioState = HomeAudioState.initial;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mantén pulsado para grabar.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.darkSurfaceCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Detener la grabación física
    final AudioRecordingResult recordResult = await _recordingService
        .stopRecording();
    if (!mounted) return;

    if (recordResult.isSuccess && recordResult.filePath != null) {
      // Activar inmediatamente:
      // 1. Container 1 muestra los 3 puntos animados ("Invirtiendo audio...")
      // 2. Container 2 se habilita de inmediato con el audio original listo
      setState(() {
        _audioState = HomeAudioState(
          status: AudioSessionStatus.processing,
          statusText: 'Invirtiendo audio...',
          audioPath: recordResult.filePath,
          recordedDuration: recordResult.duration,
        );
      });

      // Procesar en segundo plano (Isolate)
      final AudioReverseResult reverseResult = await _reverseService
          .reverseAudioFile(recordResult.filePath!);

      if (!mounted) return;

      if (reverseResult.isSuccess && reverseResult.reversedPath != null) {
        setState(() {
          _audioState = HomeAudioState(
            status: AudioSessionStatus.ready,
            statusText: '¡Audio invertido listo!',
            audioPath: recordResult.filePath,
            reversedAudioPath: reverseResult.reversedPath,
            recordedDuration:
                reverseResult.metadata?.duration ?? recordResult.duration,
          );
        });
      } else {
        setState(() {
          _audioState = HomeAudioState(
            status: AudioSessionStatus.error,
            statusText: 'Error al procesar reverso',
            audioPath: recordResult.filePath,
            recordedDuration: recordResult.duration,
          );
        });
      }
    } else {
      setState(() {
        _audioState = HomeAudioState.initial;
      });
    }
  }

  // Reproducir/pausar audio normal (Container 2)
  Future<void> _togglePlayOriginal() async {
    final String? originalPath = _audioState.audioPath;
    if (originalPath == null) return;

    try {
      if (_currentPlaying == CurrentlyPlaying.original) {
        await _playerService.pause();
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
      } else {
        if (_currentPlaying == CurrentlyPlaying.reverse) {
          await _playerService.stopAndRelease();
        }
        await _playerService.loadAudioFile(originalPath);
        await _playerService.play();
        setState(() {
          _currentPlaying = CurrentlyPlaying.original;
        });
      }
    } catch (e) {
      debugPrint('[RecordingScreen] Error reproduciendo original: $e');
    }
  }

  // Reproducir/pausar audio en reversa (Container 3)
  Future<void> _togglePlayReverse() async {
    final String? reversedPath = _audioState.reversedAudioPath;
    if (reversedPath == null) return;

    try {
      if (_currentPlaying == CurrentlyPlaying.reverse) {
        await _playerService.pause();
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
      } else {
        if (_currentPlaying == CurrentlyPlaying.original) {
          await _playerService.stopAndRelease();
        }
        await _playerService.loadAudioFile(reversedPath);
        await _playerService.play();
        setState(() {
          _currentPlaying = CurrentlyPlaying.reverse;
        });
      }
    } catch (e) {
      debugPrint('[RecordingScreen] Error reproduciendo reverso: $e');
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bool isRecording = _audioState.isRecording;
    final bool isProcessing = _audioState.isProcessing;
    final bool hasOriginal = _audioState.audioPath != null;
    final bool hasReversed = _audioState.hasReversedAudio;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppColors.darkTextPrimary,
            size: 26,
          ),
          tooltip: 'Abrir menú',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.cardBorderGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.violetAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Estudio Rever Verbal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.darkTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Column con 3 children (Containers de colores diferentes que funcionan como botones)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  children: [
                    // 1. CONTAINER 1: Botón de Grabación (Tocar para grabar / 3 puntos al soltar)
                    Expanded(
                      flex: 1,
                      child: Listener(
                        onPointerDown: _handlePointerDown,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerCancel,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: isRecording
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFDC2626),
                                      Color(0xFF991B1B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : (isProcessing
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF581C87),
                                            Color(0xFF3B0764),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFF5B21B6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isRecording
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF7C3AED))
                                        .withValues(alpha: 0.35),
                                blurRadius: isRecording ? 20 : 12,
                                spreadRadius: isRecording ? 3 : 1,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isRecording ? 0.6 : 0.2,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: isRecording
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.fiber_manual_record_rounded,
                                            color: Colors.white,
                                            size: 42,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Grabando: ${_formatDuration(_recordingDuration)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Suelta para procesar',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      )
                                    : (isProcessing
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Animación de procesamiento con 3 puntos solicitada
                                                const ThreeDotsIndicator(
                                                  dotColor: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Invirtiendo audio...',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  'Muestras en reversa en segundo plano',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.mic_rounded,
                                                  color: Colors.white,
                                                  size: 44,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Mantén presionado para grabar',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  hasOriginal
                                                      ? 'Toca de nuevo para re-grabar'
                                                      : 'Habla y suelta para revertir',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. CONTAINER 2: Reproductor Normal (Habilitado tan pronto se graba, incluso mientras procesa el reverso)
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: hasOriginal ? _togglePlayOriginal : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: hasOriginal
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1E40AF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF1E293B,
                                      ).withValues(alpha: 0.6),
                                      const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.6),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: hasOriginal
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: hasOriginal
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppColors.darkSurfaceStrong,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentPlaying ==
                                              CurrentlyPlaying.original
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: hasOriginal
                                          ? Colors.white
                                          : AppColors.darkTextMuted,
                                      size: 46,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reproducir Audio Normal',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: hasOriginal
                                            ? Colors.white
                                            : AppColors.darkTextMuted,
                                      ),
                                    ),
                                    Text(
                                      hasOriginal
                                          ? (_currentPlaying ==
                                                    CurrentlyPlaying.original
                                                ? 'Pausar audio normal'
                                                : 'Sonido original grabado')
                                          : 'Disponible tras grabar un audio',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: hasOriginal
                                            ? Colors.white70
                                            : AppColors.darkTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. CONTAINER 3: Reproductor en Reversa (Ícono de play al revés, habilitado al terminar la inversión)
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: hasReversed ? _togglePlayReverse : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: hasReversed
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0D9488),
                                      Color(0xFF047857),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF1E293B,
                                      ).withValues(alpha: 0.6),
                                      const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.6),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: hasReversed
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0D9488,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: hasReversed
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppColors.darkSurfaceStrong,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Ícono de reproducción al revés (play invertido horizontalmente ◀)
                                    Transform.flip(
                                      flipX: true,
                                      child: Icon(
                                        _currentPlaying ==
                                                CurrentlyPlaying.reverse
                                            ? Icons.pause_circle_filled_rounded
                                            : Icons.play_circle_fill_rounded,
                                        color: hasReversed
                                            ? Colors.white
                                            : AppColors.darkTextMuted,
                                        size: 46,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reproducir en Reversa',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: hasReversed
                                            ? Colors.white
                                            : AppColors.darkTextMuted,
                                      ),
                                    ),
                                    Text(
                                      hasReversed
                                          ? (_currentPlaying ==
                                                    CurrentlyPlaying.reverse
                                                ? 'Pausar audio en reversa'
                                                : 'Sonido invertido listo')
                                          : (isProcessing
                                                ? 'Generando reverso...'
                                                : 'Disponible al terminar de invertir'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: hasReversed
                                            ? Colors.white70
                                            : AppColors.darkTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AdMob Banner en la parte inferior exclusivo de la pantalla de grabación
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: const BoxDecoration(
                  color: AppColors.darkBackground,
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
