import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/constants/admob_constants.dart';

abstract class AdMobRemoteDataSource {
  Future<void> initialize();
  Future<void> loadAppOpenAd({
    VoidCallback? onLoaded,
    Function(LoadAdError error)? onFailed,
  });
  Future<void> showAppOpenAd({VoidCallback? onDismissed});
  Future<void> loadInterstitialAd({
    VoidCallback? onLoaded,
    Function(LoadAdError error)? onFailed,
  });
  Future<void> showInterstitialAd({VoidCallback? onDismissed});
  bool get isAppOpenAdLoaded;
  bool get isInterstitialAdLoaded;
  void dispose();
}

class AdMobRemoteDataSourceImpl implements AdMobRemoteDataSource {
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _isShowingAd = false;

  @override
  bool get isAppOpenAdLoaded => _appOpenAd != null;

  @override
  bool get isInterstitialAdLoaded => _interstitialAd != null;

  @override
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('[AdMobRemoteDataSource] MobileAds inicializado correctamente.');
    } catch (e) {
      debugPrint('[AdMobRemoteDataSource] Error al inicializar MobileAds: $e');
    }
  }

  @override
  Future<void> loadAppOpenAd({
    VoidCallback? onLoaded,
    Function(LoadAdError error)? onFailed,
  }) async {
    final Completer<void> completer = Completer<void>();
    try {
      await AppOpenAd.load(
        adUnitId: AdMobConstants.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            debugPrint('[AdMobRemoteDataSource] AppOpenAd cargado.');
            onLoaded?.call();
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMobRemoteDataSource] Fallo al cargar AppOpenAd: $error');
            _appOpenAd = null;
            onFailed?.call(error);
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMobRemoteDataSource] Excepción al invocar loadAppOpenAd: $e');
      _appOpenAd = null;
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  @override
  Future<void> showAppOpenAd({VoidCallback? onDismissed}) async {
    if (_appOpenAd == null || _isShowingAd) {
      onDismissed?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onDismissed?.call();
      },
    );

    await _appOpenAd!.show();
  }

  @override
  Future<void> loadInterstitialAd({
    VoidCallback? onLoaded,
    Function(LoadAdError error)? onFailed,
  }) async {
    final Completer<void> completer = Completer<void>();
    try {
      await InterstitialAd.load(
        adUnitId: AdMobConstants.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            debugPrint('[AdMobRemoteDataSource] InterstitialAd cargado.');
            onLoaded?.call();
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMobRemoteDataSource] Fallo al cargar InterstitialAd: $error');
            _interstitialAd = null;
            onFailed?.call(error);
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMobRemoteDataSource] Excepción en loadInterstitialAd: $e');
      _interstitialAd = null;
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  @override
  Future<void> showInterstitialAd({VoidCallback? onDismissed}) async {
    if (_interstitialAd == null || _isShowingAd) {
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
    );

    await _interstitialAd!.show();
  }

  @override
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

