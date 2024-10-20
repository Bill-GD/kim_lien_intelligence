import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'viewer_wait.dart';

class ViewerExtraScreen extends StatefulWidget {
  final List<int> players;
  const ViewerExtraScreen({super.key, required this.players});

  @override
  State<ViewerExtraScreen> createState() => _ViewerExtraScreenState();
}

class _ViewerExtraScreenState extends State<ViewerExtraScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double maxTimeSec = 15;
  bool canShowQuestion = false, canGetNewQuestion = true;
  late ExtraQuestion currentQuestion;
  late final StreamSubscription<KLISocketMessage> sub;
  int signaledPlayer = -1;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Window.setEffect(effect: WindowEffect.transparent);
    _controller = AnimationController(vsync: this, duration: maxTimeSec.seconds)..addListener(() => setState(() {}));

    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.extraQuestion) {
        if (canGetNewQuestion) {
          currentQuestion = ExtraQuestion.fromJson(jsonDecode(m.message));
          canShowQuestion = true;
          _controller.duration = maxTimeSec.seconds;
          _controller.reset();
        }
      }

      if (m.type == KLIMessageType.continueTimer) {
        Future.delayed(1.seconds, () => _controller.forward());
        signaledPlayer = -1;
        audioHandler.play(assetHandler.accelBackground, true);
      }

      if (m.type == KLIMessageType.stopTimer) {
        _controller.stop();
        signaledPlayer = int.parse(m.message);
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const ViewerWaitScreen()),
        );
      }

      setState(() {});
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
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    color: Theme.of(context).colorScheme.background,
                    child: timer(questionContainer()),
                  );
                },
              ),
            ),
            const SizedBox(width: 32),
            players(),
          ],
        ),
      ),
    );
  }

  Widget players() {
    final height = (200 / widget.players.length) - 4;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: widget.players.map((e) {
          final p = MatchData().players[e];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: e == signaledPlayer ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.background,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(maxHeight: height),
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text('${p.name} (${p.point})', style: const TextStyle(fontSize: fontSizeMedium)),
            ),
          );
        }).toList(),
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
