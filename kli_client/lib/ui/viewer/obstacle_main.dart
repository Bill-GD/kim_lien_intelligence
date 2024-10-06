import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'answer_slide.dart';
import 'obstacle_image.dart';
import 'obstacle_rows.dart';
import 'viewer_wait.dart';

class ViewerObstacleMainScreen extends StatefulWidget {
  final int timeLimitSec = 15;
  const ViewerObstacleMainScreen({super.key});

  @override
  State<ViewerObstacleMainScreen> createState() => _ViewerObstacleMainScreenState();
}

class _ViewerObstacleMainScreenState extends State<ViewerObstacleMainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool canShowQuestion = false;
  late ObstacleQuestion currentQuestion;
  late final StreamSubscription<KLISocketMessage> sub;
  late final List<String> answers;
  final revealed = [false, false, false, false], answered = [false, false, false, false];
  late final String obsImage;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Window.setEffect(effect: WindowEffect.transparent);
    obsImage = '$cachePath\\${MatchData().matchName}\\other\\oi.png';
    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, type: KLIMessageType.rowCharCounts),
    );

    sub = KLIClient.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.obstacleQuestion) {
        if (!canShowQuestion) {
          Future.delayed(1.seconds).then((value) {
            _controller.forward();
          });
        }
        currentQuestion = ObstacleQuestion.fromJson(jsonDecode(m.message));
        canShowQuestion = true;
        final qId = currentQuestion.id;
        if (qId < 4) answers[qId] = currentQuestion.answer;
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.rowCharCounts) {
        final charCounts = jsonDecode(m.message) as List;
        answers = List.generate(4, (i) => 'a' * charCounts[i]);
      }

      if (m.type == KLIMessageType.revealRow) {
        revealed[currentQuestion.id] = true;
      }

      if (m.type == KLIMessageType.hideQuestion) {
        if (currentQuestion.id <= 3) answered[currentQuestion.id] = true;
        canShowQuestion = false;
        _controller.reset();
      }

      if (m.type == KLIMessageType.stopTimer) {
        _controller.stop();
      }

      if (m.type == KLIMessageType.continueTimer) {
        _controller.forward();
      }

      if (m.type == KLIMessageType.showObstacleRows) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ViewerObstacleRowsScreen(
              answers: answers,
              revealedAnswers: revealed,
              answeredRows: answered,
            ),
          ),
        );
      }

      if (m.type == KLIMessageType.obstacleImage) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ViewerObstacleImageScreen(
              imagePath: obsImage,
              revealedImageParts: List<bool>.from(jsonDecode(m.message)),
            ),
          ),
        );
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
                showTime: false,
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

    _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.timeLimitSec))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // started = false;
        }
      });
  }

  @override
  void didUpdateWidget(covariant ViewerObstacleMainScreen oldWidget) {
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
                      canShowQuestion ? 'Question ${currentQuestion.id + 1}' : '',
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
                      (widget.timeLimitSec * (1 - _controller.value)).toInt().toString(),
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
    for (final i in range(0, 3)) {
      final p = MatchData().players[i];

      w.add(
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.horizontal(
              left: i == 0 ? const Radius.circular(10) : Radius.zero,
              right: i == 3 ? const Radius.circular(10) : Radius.zero,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                border: i < 3
                    ? BorderDirectional(
                        end: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                      )
                    : null,
              ),
              constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text('${p.name} (${p.point})', style: const TextStyle(fontSize: fontSizeMedium)),
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
        value: widget.timeLimitSec - _controller.value * widget.timeLimitSec,
        minValue: 0,
        maxValue: widget.timeLimitSec.toDouble(),
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
        child: Text(
          canShowQuestion ? currentQuestion.question : '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: fontSizeLarge),
        ),
      ),
    );
  }
}
