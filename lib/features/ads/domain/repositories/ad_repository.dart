import 'dart:ui';
import '../entities/ad_status.dart';

abstract class AdRepository {
  /// Inicializa el SDK de AdMob
  Future<void> initialize();

  /// Carga un anuncio de apertura de aplicación (App Open Ad)
  Future<void> loadAppOpenAd();

  /// Muestra el anuncio de apertura si está listo
  Future<void> showAppOpenAdIfAvailable({VoidCallback? onDismissed});

  /// Carga un anuncio intersticial (pantalla completa)
  Future<void> loadInterstitialAd();

  /// Muestra el anuncio intersticial si está cargado
  Future<void> showInterstitialAd({VoidCallback? onDismissed});

  /// Estado actual del anuncio Open
  AdStatus get appOpenAdStatus;

  /// Estado actual del anuncio Interstitial
  AdStatus get interstitialAdStatus;

  /// Indica si el anuncio de apertura está listo para mostrar
  bool get isAppOpenAdLoaded;

  /// Indica si el anuncio intersticial está listo para mostrar
  bool get isInterstitialAdLoaded;

  /// Libera recursos
  void dispose();
}

