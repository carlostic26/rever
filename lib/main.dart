import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (.env) para AdMob y configuración
  await dotenv.load(fileName: '.env');

  // Inicialización de inyección de dependencias y servicios (Clean Architecture)
  await InjectionContainer.init();

  // Inicializar SDK de Google Mobile Ads
  await InjectionContainer.initializeAdsUseCase();

  runApp(const ReverApp());
}

class ReverApp extends StatelessWidget {
  const ReverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: InjectionContainer.themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Retrovoz Challenge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: InjectionContainer.themeController.themeMode,
          initialRoute: AppRoutes.loading,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
