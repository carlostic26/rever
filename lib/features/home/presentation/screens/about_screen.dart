import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color cardBg =
        isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color borderColor =
        isDark ? AppColors.darkSurfaceStrong : AppColors.lightSurfaceStrong;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Acerca de',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta de Encabezado de la App
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0C1B2B), Color(0xFF0F2C3A)]
                        : const [Color(0xFFE0F2FE), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo_actual.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.brandGradient,
                            ),
                            child: const Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Retrovoz Challenge',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Graba, invierte y reproduce tus sonidos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Versión ${AppConstants.appVersion}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. ¿Qué es Retrovoz Challenge?
              _buildSectionTitle('¿En qué consiste el reto?', textPrimary),
              const SizedBox(height: 8),
              _buildParagraph(
                '¿Alguna vez te has preguntado cómo sonaría tu voz si la escucharas al revés? '
                '¿Serías capaz de reconocer una palabra, una risa o un sonido cotidiano después de invertir su reproducción?\n\n'
                'Retrovoz Challenge es una aplicación creada para explorar los sonidos de una forma totalmente diferente y divertida. '
                'Su propuesta es sencilla y emocionante: graba tu voz o cualquier sonido, invierte su reproducción al instante mediante procesamiento de audio digital, '
                'e intenta descubrir qué sonido original se esconde detrás de la grabación.',
                textSecondary,
              ),

              const SizedBox(height: 20),

              // 3. ¿Por qué suenan tan diferentes?
              _buildSectionTitle('¿Por qué suenan tan diferentes?', textPrimary),
              const SizedBox(height: 8),
              _buildParagraph(
                'Cuando una persona habla, produce una secuencia acústica continua a lo largo del tiempo. '
                'Nuestro cerebro está acostumbrado a interpretar las consonantes, vocales y transiciones en su orden natural.\n\n'
                'Al reproducir una grabación en sentido inverso, el orden temporal se invierte y las características sonoras aparecen al revés. '
                'Por eso, una palabra familiar o cotidiana puede sonar como un idioma desconocido o un enigma auditivo.',
                textSecondary,
              ),

              const SizedBox(height: 20),

              // 4. Tres formas de jugar
              _buildSectionTitle('3 Formas de jugar y retar amigos', textPrimary),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.record_voice_over_rounded,
                iconColor: AppColors.primaryBlue,
                title: '1. Adivina la palabra',
                description:
                    'Graba una palabra corta y reprodúcela al revés. Reta a tus amigos a descubrir cuál fue la palabra original.',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 10),
              _buildFeatureCard(
                icon: Icons.hearing_rounded,
                iconColor: AppColors.secondaryGreen,
                title: '2. Reconoce el sonido cotidiano',
                description:
                    'Prueba con sonidos del día a día: una palmada, un silbido, una risa o el ladrido de tu mascota. ¿Seguirá siendo fácil reconocerlo?',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 10),
              _buildFeatureCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: '3. El reto en grupo',
                description:
                    'Reúnanse con amigos o familia, túrnense para grabar y sumen puntos a quien adivine primero el sonido invertido.',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 20),

              // 5. Consejos para el juego
              _buildSectionTitle('Consejos para divertirte más', textPrimary),
              const SizedBox(height: 8),
              _buildParagraph(
                '• Empieza con palabras o frases cortas de 1 a 3 sílabas.\n'
                '• Graba en un lugar tranquilo sin demasiado ruido de fondo.\n'
                '• Mantén en secreto la palabra original antes de reproducir el reverso.\n'
                '• ¡No te preocupes si suena irreconocible: las deducciones disparatadas son la mejor parte!',
                textSecondary,
              ),

              const SizedBox(height: 24),

              // 6. Botón de Compartir Retrovoz Challenge
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: AppConstants.playStoreUrl,
                        subject: 'Retrovoz Challenge',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'Compartir Retrovoz challenge',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildParagraph(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: color,
        height: 1.55,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

