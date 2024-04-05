import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';
import 'start_screen/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initLogger();
  await initPackageInfo();
  await initStorageHandler();

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
  }

  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(800, 600),
  //   center: true,
  //   backgroundColor: Colors.transparent,
  //   skipTaskbar: false,
  //   titleBarStyle: TitleBarStyle.hidden,
  //   windowButtonVisibility: false,
  // );
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
