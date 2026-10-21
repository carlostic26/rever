import '../repositories/ad_repository.dart';

class LoadInterstitialAdUseCase {
  final AdRepository repository;

  LoadInterstitialAdUseCase(this.repository);

  Future<void> call() => repository.loadInterstitialAd();
}

