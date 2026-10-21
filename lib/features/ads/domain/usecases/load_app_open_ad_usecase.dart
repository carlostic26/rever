import '../repositories/ad_repository.dart';

class LoadAppOpenAdUseCase {
  final AdRepository repository;

  LoadAppOpenAdUseCase(this.repository);

  Future<void> call() => repository.loadAppOpenAd();
}

