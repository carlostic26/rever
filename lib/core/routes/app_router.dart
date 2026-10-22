import 'package:flutter/material.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/privacy_policy_screen.dart';
import '../../features/home/presentation/screens/recording_screen.dart';
import '../../features/loading/presentation/screens/loading_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.loading:
        return MaterialPageRoute(
          builder: (_) => const LoadingScreen(),
          settings: settings,
        );

      case AppRoutes.home:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );

      case AppRoutes.recording:
        return MaterialPageRoute(
          builder: (_) => const RecordingScreen(),
          settings: settings,
        );

      case AppRoutes.privacyPolicy:
        final url = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => url != null
              ? PrivacyPolicyScreen(url: url)
              : const PrivacyPolicyScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }
}
