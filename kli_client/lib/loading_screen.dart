import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import 'connect_screen/connect_screen.dart';
import 'global.dart';

class LoadingScreen extends StatefulWidget {
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
    await initPackageInfo();
    await Future.delayed(200.ms);

    setState(() => loadingText = 'Loading background image...');
    bgWidget = await getBackgroundWidget(useDefaultBackground);
    await Future.delayed(200.ms);

    setState(() => loadingText = 'Finished initialization');
    await Future.delayed(200.ms);

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
