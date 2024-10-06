import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'answer_slide.dart';
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
  int imageIndex = -1, questionNum = -1, totalImageCount = 0;
  double timePerImage = 0;
  late AnimationController _controller;
  late final StreamSubscription<KLISocketMessage> sub;
  late final String cachePath;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    StorageHandler.appCacheDirectory.then((p) => cachePath = '$p\\${MatchData().matchName}\\other');

    sub = KLIClient.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.accelQuestion) {
        final aQ = AccelQuestion.fromJson(jsonDecode(m.message));

        isArrange = aQ.type == AccelQuestionType.arrange;
        _controller.value = 0;
        question = aQ.question;
        canShowQuestion = true;
        questionNum++;

        final l = Directory(cachePath)
            .listSync()
            .where((e) => e is File && e.path.contains('accel_image_${questionNum}_'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        images = l.map((e) => Image.file(e as File));
        logHandler.info(
          'Loaded: c=${images.length}, q=$questionNum, l=${l.map((e) => e.path.split('\\').last).join('|')}',
        );

        // caching for continuous display
        PaintingBinding.instance.imageCache.clear(); // clear all cached images
        if (aQ.type == AccelQuestionType.sequence) {
          for (var i in images) {
            final stream = i.image.resolve(const ImageConfiguration());
            stream.addListener(ImageStreamListener((_, __) {}));
          }
        }
        totalImageCount = images.length;
        timePerImage = isArrange ? 30 : 30 / totalImageCount;
        imageIndex = -1;
      }

      if (m.type == KLIMessageType.continueTimer) {
        imageIndex = 0;
        _controller.forward();
      }

      if (m.type == KLIMessageType.revealArrangeAnswer) {
        imageIndex = 1;
      }

      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const ViewerWaitScreen()),
        );
      }

      if (m.type == KLIMessageType.showAnswers) {
        if (m.message.isNotEmpty) {
          final d = jsonDecode(m.message) as Map;

          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ViewerAnswerSlide(
                playerNames: MatchData().players.map((e) => e.name),
                answers: (d['answers'] as List).map((e) => e as String),
                times: (d['times'] as List).map((e) => e as double),
              ),
            ),
          );
        }
      }
      setState(() {});
    });

    _controller = AnimationController(vsync: this, duration: 30.seconds)
      ..addListener(() {
        final t = _controller.value * 30;
        if (t >= 30) {
          setState(() {});
          return;
        }

        if (imageIndex >= totalImageCount - 1) {
          setState(() {});
          return;
        }
        if (!isArrange && t >= timePerImage * (imageIndex + 1)) imageIndex++;
        setState(() {});
      });

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ViewerAccelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateChild = () => setState(() {});
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,
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
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.transparent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            canShowQuestion ? 'Question ${questionNum + 1}' : '',
                            style: const TextStyle(fontSize: fontSizeMedium),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: BorderDirectional(
                              start: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: IntrinsicHeight(
                            child: canShowQuestion
                                ? Text(
                                    question,
                                    style: const TextStyle(fontSize: fontSizeMedium),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: RRectProgressPainter(
                    value: 30 - _controller.value * 30,
                    minValue: 0,
                    maxValue: 30.0,
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.red,
                    strokeWidth: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        image: imageIndex >= 0
                            ? DecorationImage(
                                image: images.elementAt(imageIndex).image,
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
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
}
