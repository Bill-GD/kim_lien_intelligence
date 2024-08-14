import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../global.dart';

class SoundTest extends StatefulWidget {
  const SoundTest({super.key});

  @override
  State<SoundTest> createState() => _SoundTestState();
}

class _SoundTestState extends State<SoundTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            KLIButton(
              'Mở thư mục Assets',
              onPressed: () async {
                await launchUrlString(
                  Uri.directory(AssetHandler.assetFolder).toFilePath(windows: true),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            Flexible(
              child: ListView.builder(
                itemCount: assetHandler.soundCount,
                itemBuilder: (context, index) {
                  final sound = assetHandler.soundList[index];
                  return ListTile(
                    title: Text(sound),
                    trailing: ElevatedButton(
                      onPressed: () => audioHandler.play(sound),
                      child: const Text('Play'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
