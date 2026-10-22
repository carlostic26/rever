import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../ads/domain/usecases/initialize_ads_usecase.dart';
import '../../../ads/domain/usecases/load_app_open_ad_usecase.dart';
import '../../../ads/domain/usecases/load_interstitial_ad_usecase.dart';
import '../../../ads/domain/usecases/show_interstitial_ad_usecase.dart';

class LoadingController extends ChangeNotifier {
  final InitializeAdsUseCase initializeAdsUseCase;
  final LoadAppOpenAdUseCase loadAppOpenAdUseCase;
  final LoadInterstitialAdUseCase loadInterstitialAdUseCase;
  final ShowInterstitialAdUseCase showInterstitialAdUseCase;

  bool _isButtonEnabled = false;
  bool _isLoadingComplete = false;
  String _statusMessage = 'Cargando componentes y sonidos...';
  Timer? _timer;

  LoadingController({
    required this.initializeAdsUseCase,
    required this.loadAppOpenAdUseCase,
    required this.loadInterstitialAdUseCase,
    required this.showInterstitialAdUseCase,
  });

  bool get isButtonEnabled => _isButtonEnabled;
  bool get isLoadingComplete => _isLoadingComplete;
  String get statusMessage => _statusMessage;

  /// Inicia el flujo de inicialización, carga de anuncios y habilitación del botón
  Future<void> startLoading({
    Duration delay = const Duration(seconds: 10),
  }) async {
    // 1. Inicializar AdMob
    await initializeAdsUseCase();

    // 2. Pre-cargar el anuncio intersticial para mostrarlo al continuar
    unawaited(loadInterstitialAdUseCase());

    // 3. Temporizador de respaldo para activar el botón (10s como en Cursin v_31)
    _timer?.cancel();
    _timer = Timer(delay, () {
      enableButton();
    });
  }

  /// Habilita el botón de continuar (llamado al terminar la animación o timer)
  void enableButton() {
    if (!_isButtonEnabled) {
      _isLoadingComplete = true;
      _isButtonEnabled = true;
      _statusMessage = '¡Carga completa! Puedes continuar.';
      notifyListeners();
    }
  }

  /// Maneja el clic en "Continuar":
  /// Muestra el anuncio intersticial si está listo, o navega inmediatamente a Home.
  Future<void> onContinuePressed(BuildContext context) async {
    if (!_isButtonEnabled) return;

    void navigateToHome() {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }

    try {
      await showInterstitialAdUseCase(onDismissed: navigateToHome);
    } catch (e) {
      debugPrint(
        '[LoadingController] Error al mostrar anuncio intersticial: $e',
      );
      navigateToHome();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
