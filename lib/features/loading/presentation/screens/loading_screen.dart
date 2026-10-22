import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/loading_controller.dart';
import '../widgets/loading_progress_bar.dart';

class LoadingScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration loadingDuration;

  const LoadingScreen({
    super.key,
    this.title = 'Retrovoz Challenge',
    this.subtitle =
        'Graba tus sonidos, reproducelos en reversa y diviertete adivinando',
    this.loadingDuration = const Duration(seconds: 7),
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final LoadingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InjectionContainer.createLoadingController();
    _controller.startLoading(delay: widget.loadingDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLogo(double imageHeight) {
    return Container(
      height: imageHeight * 0.95,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo_actual.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 40,
              color: AppColors.darkAccent,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    final bool isLandscape = width > height;
    final double imageHeight = isLandscape ? height * 0.20 : height * 0.15;

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // 1. Imagen de fondo con íconos
              Positioned.fill(
                top: height * 0.05,
                child: Image.asset(
                  'assets/icon/background_asset_loading.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),

              // 2. Fondo degradado oficial
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.loadingGradient,
                    ),
                  ),
                ),
              ),

              // 3. Contenido principal centrado
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: height * 0.08),

                          // Logo con marco estilizado
                          _buildLogo(imageHeight),

                          const SizedBox(height: 16),

                          // Título de la app: Retrovoz Challenge
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),

                          SizedBox(height: height * 0.05),

                          // Barra de progreso animada de 7 segundos
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: LoadingProgressBar(
                              width: width * 0.70,
                              lineHeight: 12,
                              animationDurationMs:
                                  widget.loadingDuration.inMilliseconds,
                              onAnimationEnd: () {
                                _controller.enableButton();
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Subtítulo descriptivo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              widget.subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF38BDF8),
                                letterSpacing: -0.2,
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(height: height * 0.04),

                          // Botón de Continuar (sin anuncio interstitial, navegación directa)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextButton(
                              onPressed: _controller.isButtonEnabled
                                  ? () => _controller.onContinuePressed(context)
                                  : null,
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                  _controller.isButtonEnabled
                                      ? AppColors.secondaryGreen
                                      : const Color(0xFF132738),
                                ),
                                padding: WidgetStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                    horizontal: 42,
                                    vertical: 12,
                                  ),
                                ),
                                shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder
                                >(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Continuar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _controller.isButtonEnabled
                                      ? Colors.white
                                      : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ));
  }
}
