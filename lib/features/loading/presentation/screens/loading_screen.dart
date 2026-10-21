import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/loading_controller.dart';
import '../widgets/counting_animation.dart';
import '../widgets/loading_progress_bar.dart';

class LoadingScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int maxCourses;
  final String categoriesText;
  final Duration loadingDuration;

  const LoadingScreen({
    super.key,
    this.title = 'Rever Verbal',
    this.subtitle = 'Sonidos en reversa',
    this.maxCourses = 1004,
    this.categoriesText = 'efectos y sonidos de prueba...',
    this.loadingDuration = const Duration(seconds: 10),
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
        color: const Color.fromARGB(255, 206, 206, 206),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(1),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.15,
          0,
          0,
          0,
          0,
          0,
          1.15,
          0,
          0,
          0,
          0,
          0,
          1.15,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Image.asset(
          'assets/logo_icon.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(
                Icons.school_rounded,
                size: 40,
                color: AppColors.darkAccent,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    final bool isLandscape = width > height;
    final double imageHeight = isLandscape ? height * 0.20 : height * 0.15;
    final double textSize = isLandscape ? 10.0 : 8.0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // 1. Imagen de fondo con íconos (exacto a Cursin v_31)
              Positioned.fill(
                top: height * 0.05,
                child: Image.asset(
                  'assets/icon/icons_background.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),

              // 2. Fondo degradado oficial de Cursin
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: height * 0.12),

                        // Logo con marco estilizado
                        _buildLogo(imageHeight),

                        const SizedBox(height: 12),

                        // Título con Poppins
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),

                        // Subtítulo con Poppins
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue,
                            letterSpacing: -1,
                          ),
                        ),

                        SizedBox(height: height * 0.06),

                        // Barra de progreso animada con percent_indicator
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: LoadingProgressBar(
                            width: width * 0.65,
                            lineHeight: 7,
                            animationDurationMs:
                                widget.loadingDuration.inMilliseconds,
                            progressColor: AppColors.darkAccent,
                            backgroundColor: AppColors.darkSurfaceStrong,
                            onAnimationEnd: () {
                              _controller.enableButton();
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Fila de conteo y descripción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Recopilando  ',
                              style: GoogleFonts.poppins(
                                fontSize: textSize + 3,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            CountingAnimation(
                              endCount: widget.maxCourses,
                              textSize: textSize,
                              duration: widget.loadingDuration,
                            ),
                            Text(
                              '  ${widget.categoriesText}',
                              style: GoogleFonts.poppins(
                                fontSize: textSize + 3,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Mensaje de estado
                        Text(
                          _controller.statusMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _controller.isButtonEnabled
                                ? Colors.cyanAccent
                                : AppColors.darkTextSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        SizedBox(height: height * 0.04),

                        // Botón de Continuar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
                          child: TextButton(
                            onPressed: _controller.isButtonEnabled
                                ? () => _controller.onContinuePressed(context)
                                : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                _controller.isButtonEnabled
                                    ? AppColors.darkAccent
                                    : AppColors.darkSurfaceStrong,
                              ),
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
                                ),
                              ),
                              shape:
                                  WidgetStateProperty.all<
                                    RoundedRectangleBorder
                                  >(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
            ],
          );
        },
      ),
    );
  }
}
