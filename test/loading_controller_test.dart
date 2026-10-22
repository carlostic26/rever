import 'package:flutter_test/flutter_test.dart';
import 'package:rever/features/ads/domain/entities/ad_status.dart';
import 'package:rever/features/ads/domain/repositories/ad_repository.dart';
import 'package:rever/features/ads/domain/usecases/initialize_ads_usecase.dart';
import 'package:rever/features/ads/domain/usecases/load_app_open_ad_usecase.dart';
import 'package:rever/features/ads/domain/usecases/show_app_open_ad_usecase.dart';
import 'package:rever/features/loading/presentation/controllers/loading_controller.dart';

class MockAdRepository implements AdRepository {
  bool initialized = false;
  bool appOpenAdLoaded = false;
  bool appOpenAdShown = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> loadAppOpenAd() async {
    appOpenAdLoaded = true;
  }

  @override
  Future<void> showAppOpenAdIfAvailable({void Function()? onDismissed}) async {
    appOpenAdShown = true;
    onDismissed?.call();
  }

  @override
  AdStatus get appOpenAdStatus =>
      appOpenAdLoaded ? AdStatus.loaded : AdStatus.initial;

  @override
  AdStatus get interstitialAdStatus => AdStatus.initial;

  @override
  bool get isAppOpenAdLoaded => appOpenAdLoaded;

  @override
  bool get isInterstitialAdLoaded => false;

  @override
  Future<void> loadInterstitialAd() async {}

  @override
  Future<void> showInterstitialAd({void Function()? onDismissed}) async {}

  @override
  void dispose() {}
}

void main() {
  late MockAdRepository mockAdRepository;
  late InitializeAdsUseCase initializeAdsUseCase;
  late LoadAppOpenAdUseCase loadAppOpenAdUseCase;
  late ShowAppOpenAdUseCase showAppOpenAdUseCase;
  late LoadingController controller;

  setUp(() {
    mockAdRepository = MockAdRepository();
    initializeAdsUseCase = InitializeAdsUseCase(mockAdRepository);
    loadAppOpenAdUseCase = LoadAppOpenAdUseCase(mockAdRepository);
    showAppOpenAdUseCase = ShowAppOpenAdUseCase(mockAdRepository);
    controller = LoadingController(
      initializeAdsUseCase: initializeAdsUseCase,
      loadAppOpenAdUseCase: loadAppOpenAdUseCase,
      showAppOpenAdUseCase: showAppOpenAdUseCase,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('Initial state of LoadingController is correct', () {
    expect(controller.isButtonEnabled, isFalse);
    expect(controller.isLoadingComplete, isFalse);
    expect(controller.statusMessage, 'Cargando componentes y sonidos...');
  });

  test(
    'startLoading initializes ads, loads and shows AppOpenAd, and enables button after duration',
    () async {
      await controller.startLoading(delay: const Duration(milliseconds: 50));

      expect(mockAdRepository.initialized, isTrue);

      // Wait for async ad and timer
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(mockAdRepository.appOpenAdLoaded, isTrue);
      expect(mockAdRepository.appOpenAdShown, isTrue);
      expect(controller.isButtonEnabled, isTrue);
      expect(controller.isLoadingComplete, isTrue);
      expect(controller.statusMessage, '¡Carga completa! Puedes continuar.');
    },
  );
}

