import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/blog_article_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToBlog(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    Navigator.pop(context); // Cierra el Drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlogArticleScreen(
          title: title,
          url: url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color drawerBg =
        isDark ? AppColors.darkBackgroundAlt : AppColors.lightBackgroundAlt;
    final Color surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurfaceCard;
    final Color borderColor =
        isDark ? AppColors.darkSurfaceStrong : AppColors.lightSurfaceStrong;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header del Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonMicGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retrovoz Challenge',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sonidos en reversa',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Opciones de Navegación del Drawer
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                children: [
                  // 1. Switch de Tema (Claro / Oscuro) en primer lugar
                  ListenableBuilder(
                    listenable: InjectionContainer.themeController,
                    builder: (context, _) {
                      final bool isDarkActive =
                          InjectionContainer.themeController.isDarkMode;
                      return Container(
                        margin: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          bottom: 10,
                          top: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.5)
                              : AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDarkActive
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: isDarkActive
                                  ? AppColors.electricBlue
                                  : const Color(0xFFF59E0B),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isDarkActive ? 'Modo Oscuro' : 'Modo Claro',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: isDarkActive,
                              activeThumbColor: AppColors.secondaryGreen,
                              activeTrackColor: AppColors.primaryBlue
                                  .withValues(alpha: 0.4),
                              onChanged: (val) {
                                InjectionContainer.themeController
                                    .toggleTheme(val);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 2. Inicio
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Inicio',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 4),

                  // 3. Favoritos (Audios guardados)
                  _DrawerItem(
                    icon: Icons.favorite_rounded,
                    title: 'Favoritos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.favorites);
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: borderColor,
                      thickness: 1,
                    ),
                  ),

                  // --- Entradas del Blog Oficial ---
                  _DrawerItem(
                    icon: Icons.sports_esports_outlined,
                    title: 'Cómo jugar con Retrovoz Challenge',
                    onTap: () => _navigateToBlog(
                      context,
                      title: 'Cómo jugar con Retrovoz Challenge',
                      url:
                          'https://retrovoz.blogspot.com/2026/10/como-jugar-adivinar-sonidos-al-reves.html',
                    ),
                  ),

                  const SizedBox(height: 4),

                  _DrawerItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Graba, invierte y juega',
                    onTap: () => _navigateToBlog(
                      context,
                      title: 'Graba, invierte y juega',
                      url:
                          'https://retrovoz.blogspot.com/2026/10/retrovoz-challenge-graba-invierte-y.html',
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: borderColor,
                      thickness: 1,
                    ),
                  ),

                  // 4. Política de Privacidad
                  _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de Privacidad',
                    onTap: () {
                      Navigator.pop(context); // Cierra el Drawer
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                    },
                  ),

                  const SizedBox(height: 4),

                  // 5. Acerca de (Explicación detallada de la app basada en el blog oficial)
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de',
                    onTap: () {
                      Navigator.pop(context); // Cierra el Drawer
                      Navigator.pushNamed(context, AppRoutes.about);
                    },
                  ),
                ],
              ),
            ),

            // Footer del Drawer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'v1.0.0 • Retrovoz Challenge',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = AppColors.primaryBlue;
    final Color inactiveText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? activeColor.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? activeColor : inactiveText,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primaryBlue)
                : inactiveText,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
