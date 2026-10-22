import '../../features/ads/data/datasources/admob_remote_datasource.dart';
import '../../features/ads/data/repositories/ad_repository_impl.dart';
import '../../features/ads/domain/repositories/ad_repository.dart';
import '../../features/ads/domain/usecases/initialize_ads_usecase.dart';
import '../../features/ads/domain/usecases/load_app_open_ad_usecase.dart';
import '../../features/ads/domain/usecases/load_interstitial_ad_usecase.dart';
import '../../features/ads/domain/usecases/show_app_open_ad_usecase.dart';
import '../../features/ads/domain/usecases/show_interstitial_ad_usecase.dart';
import '../../features/loading/presentation/controllers/loading_controller.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recording_service.dart';
import '../services/audio_reverse_service.dart';
import '../theme/theme_controller.dart';

/// Contenedor de Inyección de Dependencias (Service Locator / DI)
/// siguiendo los principios de Clean Architecture.
class InjectionContainer {
  InjectionContainer._();

  static late final ThemeController themeController;
  static late final AdMobRemoteDataSource adMobRemoteDataSource;
  static late final AdRepository adRepository;

  // UseCases
  static late final InitializeAdsUseCase initializeAdsUseCase;
  static late final LoadAppOpenAdUseCase loadAppOpenAdUseCase;
  static late final ShowAppOpenAdUseCase showAppOpenAdUseCase;
  static late final LoadInterstitialAdUseCase loadInterstitialAdUseCase;
  static late final ShowInterstitialAdUseCase showInterstitialAdUseCase;

  static Future<void> init() async {
    // 0. Theme Controller (Light por defecto con soporte Dark)
    themeController = ThemeController();

    // 1. DataSources
    adMobRemoteDataSource = AdMobRemoteDataSourceImpl();

    // 2. Repositories
    adRepository = AdRepositoryImpl(remoteDataSource: adMobRemoteDataSource);

    // 3. Use Cases
    initializeAdsUseCase = InitializeAdsUseCase(adRepository);
    loadAppOpenAdUseCase = LoadAppOpenAdUseCase(adRepository);
    showAppOpenAdUseCase = ShowAppOpenAdUseCase(adRepository);
    loadInterstitialAdUseCase = LoadInterstitialAdUseCase(adRepository);
    showInterstitialAdUseCase = ShowInterstitialAdUseCase(adRepository);
  }

  /// Crea una nueva instancia de LoadingController inyectando los casos de uso
  static LoadingController createLoadingController() {
    return LoadingController(
      initializeAdsUseCase: initializeAdsUseCase,
      loadAppOpenAdUseCase: loadAppOpenAdUseCase,
      showAppOpenAdUseCase: showAppOpenAdUseCase,
    );
  }

  /// Crea una instancia del servicio de grabación de audio
  static AudioRecordingService createAudioRecordingService() {
    return AudioRecordingService();
  }

  /// Crea una instancia del servicio de inversión de audio (DSP)
  static AudioReverseService createAudioReverseService() {
    return const AudioReverseService();
  }

  /// Crea una instancia del servicio de reproducción de audio
  static AudioPlayerService createAudioPlayerService() {
    return AudioPlayerService();
  }
}
