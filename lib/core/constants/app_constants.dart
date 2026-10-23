import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AppConstants {
  AppConstants._();

  /// Versión leída dinámicamente desde pubspec.yaml (o FLUTTER_BUILD_NAME)
  static String _appVersion = const String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: '1.0.1',
  );

  static String _buildNumber = const String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: '1',
  );

  /// Nombre de versión semántica (ej. "1.0.1") sincronizado con pubspec.yaml
  static String get appVersion => _appVersion;

  /// Número de compilación (ej. "1") sincronizado con pubspec.yaml
  static String get buildNumber => _buildNumber;

  /// Versión completa con build number (ej. "1.0.1+1")
  static String get fullVersion =>
      _buildNumber.isNotEmpty ? '$_appVersion+$_buildNumber' : _appVersion;

  /// Sincroniza la versión de la UI leyendo directamente el archivo pubspec.yaml
  static Future<void> loadVersionFromPubspec() async {
    try {
      final String pubspecContent = await rootBundle.loadString('pubspec.yaml');
      parseVersionFromPubspecContent(pubspecContent);
    } catch (e) {
      debugPrint(
        '[AppConstants] No se pudo leer pubspec.yaml, usando versión $_appVersion: $e',
      );
    }
  }

  /// Extrae el campo `version:` del contenido de un pubspec.yaml
  @visibleForTesting
  static void parseVersionFromPubspecContent(String content) {
    final RegExp versionRegex = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    );
    final Match? match = versionRegex.firstMatch(content);
    if (match != null) {
      final String rawVersion = match.group(1)!.trim();
      final List<String> parts = rawVersion.split('+');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        _appVersion = parts.first;
      }
      if (parts.length > 1 && parts[1].isNotEmpty) {
        _buildNumber = parts[1];
      }
    }
  }

  /// URL de descarga de Retrovoz Challenge en Google Play Store
  /// (Puede actualizarse cuando esté publicada en tienda)
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.blogspot.retrovoz';

  /// Mensaje para compartir la aplicación
  static const String shareMessage =
      '¡Descubre Retrovoz Challenge! Graba tu voz, inviértela al revés y reta a tus amigos: $playStoreUrl';
}
