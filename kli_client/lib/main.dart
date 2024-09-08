import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'global.dart';
import 'loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();

  RenderErrorBox.backgroundColor = Colors.transparent;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  PlatformDispatcher.instance.onError = (e, s) {
    logHandler.error(e.toString(), stackTrace: s);
    final curContext = navigatorKey.currentContext;
    if (curContext == null) return false;

    if (e is! KLIException) {
      showPopupMessage(
        curContext,
        title: e.toString(),
        content: s.toString(),
        centerContent: false,
      );
      return true;
    }

    showPopupMessage(
      curContext,
      title: e.formatTitle(),
      content: e.message,
    );
    return true;
  };

  initLogHandler();
  logHandler.info('Starting KLIClient');

  logMessageStream.listen((m) {
    if (m.$1 == LogType.info) logHandler.info(m.$2);
    if (m.$1 == LogType.warn) logHandler.warn(m.$2);
    if (m.$1 == LogType.error) logHandler.error(m.$2);
  });

  if (!kIsWeb && Platform.isWindows) {
    await windowManager.hide();
    await windowManager.ensureInitialized();
  }
  windowManager.setAlwaysOnTop(!isTesting && false);
  await windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(KliClientApp(navKey: navigatorKey));
}

class KliClientApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navKey;
  const KliClientApp({super.key, required this.navKey});

  @override
  State<KliClientApp> createState() => _KliClientAppState();
}

class _KliClientAppState extends State<KliClientApp> {
  Offset _offset = Offset.zero;

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
        child: Builder(
          builder: (context) {
            return MaterialApp(
              navigatorKey: widget.navKey,
              builder: (context, child) {
                ErrorWidget.builder = (d) => WidgetErrorScreen(e: d);
                updateDebugOverlay = () {
                  // logHandler.info('Updating debug overlay');
                  setState(() {});
                };
                return Stack(
                  children: [
                    child!,
                    showDebugInfo ? debugOverlay() : const SizedBox(),
                  ],
                );
              },
              scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse}),
              theme: ThemeProvider.themeOf(context).data,
              home: const LoadingScreen(),
            );
          },
        ),
      ),
    );
  }

  Widget debugOverlay() {
    return Positioned(
      top: _offset.dy,
      left: _offset.dx,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() => _offset += details.delta),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onBackground,
            border: Border.all(color: Theme.of(context).colorScheme.background),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.background,
                  fontSize: fontSizeSmall,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App version: $appVersionString (${buildDate.reverseDate})'),
                Row(
                  children: [
                    const Text('Test mode: '),
                    GestureDetector(
                      onTap: () {
                        logHandler.info('Toggling test mode');
                        setState(() => isTesting = !isTesting);
                        updateChild();
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(isTesting ? '✔️' : '❌'),
                      ),
                    ),
                  ],
                ),
                Text('Position: (${_offset.dx.toInt()}, ${_offset.dy.toInt()})'),
                Text('Client ID: ${KLIClient.clientID}'),
                Text('Host: ${KLIClient.socket?.remoteAddress.address}:${KLIClient.socket?.remotePort}'),
                Text('Client: ${KLIClient.socket?.address.address}:${KLIClient.socket?.port}'),
                Text('Receiving data: ${KLIClient.receivingData}'),
                Text('Playing sound: ${audioHandler.isPlaying}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
