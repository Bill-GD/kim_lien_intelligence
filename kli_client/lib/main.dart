import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';
import 'loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogHandler();
  logHandler.info('Starting KLIClient');

  logMessageStream.listen((m) {
    if (m.$1 == LogType.info) logHandler.info(m.$2, d: m.$3);
    if (m.$1 == LogType.warn) logHandler.warn(m.$2, d: m.$3);
    if (m.$1 == LogType.error) logHandler.error(m.$2, d: m.$3);
  });

  if (!kIsWeb && Platform.isWindows) {
    await windowManager.hide();
    await windowManager.ensureInitialized();
  }
  await windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const KliClientApp());
}

class KliClientApp extends StatelessWidget {
  const KliClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      defaultThemeId: 'dark_theme',
      themes: [
        AppTheme(id: 'light_theme', description: 'Light theme (disabled)', data: ThemeData()),
        AppTheme(
          id: 'dark_theme',
          description: 'Dark theme',
          data: ThemeData(
            useMaterial3: true,
            fontFamily: 'Nunito',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.dark,
              error: Colors.redAccent,
            ),
          ),
        ),
      ],
      child: ThemeConsumer(
        child: Builder(builder: (context) {
          return MaterialApp(
            scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse}),
            theme: ThemeProvider.themeOf(context).data,
            home: const LoadingScreen(),
          );
        }),
      ),
    );
  }
}
