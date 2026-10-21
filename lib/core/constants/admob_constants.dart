import '../utils/ads.dart';

/// Constantes para Google AdMob en Rever Verbal.
/// Centraliza la lectura desde .env mediante [ReverAdsIds].
class AdMobConstants {
  AdMobConstants._();

  static String get appOpenAdUnitId => ReverAdsIds.openAppAdUnitId;
  static String get interstitialAdUnitId => ReverAdsIds.interstitialAdUnitId;
  static String get bannerAdUnitId => ReverAdsIds.bannerAdUnitId;
  static String get rewardAdUnitId => ReverAdsIds.rewardAdUnitId;
}
