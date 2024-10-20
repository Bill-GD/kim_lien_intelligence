import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'global.dart';
import 'home_screen/home_screen.dart';

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

      setState(() => loadingText = 'Checking assets..');
      assetHandler = AssetHandler.init();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Initializing audio handler...');
      audioHandler = AudioHandler.init(updateDebugOverlay);
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Loading background image...');
      bgDecorationImage = await getBackgroundWidget(assetHandler);
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Initializing storage handler...');
      storageHandler = StorageHandler.init();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Finished initialization');
      await Future.delayed(widget.delayMilli);

      logHandler.info('Finished initializing app');
      logHandler.empty();

      if (kDebugMode) {
        showDebugInfo = true;
        updateDebugOverlay();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
}
