import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher.dart';

class SoundTest extends StatefulWidget {
  final AssetHandler assetHandler;
  final AudioHandler audioHandler;
  const SoundTest({super.key, required this.assetHandler, required this.audioHandler});

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
                await launchUrl(Uri.parse(AssetHandler.assetFolder));
              },
            ),
            Flexible(
              child: ListView.builder(
                itemCount: widget.assetHandler.soundCount,
                itemBuilder: (context, index) {
                  final sound = widget.assetHandler.soundList[index];
                  return ListTile(
                    title: Text(sound),
                    trailing: ElevatedButton(
                      onPressed: () {
                        widget.audioHandler.play(sound);
                      },
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
