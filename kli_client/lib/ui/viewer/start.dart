import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'viewer_wait.dart';

class ViewerStartScreen extends StatefulWidget {
  final int timeLimitSec = 60;
  final int playerPos;
  const ViewerStartScreen({super.key, required this.playerPos});

  @override
  State<ViewerStartScreen> createState() => _ViewerStartScreenState();
}

class _ViewerStartScreenState extends State<ViewerStartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double currentTimeSec = 60;
  bool started = false;
  late StartQuestion currentQuestion;
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Window.setEffect(effect: WindowEffect.transparent);
    audioHandler.play(assetHandler.startPlayerStart);

    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.startQuestion) {
        if (!started) {
          _controller.forward();
          setState(() {});
        }
        currentQuestion = StartQuestion.fromJson(jsonDecode(m.message));
        started = true;
      }

      if (m.type == KLIMessageType.correctStartAnswer) {
        MatchData().players[widget.playerPos].point = int.parse(m.message);
        audioHandler.play(assetHandler.startCorrect);
      }

      if (m.type == KLIMessageType.playAudio) {
        audioHandler.play(m.message, m.message.contains('background'));
      }

      if (m.type == KLIMessageType.stopTimer) {
        _controller.stop();
        audioHandler.stop(true);
      }

      if (m.type == KLIMessageType.endSection) {
        audioHandler.play(assetHandler.startEndPlayer);
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const ViewerWaitScreen()),
        );
      }
      setState(() {});
    });

    _controller = AnimationController(vsync: this, duration: widget.timeLimitSec.seconds)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          started = false;
        }
      });
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
                      started ? StartQuestion.mapTypeDisplay(currentQuestion.subject) : '',
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
              // bottomLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
              right: i == 3 ? const Radius.circular(10) : Radius.zero,
              // bottomRight: i == 3 ? const Radius.circular(10) : Radius.zero,
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
          started ? currentQuestion.question : '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: fontSizeLarge),
        ),
      ),
    );
  }
}
