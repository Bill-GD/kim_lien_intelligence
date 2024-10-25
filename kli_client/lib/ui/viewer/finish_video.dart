import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:video_player/video_player.dart';

import '../../global.dart';
import '../../match_data.dart';

class ViewerFinishVideoScreen extends StatefulWidget {
  final String question, videoPath;
  const ViewerFinishVideoScreen({super.key, required this.question, required this.videoPath});

  @override
  State<ViewerFinishVideoScreen> createState() => _ViewerFinishVideoScreenState();
}

class _ViewerFinishVideoScreenState extends State<ViewerFinishVideoScreen> {
  late final StreamSubscription<KLISocketMessage> sub;
  late final VideoPlayerController vidController;
  bool vidPlaying = true;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});

    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.continueTimer) {
        vidController.dispose();
        Navigator.pop(context);
      }
      if (m.type == KLIMessageType.playVideo) {
        vidController.play();
        setState(() => vidPlaying = true);
      }
      setState(() {});
    });

    final v = '$cachePath\\${MatchData().matchName}\\other\\${widget.videoPath}';
    logHandler.info('Playing: $v');
    vidController = VideoPlayerController.file(File(v))..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    sub.cancel();
    vidController.dispose();
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
          // color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                // widget.question,
                'Trả lời câu hỏi trong video',
                style: TextStyle(fontSize: fontSizeMedium),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: BorderDirectional(top: BorderSide(color: Colors.white)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: vidPlaying
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [VideoPlayer(vidController)],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
