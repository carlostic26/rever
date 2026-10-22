import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../screens/coming_soon_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToComingSoon(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    Navigator.pop(context); // Cierra el Drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComingSoonScreen(
          title: title,
          description: description,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBackgroundAlt,
      child: SafeArea(
        child: Column(
          children: [
            // Header del Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withValues(alpha: 0.6),
                border: const Border(
                  bottom: BorderSide(
                    color: AppColors.darkSurfaceStrong,
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
                          color: AppColors.violetAccent.withValues(alpha: 0.35),
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
                          'Retrovoz',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sonidos en reversa',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.electricBlue,
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
                  // 1. Inicio
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Inicio',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(
                        context,
                      ); // Cierra el Drawer y permanece en Inicio
                    },
                  ),

                  const SizedBox(height: 4),

                  // 2. Mis audios
                  _DrawerItem(
                    icon: Icons.mic_none_rounded,
                    title: 'Mis audios',
                    onTap: () => _navigateToComingSoon(
                      context,
                      title: 'Mis audios',
                      description:
                          'Gestiona, organiza y escucha tus grabaciones anteriores.',
                      icon: Icons.library_music_rounded,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 3. Favoritos
                  _DrawerItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Favoritos',
                    onTap: () => _navigateToComingSoon(
                      context,
                      title: 'Favoritos',
                      description:
                          'Tus audios invertidos y retos favoritos en un solo lugar.',
                      icon: Icons.favorite_rounded,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 4. Ajustes
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    title: 'Ajustes',
                    onTap: () => _navigateToComingSoon(
                      context,
                      title: 'Ajustes',
                      description:
                          'Configura la calidad de grabación, velocidad de inversión y preferencias.',
                      icon: Icons.settings_rounded,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: AppColors.darkSurfaceStrong,
                      thickness: 1,
                    ),
                  ),

                  // 5. Acerca de
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de',
                    onTap: () => _navigateToComingSoon(
                      context,
                      title: 'Acerca de',
                      description:
                          'Retrovoz v1.0.0\nLa app para escuchar y adivinar palabras y sonidos reproducidos en reversa.',
                      icon: Icons.graphic_eq_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Footer del Drawer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'v1.0.0 • Retrovoz',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.darkTextMuted,
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.violetAccent.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.violetAccent.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.violetAccent
              : AppColors.darkTextSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.darkTextSecondary,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violetAccent,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
