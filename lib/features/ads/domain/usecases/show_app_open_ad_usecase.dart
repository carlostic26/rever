import 'dart:ui';
import '../repositories/ad_repository.dart';

class ShowAppOpenAdUseCase {
  final AdRepository repository;

  ShowAppOpenAdUseCase(this.repository);

  Future<void> call({VoidCallback? onDismissed}) =>
      repository.showAppOpenAdIfAvailable(onDismissed: onDismissed);
}

