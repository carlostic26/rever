import 'dart:ui';
import '../repositories/ad_repository.dart';

class ShowInterstitialAdUseCase {
  final AdRepository repository;

  ShowInterstitialAdUseCase(this.repository);

  Future<void> call({VoidCallback? onDismissed}) =>
      repository.showInterstitialAd(onDismissed: onDismissed);
}

