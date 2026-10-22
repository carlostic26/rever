import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rever/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeController defaults to light mode as requested', () {
    final controller = ThemeController();
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.isDarkMode, isFalse);
  });

  test('ThemeController toggles to dark mode and back to light mode', () async {
    final controller = ThemeController();

    await controller.toggleTheme(true);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isDarkMode, isTrue);

    await controller.toggleTheme(false);
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.isDarkMode, isFalse);
  });
}

