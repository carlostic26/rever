import '../utils/ads.dart';

/// Constantes para Google AdMob en Retrovoz.
/// Centraliza la lectura desde .env mediante [ReverAdsIds].
class AdMobConstants {
  AdMobConstants._();

  static String get appOpenAdUnitId => ReverAdsIds.openAppAdUnitId;
  static String get interstitialAdUnitId => ReverAdsIds.interstitialAdUnitId;
  static String get bannerAdUnitId => ReverAdsIds.bannerAdUnitId;
  static String get rewardAdUnitId => ReverAdsIds.rewardAdUnitId;
}
