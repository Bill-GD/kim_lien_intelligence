import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'viewer_wait.dart';

class ViewerAccelScreen extends StatefulWidget {
  const ViewerAccelScreen({super.key});

  @override
  State<ViewerAccelScreen> createState() => _ViewerAccelScreenState();
}

class _ViewerAccelScreenState extends State<ViewerAccelScreen> with SingleTickerProviderStateMixin {
  String question = '';
  Iterable<Image> images = [];
  bool canShowQuestion = false, isArrange = false;
  Timer? timer;
  int imageIndex = 0, questionNum = 0, totalImageCount = 0;
  double timePerImage = 0, currentTime = 0;
  late AnimationController _controller;
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});

    sub = KLIClient.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.accelQuestion) {
        final aQ = AccelQuestion.fromJson(jsonDecode(m.message));

        isArrange = aQ.type == AccelQuestionType.arrange;
        question = aQ.question;

        final cache = '${await StorageHandler.appCacheDirectory}\\${MatchData().matchName}\\other';
        images = Directory(cache)
            .listSync()
            .where((e) => e is File && e.path.contains('accel_image_$questionNum'))
            .map((e) => Image.file(e as File));

        // caching for continuous display
        PaintingBinding.instance.imageCache.clear(); // clear all cached images
        if (aQ.type == AccelQuestionType.sequence) {
          for (var i in images) {
            final stream = i.image.resolve(const ImageConfiguration());
            stream.addListener(ImageStreamListener((_, __) {}));
          }
        }

        _controller.reset();
        totalImageCount = images.length;
        timePerImage = 30 / totalImageCount;
        imageIndex = 0;
        canShowQuestion = true;
        questionNum++;
      }

      if (m.type == KLIMessageType.continueTimer) {
        if (!isArrange) startImageShow();
        _controller.forward();
      }

      if (m.type == KLIMessageType.revealArrangeAnswer) {
        imageIndex = 1;
      }

      if (m.type == KLIMessageType.endSection && mounted) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const ViewerWaitScreen()),
        );
      }
      setState(() {});
    });

    if (images.length == 1) {
      setState(() {});
      return;
    }

    _controller = AnimationController(vsync: this, duration: 30.seconds)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // started = false;
        }
      });

    setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: isTesting,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: BorderDirectional(
                            end: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          canShowQuestion ? 'Question $questionNum' : '',
                          style: const TextStyle(fontSize: fontSizeMedium),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: BorderDirectional(
                            end: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          question,
                          style: const TextStyle(fontSize: fontSizeMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CustomPaint(
                  painter: RRectProgressPainter(
                    value: 30 - _controller.value * 30,
                    minValue: 0,
                    maxValue: 30.0,
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.red,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: canShowQuestion
                          ? DecorationImage(
                              image: images.elementAt(imageIndex).image,
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startImageShow() {
    timer = Timer.periodic(timePerImage.seconds, (t) {
      if (currentTime >= 30) {
        t.cancel();
        timer = null;
        return;
      }
      if (imageIndex >= totalImageCount - 1) return;
      imageIndex++;
      currentTime += timePerImage;
    });
  }
}
