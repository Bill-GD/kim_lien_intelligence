import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'finish_video.dart';
import 'viewer_wait.dart';

class ViewerFinishScreen extends StatefulWidget {
  final int playerPos;
  const ViewerFinishScreen({super.key, required this.playerPos});

  @override
  State<ViewerFinishScreen> createState() => _ViewerFinishScreenState();
}

class _ViewerFinishScreenState extends State<ViewerFinishScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double maxTimeSec = 10;
  bool canShowQuestion = false, canGetNewQuestion = true;
  late FinishQuestion currentQuestion;
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    audioHandler.play(assetHandler.finishPlayerStart);
    Future.delayed(1.seconds, () => audioHandler.play(assetHandler.finishShowPacks));
    Window.setEffect(effect: WindowEffect.transparent);
    _controller = AnimationController(vsync: this, duration: maxTimeSec.seconds)..addListener(() => setState(() {}));

    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.finishQuestion) {
        if (canGetNewQuestion) {
          currentQuestion = FinishQuestion.fromJson(jsonDecode(m.message));
          canShowQuestion = true;
          maxTimeSec = currentQuestion.point / 10 * 5 + 5;
          _controller.duration = maxTimeSec.seconds;
          _controller.reset();
          if (currentQuestion.mediaPath.isNotEmpty) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ViewerFinishVideoScreen(
                  question: currentQuestion.question,
                  videoPath: 'f_${currentQuestion.mediaPath.split(r'\').last}',
                ),
              ),
            );
          }
        }
      }

      if (m.type == KLIMessageType.playAudio) {
        audioHandler.play(m.message);
      }

      if (m.type == KLIMessageType.continueTimer) {
        Future.delayed(1.seconds, () => _controller.forward());
        audioHandler.play(assetHandler.finishBackground[currentQuestion.point]!, true);
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.enableSteal) {
        audioHandler.play(assetHandler.finishStealWait, true);
      }

      if (m.type == KLIMessageType.endSection) {
        audioHandler.play(assetHandler.finishEndPlayer);
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const ViewerWaitScreen()),
        );
      }

      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ViewerFinishScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateChild = () => setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: isTesting),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 8,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      players(),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        color: Theme.of(context).colorScheme.background,
                        child: timer(questionContainer()),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                      color: Theme.of(context).colorScheme.background,
                    ),
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(maxHeight: 80),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      canShowQuestion ? '${currentQuestion.point} điểm' : '',
                      style: const TextStyle(fontSize: fontSizeLarge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                      color: Theme.of(context).colorScheme.background,
                    ),
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minWidth: 170, maxHeight: 200),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      MatchData().players[widget.playerPos].point.toString(),
                      style: const TextStyle(fontSize: fontSizeLarge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget players() {
    final w = <Widget>[];
    String s;
    for (final i in range(0, 3)) {
      final isCurPlayer = i == widget.playerPos;

      final p = MatchData().players[i];
      s = '${p.name}${isCurPlayer ? '' : ' (${p.point})'}';

      w.add(
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.horizontal(
              left: i == 0 ? const Radius.circular(10) : Radius.zero,
              right: i == 3 ? const Radius.circular(10) : Radius.zero,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: i == widget.playerPos ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.background,
                border: i < 3
                    ? BorderDirectional(
                        end: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                      )
                    : null,
              ),
              constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(s, style: const TextStyle(fontSize: fontSizeMedium)),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [for (final e in w) e],
      ),
    );
  }

  Widget timer(Widget child) {
    return CustomPaint(
      painter: RRectProgressPainter(
        value: maxTimeSec - _controller.value * maxTimeSec,
        minValue: 0,
        maxValue: maxTimeSec.toDouble(),
        foregroundColor: Colors.green,
        backgroundColor: Colors.red,
      ),
      child: child,
    );
  }

  Widget questionContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 128),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: AutoSizeText(
          canShowQuestion ? currentQuestion.question : '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: fontSizeLarge),
        ),
      ),
    );
  }
}
