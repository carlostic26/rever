import 'dart:ui';
import '../../domain/entities/ad_status.dart';
import '../../domain/repositories/ad_repository.dart';
import '../datasources/admob_remote_datasource.dart';

class AdRepositoryImpl implements AdRepository {
  final AdMobRemoteDataSource remoteDataSource;

  AdStatus _appOpenStatus = AdStatus.initial;
  AdStatus _interstitialStatus = AdStatus.initial;

  AdRepositoryImpl({required this.remoteDataSource});

  @override
  AdStatus get appOpenAdStatus => _appOpenStatus;

  @override
  AdStatus get interstitialAdStatus => _interstitialStatus;

  @override
  bool get isAppOpenAdLoaded => remoteDataSource.isAppOpenAdLoaded;

  @override
  bool get isInterstitialAdLoaded => remoteDataSource.isInterstitialAdLoaded;

  @override
  Future<void> initialize() async {
    await remoteDataSource.initialize();
  }

  @override
  Future<void> loadAppOpenAd() async {
    _appOpenStatus = AdStatus.loading;
    await remoteDataSource.loadAppOpenAd(
      onLoaded: () {
        _appOpenStatus = AdStatus.loaded;
      },
      onFailed: (_) {
        _appOpenStatus = AdStatus.failed;
      },
    );
  }

  @override
  Future<void> showAppOpenAdIfAvailable({VoidCallback? onDismissed}) async {
    if (isAppOpenAdLoaded) {
      await remoteDataSource.showAppOpenAd(onDismissed: () {
        _appOpenStatus = AdStatus.dismissed;
        onDismissed?.call();
      });
    } else {
      onDismissed?.call();
    }
  }

  @override
  Future<void> loadInterstitialAd() async {
    _interstitialStatus = AdStatus.loading;
    await remoteDataSource.loadInterstitialAd(
      onLoaded: () {
        _interstitialStatus = AdStatus.loaded;
      },
      onFailed: (_) {
        _interstitialStatus = AdStatus.failed;
      },
    );
  }

  @override
  Future<void> showInterstitialAd({VoidCallback? onDismissed}) async {
    if (isInterstitialAdLoaded) {
      await remoteDataSource.showInterstitialAd(onDismissed: () {
        _interstitialStatus = AdStatus.dismissed;
        onDismissed?.call();
      });
    } else {
      onDismissed?.call();
    }
  }

  @override
  void dispose() {
    remoteDataSource.dispose();
  }
}

