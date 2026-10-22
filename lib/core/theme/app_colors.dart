import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Fondos principales - Modo Oscuro (azul marino y verdes profundos)
  static const Color darkBackground = Color(0xFF08131E);
  static const Color darkBackgroundAlt = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF112233);
  static const Color darkSurfaceCard = Color(0xFF162B3F);
  static const Color darkSurfaceStrong = Color(0xFF1F3A54);

  // Fondos principales - Modo Claro (limpios, modernos y legibles)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightBackgroundAlt = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9);
  static const Color lightSurfaceStrong = Color(0xFFE2E8F0);

  // Paleta Verde y Azul prevalente de Retrovoz Challenge
  static const Color primaryBlue = Color(0xFF0284C7); // Azul vibrante
  static const Color secondaryGreen = Color(0xFF10B981); // Verde esmeralda
  static const Color deepGreen = Color(0xFF059669);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color electricBlue = Color(0xFF38BDF8);
  static const Color darkAccent = Color(0xFF0284C7);
  static const Color violetAccent = Color(0xFF0284C7); // Mapeado al azul primario

  // Textos - Modo Oscuro
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Textos - Modo Claro
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Estados
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusRecording = Color(0xFFEF4444);

  // Degradados de la marca (Prevaleciendo Azul y Verde)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF10B981)],
  );

  static const LinearGradient reverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF10B981)],
  );

  static const LinearGradient buttonMicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF10B981)],
  );

  static const LinearGradient cardBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x800284C7), Color(0x3010B981)],
  );

  // Gradient colors utilizados en el Loading Screen (Prevaleciendo Verde y Azul oscuro)
  static const List<Color> loadingGradient = [
    Color(0xFF021626), // Azul marino profundo
    Color(0xFF032630), // Teal azulado
    Color(0xFF022019), // Verde esmeralda profundo
  ];
}
