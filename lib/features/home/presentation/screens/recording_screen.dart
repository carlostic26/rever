import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/admob_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/audio_recording_service.dart';
import '../../../../core/services/audio_reverse_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorites/domain/services/favorites_service.dart';
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
  late final AudioPlayerService _originalPlayerService;
  late final AudioPlayerService _reversePlayerService;
  late final FavoritesService _favoritesService;

  // Estado de guardado en Favoritos del audio actual
  bool _isCurrentAudioSaved = false;

  // Suscripciones de reproducción
  StreamSubscription<PlayerState>? _originalPlayerStateSub;
  StreamSubscription<PlayerState>? _reversePlayerStateSub;

  // Estado del flujo de audio
  HomeAudioState _audioState = HomeAudioState.initial;

  // Pista actualmente en reproducción
  CurrentlyPlaying _currentPlaying = CurrentlyPlaying.none;

  // Gestos táctiles y cronómetro (tipo WhatsApp)
  int? _activePointerId;
  DateTime? _pointerDownTime;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Contador de grabaciones de voz válidas (> 2 segundos) para anuncio intersticial
  int _validRecordingsCount = 0;

  // Animación shrink para containers de reproducción durante el procesamiento
  late final AnimationController _shrinkController;
  late final Animation<double> _shrinkScale;
  late final Animation<double> _shrinkOpacity;

  // Banner Ad adaptativo de AdMob para la pantalla de grabación
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isLoadingBanner = false;

  @override
  void initState() {
    super.initState();
    _recordingService = InjectionContainer.createAudioRecordingService();
    _reverseService = InjectionContainer.createAudioReverseService();
    _originalPlayerService = InjectionContainer.createAudioPlayerService();
    _reversePlayerService = InjectionContainer.createAudioPlayerService();
    _favoritesService = InjectionContainer.getFavoritesService();

    // Precargar Interstitial Ad para que esté listo cuando se requiera
    unawaited(InjectionContainer.loadInterstitialAdUseCase());

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoadingBanner) {
      _loadAdaptiveBannerAd();
    }
  }

  void _setupPlayerListeners() {
    _originalPlayerStateSub = _originalPlayerService.playerStateStream.listen((
      playerState,
    ) {
      if (!mounted) return;
      final bool isPlaying = playerState.playing;
      final bool isCompleted =
          playerState.processingState == ProcessingState.completed;

      if (!isPlaying || isCompleted) {
        if (_currentPlaying == CurrentlyPlaying.original) {
          setState(() {
            _currentPlaying = CurrentlyPlaying.none;
          });
        }
      }
    });

    _reversePlayerStateSub = _reversePlayerService.playerStateStream.listen((
      playerState,
    ) {
      if (!mounted) return;
      final bool isPlaying = playerState.playing;
      final bool isCompleted =
          playerState.processingState == ProcessingState.completed;

      if (!isPlaying || isCompleted) {
        if (_currentPlaying == CurrentlyPlaying.reverse) {
          setState(() {
            _currentPlaying = CurrentlyPlaying.none;
          });
        }
      }
    });
  }

  Future<void> _loadAdaptiveBannerAd() async {
    _isLoadingBanner = true;
    final int width = MediaQuery.of(context).size.width.truncate();

    // 1. Obtener tamaño adaptativo optimizado según ancho y orientación
    AnchoredAdaptiveBannerAdSize? adaptiveSize;
    try {
      adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    } catch (e) {
      debugPrint(
        '[RecordingScreen] Error calculando tamaño de banner adaptativo: $e',
      );
    }

    if (!mounted) return;

    // 2. Instanciar y cargar el BannerAd con la medida exacta recibida
    _bannerAd = BannerAd(
      adUnitId: AdMobConstants.bannerAdUnitId,
      size: adaptiveSize ?? AdSize.banner,
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
          debugPrint(
            '[RecordingScreen] Error cargando BannerAd adaptativo: $error',
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isBannerLoaded = false;
            });
          }
        },
      ),
    );
    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _originalPlayerStateSub?.cancel();
    _reversePlayerStateSub?.cancel();
    _recordingTimer?.cancel();
    _shrinkController.dispose();
    _originalPlayerService.dispose();
    _reversePlayerService.dispose();
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
          'Retrovoz Challenge requiere acceso al micrófono para grabar tu voz. '
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

  void _showRecordFirstMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Primero mantén presionado para grabar',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.darkSurfaceCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSupportDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurfaceCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.secondaryGreen,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¿Te está gustando Retrovoz Challenge?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Apóyanos viendo un corto anuncio para continuar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                InjectionContainer.showInterstitialAdUseCase(
                  onDismissed: () {
                    unawaited(InjectionContainer.loadInterstitialAdUseCase());
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Gesto: Iniciar grabación en Container 1 (inmediato al tocar)
  Future<void> _handlePointerDown(PointerDownEvent event) async {
    // Si se está procesando audio, bloquear cualquier interacción
    if (_audioState.isProcessing) return;

    // Si algún reproductor está activo, detenerlo inmediatamente
    if (_currentPlaying != CurrentlyPlaying.none) {
      unawaited(_originalPlayerService.pause());
      unawaited(_reversePlayerService.pause());
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
      _isCurrentAudioSaved = false;
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
      // 1. Container 1 muestra animación de procesamiento con 3 puntos (en color púrpura)
      // 2. Containers 2 y 3 permanecen totalmente bloqueados e inician animación shrink
      setState(() {
        _audioState = HomeAudioState(
          status: AudioSessionStatus.processing,
          statusText: 'Invirtiendo audio...',
          audioPath: null,
          reversedAudioPath: null,
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
        final String origPath = recordResult.filePath!;
        final String revPath = reverseResult.reversedPath!;

        try {
          // Precargamos ambos reproductores para garantizar reproducción y pausa instantánea
          await Future.wait([
            _originalPlayerService.loadAudioFile(origPath),
            _reversePlayerService.loadAudioFile(revPath),
          ]);

          if (!mounted) return;

          final Duration validDuration =
              reverseResult.metadata?.duration ?? recordResult.duration;

          // Solo ahora que ambos audios están listos y cargados, habilitamos los botones
          setState(() {
            _audioState = HomeAudioState(
              status: AudioSessionStatus.ready,
              statusText: '¡Audios listos!',
              audioPath: origPath,
              reversedAudioPath: revPath,
              recordedDuration: validDuration,
            );
          });

          // Contabilizar grabación válida de voz mayor a 2 segundos
          if (validDuration > const Duration(seconds: 2)) {
            _validRecordingsCount++;
            if (_validRecordingsCount % 3 == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showSupportDialog();
                }
              });
            }
          }
        } catch (e) {
          debugPrint('[RecordingScreen] Error precargando audios: $e');
          if (mounted) {
            setState(() {
              _audioState = HomeAudioState(
                status: AudioSessionStatus.error,
                statusText: 'Error al preparar audio',
                recordedDuration: recordResult.duration,
              );
            });
          }
        }
      } else {
        setState(() {
          _audioState = HomeAudioState(
            status: AudioSessionStatus.error,
            statusText: 'Error al procesar reverso',
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

  // Guardar únicamente el audio en reversa en la sección de Favoritos (SQLite)
  Future<void> _saveCurrentReverseToFavorites() async {
    if (!_audioState.isReady || _audioState.reversedAudioPath == null) {
      _showRecordFirstMessage();
      return;
    }

    if (_isCurrentAudioSaved) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Este sonido ya está en tus Favoritos',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurfaceCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Ver',
            textColor: AppColors.secondaryGreen,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.favorites);
            },
          ),
        ),
      );
      return;
    }

    try {
      final saved = await _favoritesService.saveFavorite(
        tempReversedPath: _audioState.reversedAudioPath!,
        duration: _audioState.recordedDuration ?? Duration.zero,
      );

      if (!mounted) return;
      setState(() {
        _isCurrentAudioSaved = true;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Guardado: ${saved.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.darkSurfaceCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver Favoritos',
            textColor: AppColors.secondaryGreen,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.favorites);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[RecordingScreen] Error guardando favorito: $e');
      if (mounted) {
        final isPluginMissing = e.toString().contains('MissingPluginException');
        final message = isPluginMissing
            ? 'Reinicia la app (Stop y Run) para cargar la base de datos.'
            : 'No se pudo guardar el audio en favoritos. Inténtalo de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Reproducir/pausar audio normal de forma inmediata (Container 2 - Azul)
  Future<void> _togglePlayOriginal() async {
    if (!_audioState.isReady) return;
    try {
      if (_currentPlaying == CurrentlyPlaying.original) {
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
        await _originalPlayerService.pause();
      } else {
        if (_currentPlaying == CurrentlyPlaying.reverse) {
          unawaited(_reversePlayerService.pause());
          unawaited(_reversePlayerService.seek(Duration.zero));
        }
        setState(() {
          _currentPlaying = CurrentlyPlaying.original;
        });
        await _originalPlayerService.play();
      }
    } catch (e) {
      debugPrint('[RecordingScreen] Error reproduciendo original: $e');
      if (mounted) {
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
      }
    }
  }

  // Reproducir/pausar audio en reversa de forma inmediata (Container 3 - Verde)
  Future<void> _togglePlayReverse() async {
    if (!_audioState.isReady) return;
    try {
      if (_currentPlaying == CurrentlyPlaying.reverse) {
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
        await _reversePlayerService.pause();
      } else {
        if (_currentPlaying == CurrentlyPlaying.original) {
          unawaited(_originalPlayerService.pause());
          unawaited(_originalPlayerService.seek(Duration.zero));
        }
        setState(() {
          _currentPlaying = CurrentlyPlaying.reverse;
        });
        await _reversePlayerService.play();
      }
    } catch (e) {
      debugPrint('[RecordingScreen] Error reproduciendo reverso: $e');
      if (mounted) {
        setState(() {
          _currentPlaying = CurrentlyPlaying.none;
        });
      }
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
    // Solo se habilitan cuando estemos 100% seguros de poder reproducir al derecho y al revés
    final bool isAudiosReady = !isProcessing &&
        _audioState.isReady &&
        _audioState.audioPath != null &&
        _audioState.reversedAudioPath != null;
    final bool hasOriginal = isAudiosReady;
    final bool hasReversed = isAudiosReady;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: textPrimary,
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
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Estudio Retrovoz',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Botón de Corazón / Guardar en Favoritos en el AppBar
          IconButton(
            icon: Icon(
              _isCurrentAudioSaved
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: hasReversed && !isProcessing
                  ? (_isCurrentAudioSaved
                      ? Colors.redAccent
                      : (isDark ? Colors.white : AppColors.primaryBlue))
                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              size: 24,
            ),
            tooltip: hasReversed && !isProcessing
                ? (_isCurrentAudioSaved
                    ? 'Guardado en Favoritos'
                    : 'Guardar sonido en Favoritos')
                : 'Disponible tras generar el audio',
            onPressed: hasReversed && !isProcessing
                ? _saveCurrentReverseToFavorites
                : _showRecordFirstMessage,
          ),
          // Acceso a la lista de Favoritos
          IconButton(
            icon: Icon(
              Icons.bookmarks_rounded,
              color: textPrimary,
              size: 22,
            ),
            tooltip: 'Ver Favoritos',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.favorites);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
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
                  // 1. CONTAINER 1: Botón de Grabación (Púrpura cuando está en reposo/procesando, Rojo únicamente al grabar)
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
                                                  Color(0xFF7C3AED),
                                                  Color(0xFF5B21B6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFF6D28D9),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isRecording
                                          ? const Color(0xFFDC2626).withValues(
                                              alpha: 0.45,
                                            )
                                          : const Color(0xFF7C3AED).withValues(
                                              alpha: 0.35,
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
                                      // Espectro de audio animado en la base (rojo al grabar, púrpura profundo en reposo)
                                      Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 0,
                                        height: 38,
                                        child: AudioSpectrumWave(
                                          barColor: isRecording
                                              ? const Color(
                                                  0xFF7F1D1D,
                                                ).withValues(alpha: 0.70)
                                              : const Color(
                                                  0xFF4C1D95,
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
                            behavior: HitTestBehavior.opaque,
                            onTap: isProcessing
                                ? null
                                : (hasOriginal
                                    ? _togglePlayOriginal
                                    : _showRecordFirstMessage),
                            child: Transform.scale(
                              scale: isProcessing ? _shrinkScale.value : 1.0,
                              child: Opacity(
                                opacity: isProcessing
                                    ? _shrinkOpacity.value
                                    : 1.0,
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
                                                  colors: isDark
                                                      ? const [
                                                          Color(0xFF0F2338),
                                                          Color(0xFF0C1B2B),
                                                        ]
                                                      : const [
                                                          Color(0xFFEFF6FF),
                                                          Color(0xFFDBEAFE),
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
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
                                        : (isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ).withValues(alpha: 0.08),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]),
                                    border: Border.all(
                                      color: hasOriginal && !isProcessing
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : (isProcessing
                                                ? const Color(
                                                    0xFF3B82F6,
                                                  ).withValues(alpha: 0.4)
                                                : (isDark
                                                    ? const Color(0xFF1E3A5F)
                                                    : const Color(
                                                        0xFF93C5FD,
                                                      ))),
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
                                            barColor: _currentPlaying ==
                                                    CurrentlyPlaying.original
                                                ? const Color(
                                                    0xFF172554,
                                                  ).withValues(alpha: 0.80)
                                                : (isDark
                                                    ? const Color(
                                                        0xFF1E3A5F,
                                                      ).withValues(alpha: 0.40)
                                                    : const Color(
                                                        0xFF93C5FD,
                                                      ).withValues(alpha: 0.40)),
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
                                                  // Ícono normal play/pause (gris cuando está deshabilitado)
                                                  Icon(
                                                    _currentPlaying ==
                                                            CurrentlyPlaying
                                                                .original
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .play_arrow_rounded,
                                                    color: hasOriginal &&
                                                            !isProcessing
                                                        ? Colors.white
                                                        : (isProcessing
                                                              ? Colors.white70
                                                              : (isDark
                                                                  ? const Color(
                                                                      0xFF64748B,
                                                                    )
                                                                  : const Color(
                                                                      0xFF94A3B8,
                                                                    ))),
                                                    size: 54,
                                                  ),
                                                  if (hasOriginal ||
                                                      isProcessing) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Reproducir Audio Normal',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: hasOriginal &&
                                                                !isProcessing
                                                            ? Colors.white
                                                            : (isProcessing
                                                                  ? Colors
                                                                        .white70
                                                                  : (isDark
                                                                      ? Colors
                                                                            .white
                                                                      : const Color(
                                                                          0xFF1E3A8A,
                                                                        ))),
                                                      ),
                                                    ),
                                                    Text(
                                                      isProcessing
                                                          ? 'Procesando sonido...'
                                                          : (_currentPlaying ==
                                                                  CurrentlyPlaying
                                                                      .original
                                                              ? 'Pausar audio normal'
                                                              : 'Sonido original grabado'),
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: hasOriginal &&
                                                                !isProcessing
                                                            ? Colors.white70
                                                            : Colors.cyanAccent,
                                                      ),
                                                    ),
                                                  ],
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
                            behavior: HitTestBehavior.opaque,
                            onTap: isProcessing
                                ? null
                                : (hasReversed
                                    ? _togglePlayReverse
                                    : _showRecordFirstMessage),
                            child: Transform.scale(
                              scale: isProcessing ? _shrinkScale.value : 1.0,
                              child: Opacity(
                                opacity: isProcessing
                                    ? _shrinkOpacity.value
                                    : 1.0,
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
                                                  colors: isDark
                                                      ? const [
                                                          Color(0xFF07271E),
                                                          Color(0xFF051E17),
                                                        ]
                                                      : const [
                                                          Color(0xFFECFDF5),
                                                          Color(0xFFD1FAE5),
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
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
                                        : (isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.08),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]),
                                    border: Border.all(
                                      color: hasReversed && !isProcessing
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : (isProcessing
                                                ? const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.4)
                                                : (isDark
                                                    ? const Color(0xFF0D4233)
                                                    : const Color(
                                                        0xFFA7F3D0,
                                                      ))),
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
                                            barColor: _currentPlaying ==
                                                    CurrentlyPlaying.reverse
                                                ? const Color(
                                                    0xFF022C22,
                                                  ).withValues(alpha: 0.80)
                                                : (isDark
                                                    ? const Color(
                                                        0xFF0D4233,
                                                      ).withValues(alpha: 0.40)
                                                    : const Color(
                                                        0xFFA7F3D0,
                                                      ).withValues(alpha: 0.40)),
                                            isActive:
                                                _currentPlaying ==
                                                CurrentlyPlaying.reverse,
                                          ),
                                        ),

                                        // Botón de corazón para guardar audio reverso en Favoritos
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: hasReversed && !isProcessing
                                                ? _saveCurrentReverseToFavorites
                                                : _showRecordFirstMessage,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: hasReversed && !isProcessing
                                                    ? (_isCurrentAudioSaved
                                                        ? Colors.white
                                                        : Colors.black.withValues(alpha: 0.18))
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: hasReversed && !isProcessing
                                                      ? (_isCurrentAudioSaved
                                                          ? Colors.redAccent
                                                          : Colors.white.withValues(alpha: 0.45))
                                                      : (isDark
                                                          ? const Color(0xFF64748B).withValues(alpha: 0.3)
                                                          : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                _isCurrentAudioSaved
                                                    ? Icons.favorite_rounded
                                                    : Icons.favorite_border_rounded,
                                                size: 22,
                                                color: hasReversed && !isProcessing
                                                    ? (_isCurrentAudioSaved
                                                        ? Colors.redAccent
                                                        : Colors.white)
                                                    : (isDark
                                                        ? const Color(0xFF64748B)
                                                        : const Color(0xFF94A3B8)),
                                              ),
                                            ),
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
                                                  // Ícono doble triángulo apuntando a la izquierda (fast_rewind_rounded, gris cuando está deshabilitado)
                                                  Icon(
                                                    _currentPlaying ==
                                                            CurrentlyPlaying
                                                                .reverse
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .fast_rewind_rounded,
                                                    color: hasReversed &&
                                                            !isProcessing
                                                        ? Colors.white
                                                        : (isProcessing
                                                              ? Colors.white70
                                                              : (isDark
                                                                  ? const Color(
                                                                      0xFF64748B,
                                                                    )
                                                                  : const Color(
                                                                      0xFF94A3B8,
                                                                    ))),
                                                    size: 54,
                                                  ),
                                                  if (hasReversed ||
                                                      isProcessing) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Reproducir en Reversa',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: hasReversed &&
                                                                !isProcessing
                                                            ? Colors.white
                                                            : (isProcessing
                                                                  ? Colors
                                                                        .white70
                                                                  : (isDark
                                                                      ? Colors
                                                                            .white
                                                                      : const Color(
                                                                          0xFF064E3B,
                                                                        ))),
                                                      ),
                                                    ),
                                                    Text(
                                                      isProcessing
                                                          ? 'Generando reverso...'
                                                          : (_currentPlaying ==
                                                                  CurrentlyPlaying
                                                                      .reverse
                                                              ? 'Pausar audio en reversa'
                                                              : 'Sonido invertido listo'),
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: hasReversed &&
                                                                !isProcessing
                                                            ? Colors.white70
                                                            : const Color(
                                                                0xFF34D399,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
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
      bottomNavigationBar: (_isBannerLoaded && _bannerAd != null)
          ? SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: BoxDecoration(
                  color: bgColor,
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }
}
