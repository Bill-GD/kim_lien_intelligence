import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import 'global.dart';
import 'start_screen/start_screen.dart';

class LoadingScreen extends StatefulWidget {
  final delayMilli = const Duration(milliseconds: 150);
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String loadingText = 'Initializing package info...';

  @override
  void initState() {
    logHandler.depth = 1;
    super.initState();
    initializeApp();
  }

  void initializeApp() async {
    await initPackageInfo();

    try {
      setState(() => loadingText = 'Checking assets..');
      initAssetHandler();
      await Future.delayed(widget.delayMilli);
    } on Exception catch (e) {
      logHandler.error('Error initializing app: ${e.toString()}');
      if (mounted) {
        await assetErrorDialog(context, message: e.toString(), assetPath: AssetHandler.assetFolder);
      }
    }

    setState(() => loadingText = 'Initializing audio handler...');
    initAudioHandler();
    await Future.delayed(widget.delayMilli);

    setState(() => loadingText = 'Loading background image...');
    bgWidget = await getBackgroundWidget(assetHandler);
    await Future.delayed(widget.delayMilli);

    setState(() => loadingText = 'Initializing storage handler...');
    await initStorageHandler();
    await Future.delayed(widget.delayMilli);

    setState(() => loadingText = 'Finished initialization');
    await Future.delayed(widget.delayMilli);

    logHandler.depth = 0;
    logHandler.info('Finished initializing app\n');

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const StartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
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
