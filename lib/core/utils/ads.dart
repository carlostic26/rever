// https://developers.google.com/admob/android/test-ads?hl=es-419
import 'package:flutter_dotenv/flutter_dotenv.dart';

// IDs de prueba para desarrollo
class ReverAdsIdsTest {
  String get bannerAdUnitId =>
      dotenv.env['BANNER_AD_UNIT_ID_TEST'] ??
      'ca-app-pub-3940256099942544/6300978111';
  String get openAppAdUnitId =>
      dotenv.env['OPEN_APP_AD_UNIT_ID_TEST'] ??
      'ca-app-pub-3940256099942544/9257395921';
  String get interstitialAdUnitId =>
      dotenv.env['INTERSTITIAL_AD_UNIT_ID_TEST'] ??
      'ca-app-pub-3940256099942544/1033173712';
  String get rewardAdUnitId =>
      dotenv.env['REWARD_AD_UNIT_ID_TEST'] ??
      'ca-app-pub-3940256099942544/5224354917';
}

// IDs reales listos en .env para producción
class ReverAdsIdsReal {
  String get bannerAdUnitId => dotenv.env['BANNER_AD_UNIT_ID'] ?? '';
  String get openAppAdUnitId => dotenv.env['OPEN_APP_AD_UNIT_ID'] ?? '';
  String get interstitialAdUnitId =>
      dotenv.env['INTERSTITIAL_AD_UNIT_ID'] ?? '';
  String get rewardAdUnitId => dotenv.env['REWARD_AD_UNIT_ID'] ?? '';
}

/// Manejador de IDs de anuncios activos.
/// Actualmente configurado con IDs de prueba según lo solicitado.
class ReverAdsIds {
  static final ReverAdsIdsTest _testIds = ReverAdsIdsTest();
  // static final ReverAdsIdsReal _realIds = ReverAdsIdsReal(); // Para producción

  static String get bannerAdUnitId => _testIds.bannerAdUnitId;
  static String get openAppAdUnitId => _testIds.openAppAdUnitId;
  static String get interstitialAdUnitId => _testIds.interstitialAdUnitId;
  static String get rewardAdUnitId => _testIds.rewardAdUnitId;
}
