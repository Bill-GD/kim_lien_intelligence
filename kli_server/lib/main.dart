import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kli_utils/kli_utils.dart';

import 'global.dart';
import 'start_screen/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await initStorageHandler();
  initLogger(storageHandler!.logFile);
  storageHandler = null;
  await initPackageInfo();
  logMessageStream.listen((m) {
    if (m.key == LogType.info) logger.i(m.value);
    if (m.key == LogType.warn) logger.w(m.value);
    if (m.key == LogType.error) logger.e(m.value);
  });

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
  }
  windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.show();
    await windowManager.focus();
    await WindowManager.instance.setFullScreen(true);
  });

  runApp(const KliServerApp());
}

class KliServerApp extends StatelessWidget {
  const KliServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      defaultThemeId: '${SchedulerBinding.instance.platformDispatcher.platformBrightness.name}_theme',
      themes: [
        AppTheme(
          id: 'light_theme',
          description: 'Light theme',
          data: ThemeData(
            useMaterial3: true,
            fontFamily: 'Nunito',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.light,
              error: Colors.redAccent,
            ).copyWith(background: Colors.white),
          ),
        ),
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
        child: Builder(
          builder: (context) => MaterialApp(
            theme: ThemeProvider.themeOf(context).data,
            home: const StartPage(),
          ),
        ),
      ),
    );
  }
}
