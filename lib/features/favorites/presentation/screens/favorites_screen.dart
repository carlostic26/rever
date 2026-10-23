import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/admob_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/favorite_audio.dart';
import '../../domain/services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesService _favoritesService;
  late final AudioPlayerService _playerService;

  List<FavoriteAudio> _favorites = [];
  bool _isLoading = true;

  // Estado de reproducción
  int? _currentlyPlayingId;
  bool _isStartingPlayback = false;
  StreamSubscription<PlayerState>? _playerStateSub;

  // Banner Ad adaptativo de AdMob
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isLoadingBanner = false;

  @override
  void initState() {
    super.initState();
    _favoritesService = InjectionContainer.getFavoritesService();
    _playerService = InjectionContainer.createAudioPlayerService();

    _playerStateSub = _playerService.playerStateStream.listen((state) {
      if (!mounted || _isStartingPlayback) return;
      final bool isPlaying = state.playing;
      final bool isCompleted =
          state.processingState == ProcessingState.completed;

      if (isCompleted) {
        _playerService.pause();
        _playerService.seek(Duration.zero);
        if (_currentlyPlayingId != null) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      } else if (!isPlaying &&
          state.processingState != ProcessingState.loading &&
          state.processingState != ProcessingState.buffering) {
        if (_currentlyPlayingId != null) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      }
    });

    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoadingBanner) {
      _loadAdaptiveBannerAd();
    }
  }

  Future<void> _loadAdaptiveBannerAd() async {
    _isLoadingBanner = true;
    final int width = MediaQuery.of(context).size.width.truncate();

    AnchoredAdaptiveBannerAdSize? adaptiveSize;
    try {
      adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    } catch (e) {
      debugPrint('[FavoritesScreen] Error calculando tamaño banner: $e');
    }

    if (!mounted) return;

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
          debugPrint('[FavoritesScreen] Error cargando BannerAd: $error');
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

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _favoritesService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FavoritesScreen] Error cargando favoritos: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayFavorite(FavoriteAudio audio) async {
    try {
      if (_currentlyPlayingId == audio.id) {
        // Pausar
        _isStartingPlayback = false;
        if (mounted) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
        await _playerService.pause();
      } else {
        // Reproducir: actualizar estado visual a pausa inmediatamente
        _isStartingPlayback = true;
        if (mounted) {
          setState(() {
            _currentlyPlayingId = audio.id;
          });
        }
        await _playerService.loadAudioFile(audio.filePath);
        _isStartingPlayback = false;
        if (!mounted || _currentlyPlayingId != audio.id) return;
        await _playerService.play();
      }
    } catch (e) {
      _isStartingPlayback = false;
      debugPrint('[FavoritesScreen] Error al reproducir audio favorito: $e');
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo reproducir este archivo de audio.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteOne(FavoriteAudio audio) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurfaceCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Eliminar sonido',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar "${audio.name}" de tus favoritos?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_currentlyPlayingId == audio.id) {
        await _playerService.pause();
        _currentlyPlayingId = null;
      }
      await _favoritesService.deleteFavorite(audio);
      await _loadFavorites();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sonido eliminado de favoritos',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurfaceCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurfaceCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.errorRed,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              'Eliminar todos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar todas las grabaciones favoritas? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Eliminar todos',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _playerService.pause();
      _currentlyPlayingId = null;

      await _favoritesService.deleteAllFavorites();
      await _loadFavorites();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se han eliminado todas las grabaciones favoritas',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurfaceCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playerService.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color cardBg =
        isDark ? AppColors.darkSurfaceCard : Colors.white;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color borderColor =
        isDark ? AppColors.darkSurfaceStrong : AppColors.lightSurfaceStrong;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackgroundAlt : AppColors.lightBackgroundAlt,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondaryGreen, AppColors.primaryBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Favoritos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.errorRed,
                size: 24,
              ),
              tooltip: 'Eliminar todos',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondaryGreen,
                  ),
                ),
              )
            : _favorites.isEmpty
                ? _buildEmptyState(isDark, textPrimary, textSecondary)
                : _buildFavoritesList(
                    isDark,
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
      ),
      bottomNavigationBar: (_isBannerLoaded && _bannerAd != null)
          ? SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: BoxDecoration(color: bgColor),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryGreen.withValues(alpha: 0.2),
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.secondaryGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.secondaryGreen,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Graba sonidos en el Estudio, inviértelos y pulsa el botón del corazón para guardarlos aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.recording);
              },
              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
              label: Text(
                'Ir al Estudio',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.secondaryGreen.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _favorites.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final audio = _favorites[index];
        final bool isPlaying = _currentlyPlayingId == audio.id;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlaying
                  ? AppColors.secondaryGreen
                  : borderColor.withValues(alpha: 0.6),
              width: isPlaying ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPlaying
                    ? AppColors.secondaryGreen.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04)),
                blurRadius: isPlaying ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: GestureDetector(
              onTap: () => _togglePlayFavorite(audio),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isPlaying
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
                            AppColors.primaryBlue.withValues(alpha: 0.15),
                            AppColors.secondaryGreen.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isPlaying ? Colors.white : AppColors.secondaryGreen,
                  size: 26,
                ),
              ),
            ),
            title: Text(
              audio.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  audio.formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.fast_rewind_rounded,
                  size: 13,
                  color: AppColors.secondaryGreen,
                ),
                const SizedBox(width: 2),
                Text(
                  audio.formattedDuration,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryGreen,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDeleteOne(audio),
            ),
          ),
        );
      },
    );
  }
}
