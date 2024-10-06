import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:video_player/video_player.dart';

import '../../global.dart';

class ViewerFinishVideoScreen extends StatefulWidget {
  final String question, videoPath;
  const ViewerFinishVideoScreen({super.key, required this.question, required this.videoPath});

  @override
  State<ViewerFinishVideoScreen> createState() => _ViewerFinishVideoScreenState();
}

class _ViewerFinishVideoScreenState extends State<ViewerFinishVideoScreen> {
  late final StreamSubscription<KLISocketMessage> sub;
  VideoPlayerController? vidController;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});

    StorageHandler.appCacheDirectory.then(
      (value) => vidController = VideoPlayerController.file(File(value + widget.videoPath))
        ..initialize().then((_) => setState(() {})),
    );

    sub = KLIServer.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.continueTimer) {
        Navigator.pop(context);
      }
      if (m.type == KLIMessageType.playVideo) {
        vidController?.play();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    sub.cancel();
    vidController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: isTesting,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: BorderDirectional(bottom: BorderSide(color: Colors.white)),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: fontSizeMedium),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Container(
                  child: vidController != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 24),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                VideoPlayer(vidController!),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
