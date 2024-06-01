import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import 'connect_screen/connect_screen.dart';
import 'global.dart';

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
    super.initState();
    initializeApp();
  }

  void initializeApp() async {
    logHandler.depth = 1;
    await initPackageInfo();

    setState(() => loadingText = 'Loading background image...');
    bgWidget = await getBackgroundWidget(useDefaultBackground);
    await Future.delayed(widget.delayMilli);

    setState(() => loadingText = 'Finished initialization');
    await Future.delayed(widget.delayMilli);
    logHandler.depth = 0;

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ConnectPage()),
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
