import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'connect_screen/connect_screen.dart';
import 'global.dart';

class LoadingScreen extends StatefulWidget {
  final delayMilli = const Duration(milliseconds: 150);
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool hasError = false;
  String errorMessage = '';
  String loadingText = 'Initializing package info...';

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  void initializeApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersionString = 'v${packageInfo.version}.${packageInfo.buildNumber}';
      logHandler.info('PackageInfo init: $appVersionString');

      setState(() => loadingText = 'Checking assets...');
      assetHandler = AssetHandler.init();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Initializing audio handler...');
      audioHandler = AudioHandler.init(updateDebugOverlay);
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Loading background image...');
      bgDecorationImage = await getBackgroundWidget(assetHandler);
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Clearing cache...');
      initCache();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Finished initialization');
      await Future.delayed(widget.delayMilli);

      if (kDebugMode) {
        showDebugInfo = true;
        updateDebugOverlay();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectPage()),
        );
      }
    } on Exception catch (e) {
      logHandler.error('Error initializing app: ${e.toString()}');
      hasError = true;
      errorMessage = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Missing assets', style: TextStyle(fontSize: fontSizeLarge)),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SingleChildScrollView(
                        child: Text(errorMessage, style: const TextStyle(fontSize: fontSizeMedium)),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      KLIButton('Exit', onPressed: () => exit(1)),
                      KLIButton(
                        'Open Asset Folder',
                        onPressed: () async {
                          await launchUrlString(
                            Uri.directory(AssetHandler.assetFolder).toFilePath(windows: true),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      KLIButton(
                        'Download Assets',
                        onPressed: () async {
                          await launchUrl(Uri.parse(
                            'https://github.com/Bill-GD/kim_lien_intelligence/releases/tag/assets',
                          ));
                        },
                      )
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(loadingText, style: const TextStyle(fontSize: fontSizeMedium)),
                ],
              ),
      ),
    );
  }

  void initCache() {
    cachePath = StorageHandler.clientMatchDataPath;
    logHandler.info('Data path: $cachePath');

    getApplicationCacheDirectory().then((oldCache) {
      final newCache = Directory(cachePath);
      if (newCache.existsSync()) {
        oldCache.deleteSync(recursive: true);
        return;
      }
      if (oldCache.existsSync()) {
        // oldCache.renameSync(cachePath);
        copyDirectory(oldCache.path, cachePath);

        oldCache.deleteSync(recursive: true);
        return;
      }

      newCache.createSync(recursive: true);
      StorageHandler().writeStringToFile(
        '$cachePath\\cache.txt',
        dedent('''The folder(s) here are used for caching match data (names, images, videos)
        so that the client app doesn't need to request new data every time joining a match.'''),
        createIfNotExists: true,
        abortIfExists: true,
      );
    });
  }

  void copyDirectory(String oldPath, String newPath) {
    final oldDir = Directory(oldPath), newDir = Directory(newPath);

    for (final m in oldDir.listSync()) {
      if (m is File) {
        final newFile = File(m.path.replaceAll(oldDir.path, newDir.path));
        if (!newFile.existsSync()) newFile.createSync(recursive: true);
        m.copySync(newFile.path);
      } else {
        copyDirectory(m.path, m.path.replaceAll(oldDir.path, newDir.path));
      }
    }
  }
}
