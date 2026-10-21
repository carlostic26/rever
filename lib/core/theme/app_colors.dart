import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Fondos principales (azul marino profundo y casi negros)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkBackgroundAlt = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF141E33);
  static const Color darkSurfaceCard = Color(0xFF1A2642);
  static const Color darkSurfaceStrong = Color(0xFF263554);

  // Acentos de Rever Verbal: Violetas, morados y azules
  static const Color violetAccent = Color(0xFF8B5CF6);
  static const Color purpleAccent = Color(0xFFA855F7);
  static const Color purpleDeep = Color(0xFF7C3AED);
  static const Color electricBlue = Color(0xFF38BDF8);
  static const Color darkAccent = Color(0xFF3B82F6);

  // Textos
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Estados
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusRecording = Color(0xFFEF4444);

  // Degradados de la marca
  static const LinearGradient reverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  );

  static const LinearGradient buttonMicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF2563EB)],
  );

  static const LinearGradient cardBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x808B5CF6), Color(0x2038BDF8)],
  );

  // Gradient colors utilizados en el Loading Screen
  static const List<Color> loadingGradient = [
    Color.fromARGB(255, 2, 13, 34),
    Color.fromARGB(190, 6, 38, 90),
    Color.fromARGB(120, 6, 74, 168),
  ];
}
