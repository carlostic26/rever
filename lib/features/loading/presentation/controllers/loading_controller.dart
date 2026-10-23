import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../ads/domain/usecases/initialize_ads_usecase.dart';
import '../../../ads/domain/usecases/load_app_open_ad_usecase.dart';
import '../../../ads/domain/usecases/show_app_open_ad_usecase.dart';

class LoadingController extends ChangeNotifier {
  final InitializeAdsUseCase initializeAdsUseCase;
  final LoadAppOpenAdUseCase loadAppOpenAdUseCase;
  final ShowAppOpenAdUseCase showAppOpenAdUseCase;

  bool _isButtonEnabled = false;
  bool _isLoadingComplete = false;
  String _statusMessage = 'Cargando componentes y sonidos...';
  Timer? _timer;

  LoadingController({
    required this.initializeAdsUseCase,
    required this.loadAppOpenAdUseCase,
    required this.showAppOpenAdUseCase,
  });

  bool get isButtonEnabled => _isButtonEnabled;
  bool get isLoadingComplete => _isLoadingComplete;
  String get statusMessage => _statusMessage;

  /// Inicia el flujo de inicialización, carga y muestra el anuncio de apertura (App Open Ad)
  /// y activa el botón de continuar a los 7 segundos.
  Future<void> startLoading({
    Duration delay = const Duration(seconds: 7),
  }) async {
    // 1. Temporizador de 7 segundos iniciado de inmediato para no bloquear la UI
    //    incluso si Google Play Services / AdMob tarda en responder en el emulador.
    _timer?.cancel();
    _timer = Timer(delay, () {
      enableButton();
    });

    // 2. Inicializar SDK de AdMob y mostrar App Open Ad en segundo plano
    unawaited(_initAndShowAppOpenAd());
  }

  Future<void> _initAndShowAppOpenAd() async {
    try {
      await initializeAdsUseCase();
      await loadAppOpenAdUseCase();
      await showAppOpenAdUseCase();
    } catch (e) {
      debugPrint('[LoadingController] Error al gestionar AppOpenAd: $e');
    }
  }

  /// Habilita el botón de continuar (llamado al terminar la animación de 7s)
  void enableButton() {
    if (!_isButtonEnabled) {
      _isLoadingComplete = true;
      _isButtonEnabled = true;
      _statusMessage = '¡Carga completa! Puedes continuar.';
      notifyListeners();
    }
  }

  /// Maneja el clic en "Continuar":
  /// No activa ningún anuncio, navega directamente al Home.
  void onContinuePressed(BuildContext context) {
    if (!_isButtonEnabled) return;
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
