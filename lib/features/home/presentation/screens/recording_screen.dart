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
import '../widgets/audio_spectrum_wave.dart';
import '../widgets/three_dots_indicator.dart';

enum CurrentlyPlaying { none, original, reverse }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Servicios
  late final AudioRecordingService _recordingService;
  late final AudioReverseService _reverseService;
  late final AudioPlayerService _playerService;

  // Suscripciones de reproducción
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

  // Animación shrink para containers de reproducción durante el procesamiento
  late final AnimationController _shrinkController;
  late final Animation<double> _shrinkScale;
  late final Animation<double> _shrinkOpacity;

  // Banner Ad de AdMob para la pantalla de grabación
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _recordingService = InjectionContainer.createAudioRecordingService();
    _reverseService = InjectionContainer.createAudioReverseService();
    _playerService = InjectionContainer.createAudioPlayerService();

    // Animación shrink (contracción y opacidad/transparencia) mientras se procesa el audio
    _shrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _shrinkScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
    );
    _shrinkOpacity = Tween<double>(begin: 0.85, end: 0.45).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
    );

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
    _playerStateSubscription?.cancel();
    _recordingTimer?.cancel();
    _shrinkController.dispose();
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
          'Retrovoz requiere acceso al micrófono para grabar tu voz. '
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
    // Si se está procesando audio, bloquear cualquier interacción
    if (_audioState.isProcessing) return;

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

  // Al soltar el primer container: detener grabación y activar procesamiento con animación shrink
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
      // 1. Container 1 muestra animación de procesamiento con 3 puntos
      // 2. Containers 2 y 3 se bloquean e inician animación shrink
      setState(() {
        _audioState = HomeAudioState(
          status: AudioSessionStatus.processing,
          statusText: 'Invirtiendo audio...',
          audioPath: recordResult.filePath,
          recordedDuration: recordResult.duration,
        );
      });

      // Iniciar animación shrink continua durante el procesamiento
      _shrinkController.repeat(reverse: true);

      // Procesar en segundo plano (Isolate)
      final AudioReverseResult reverseResult = await _reverseService
          .reverseAudioFile(recordResult.filePath!);

      if (!mounted) return;

      // Detener animación shrink y restaurar tamaño completo
      _shrinkController.stop();
      _shrinkController.reset();

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
      _shrinkController.stop();
      _shrinkController.reset();
      setState(() {
        _audioState = HomeAudioState.initial;
      });
    }
  }

  // Reproducir/pausar audio normal (Container 2 - Azul)
  Future<void> _togglePlayOriginal() async {
    if (_audioState.isProcessing) return;
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

  // Reproducir/pausar audio en reversa (Container 3 - Verde)
  Future<void> _togglePlayReverse() async {
    if (_audioState.isProcessing) return;
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
              'Estudio Retrovoz',
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
            // Column con 3 children: 1. Rojo (grabar), 2. Azul (reproducir normal), 3. Verde (reproducir reverso)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: AnimatedBuilder(
                  animation: _shrinkController,
                  builder: (context, _) {
                    return Column(
                      children: [
                        // 1. CONTAINER 1 (ROJO): Botón de Grabación (Tocar para grabar / 3 puntos al soltar)
                        Expanded(
                          flex: 1,
                          child: AbsorbPointer(
                            absorbing: isProcessing,
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
                                                  Color(0xFF991B1B),
                                                  Color(0xFF7F1D1D),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFFEF4444),
                                                  Color(0xFFDC2626),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFDC2626).withValues(
                                        alpha: isRecording ? 0.45 : 0.3,
                                      ),
                                      blurRadius: isRecording ? 20 : 12,
                                      spreadRadius: isRecording ? 3 : 1,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isRecording ? 0.6 : 0.25,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    children: [
                                      // Espectro de audio animado en la base (color rojo más oscuro)
                                      Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 0,
                                        height: 38,
                                        child: AudioSpectrumWave(
                                          barColor: const Color(
                                            0xFF7F1D1D,
                                          ).withValues(alpha: 0.70),
                                          isActive: isRecording,
                                        ),
                                      ),

                                      // Contenido centralizado
                                      Center(
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .fiber_manual_record_rounded,
                                                        color: Colors.white,
                                                        size: 46,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Grabando: ${_formatDuration(_recordingDuration)}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Suelta para procesar',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                      ),
                                                    ],
                                                  )
                                                : (isProcessing
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const ThreeDotsIndicator(
                                                              dotColor:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(
                                                              height: 12,
                                                            ),
                                                            Text(
                                                              'Invirtiendo audio...',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Muestras en reversa en segundo plano',
                                                              style:
                                                                  GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ],
                                                        )
                                                      : Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons.mic_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 52,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Mantén presionado para grabar',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              hasOriginal
                                                                  ? 'Toca de nuevo para re-grabar'
                                                                  : 'Habla y suelta para revertir',
                                                              style:
                                                                  GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ],
                                                        )),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. CONTAINER 2 (AZUL): Reproductor Normal (Con espectro azul oscuro y animación shrink)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: (!isProcessing && hasOriginal)
                                ? _togglePlayOriginal
                                : null,
                            child: Transform.scale(
                              scale: isProcessing ? _shrinkScale.value : 1.0,
                              child: Opacity(
                                opacity: isProcessing
                                    ? _shrinkOpacity.value
                                    : (hasOriginal ? 1.0 : 0.55),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: isProcessing
                                        ? LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFF1E3A8A,
                                              ).withValues(alpha: 0.65),
                                              const Color(
                                                0xFF172554,
                                              ).withValues(alpha: 0.65),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : (hasOriginal
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFF2563EB),
                                                    Color(0xFF1D4ED8),
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
                                                )),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: hasOriginal && !isProcessing
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
                                      color: hasOriginal && !isProcessing
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : (isProcessing
                                                ? const Color(
                                                    0xFF3B82F6,
                                                  ).withValues(alpha: 0.4)
                                                : AppColors.darkSurfaceStrong),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        // Espectro de audio animado en la base (color azul oscuro del propio container)
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          bottom: 0,
                                          height: 38,
                                          child: AudioSpectrumWave(
                                            barColor: const Color(
                                              0xFF172554,
                                            ).withValues(alpha: 0.80),
                                            isActive:
                                                _currentPlaying ==
                                                CurrentlyPlaying.original,
                                          ),
                                        ),

                                        // Contenido centralizado
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 8,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // Ícono no circular, grande estilo mic
                                                  Icon(
                                                    _currentPlaying ==
                                                            CurrentlyPlaying
                                                                .original
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .play_arrow_rounded,
                                                    color:
                                                        hasOriginal &&
                                                            !isProcessing
                                                        ? Colors.white
                                                        : (isProcessing
                                                              ? Colors.white70
                                                              : AppColors
                                                                    .darkTextMuted),
                                                    size: 54,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Reproducir Audio Normal',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          hasOriginal &&
                                                              !isProcessing
                                                          ? Colors.white
                                                          : (isProcessing
                                                                ? Colors.white70
                                                                : AppColors
                                                                      .darkTextMuted),
                                                    ),
                                                  ),
                                                  Text(
                                                    isProcessing
                                                        ? 'Procesando sonido...'
                                                        : (hasOriginal
                                                              ? (_currentPlaying ==
                                                                        CurrentlyPlaying
                                                                            .original
                                                                    ? 'Pausar audio normal'
                                                                    : 'Sonido original grabado')
                                                              : 'Disponible tras grabar un audio'),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color:
                                                          hasOriginal &&
                                                              !isProcessing
                                                          ? Colors.white70
                                                          : (isProcessing
                                                                ? Colors
                                                                      .cyanAccent
                                                                : AppColors
                                                                      .darkTextMuted),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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

                        // 3. CONTAINER 3 (VERDE): Reproductor en Reversa (Con espectro verde oscuro y animación shrink)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: (!isProcessing && hasReversed)
                                ? _togglePlayReverse
                                : null,
                            child: Transform.scale(
                              scale: isProcessing ? _shrinkScale.value : 1.0,
                              child: Opacity(
                                opacity: isProcessing
                                    ? _shrinkOpacity.value
                                    : (hasReversed ? 1.0 : 0.55),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: isProcessing
                                        ? LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFF064E3B,
                                              ).withValues(alpha: 0.65),
                                              const Color(
                                                0xFF022C22,
                                              ).withValues(alpha: 0.65),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : (hasReversed
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFF10B981),
                                                    Color(0xFF059669),
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
                                                )),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: hasReversed && !isProcessing
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color: hasReversed && !isProcessing
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : (isProcessing
                                                ? const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.4)
                                                : AppColors.darkSurfaceStrong),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        // Espectro de audio animado en la base (color verde oscuro del propio container)
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          bottom: 0,
                                          height: 38,
                                          child: AudioSpectrumWave(
                                            barColor: const Color(
                                              0xFF022C22,
                                            ).withValues(alpha: 0.80),
                                            isActive:
                                                _currentPlaying ==
                                                CurrentlyPlaying.reverse,
                                          ),
                                        ),

                                        // Contenido centralizado
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 8,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // Ícono no circular al revés, grande estilo mic
                                                  _currentPlaying ==
                                                          CurrentlyPlaying
                                                              .reverse
                                                      ? const Icon(
                                                          Icons.pause_rounded,
                                                          color: Colors.white,
                                                          size: 54,
                                                        )
                                                      : Transform.flip(
                                                          flipX: true,
                                                          child: Icon(
                                                            Icons
                                                                .play_arrow_rounded,
                                                            color:
                                                                hasReversed &&
                                                                    !isProcessing
                                                                ? Colors.white
                                                                : (isProcessing
                                                                      ? Colors
                                                                            .white70
                                                                      : AppColors
                                                                            .darkTextMuted),
                                                            size: 54,
                                                          ),
                                                        ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Reproducir en Reversa',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          hasReversed &&
                                                              !isProcessing
                                                          ? Colors.white
                                                          : (isProcessing
                                                                ? Colors.white70
                                                                : AppColors
                                                                      .darkTextMuted),
                                                    ),
                                                  ),
                                                  Text(
                                                    isProcessing
                                                        ? 'Generando reverso...'
                                                        : (hasReversed
                                                              ? (_currentPlaying ==
                                                                        CurrentlyPlaying
                                                                            .reverse
                                                                    ? 'Pausar audio en reversa'
                                                                    : 'Sonido invertido listo')
                                                              : 'Disponible al terminar de invertir'),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color:
                                                          hasReversed &&
                                                              !isProcessing
                                                          ? Colors.white70
                                                          : (isProcessing
                                                                ? const Color(
                                                                    0xFF34D399,
                                                                  )
                                                                : AppColors
                                                                      .darkTextMuted),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                    );
                  },
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
