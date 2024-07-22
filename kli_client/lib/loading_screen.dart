import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher.dart';

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
      await initPackageInfo();

      setState(() => loadingText = 'Checking assets...');
      initAssetHandler();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Initializing audio handler...');
      initAudioHandler();
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Loading background image...');
      bgDecorationImage = await getBackgroundWidget(assetHandler);
      await Future.delayed(widget.delayMilli);

      setState(() => loadingText = 'Finished initialization');
      await Future.delayed(widget.delayMilli);

      if (mounted) {
        Navigator.of(context).push(
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
                          await launchUrl(Uri.parse(AssetHandler.assetFolder));
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
