import '../repositories/ad_repository.dart';

class InitializeAdsUseCase {
  final AdRepository repository;

  InitializeAdsUseCase(this.repository);

  Future<void> call() => repository.initialize();
}

