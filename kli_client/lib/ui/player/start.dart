import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../connect_screen/overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class PlayerStartScreen extends StatefulWidget {
  final double timeLimitSec = 60;
  final int playerPos;

  const PlayerStartScreen({super.key, required this.playerPos});

  @override
  State<PlayerStartScreen> createState() => _PlayerStartScreenState();
}

class _PlayerStartScreenState extends State<PlayerStartScreen> {
  double currentTimeSec = 60;
  bool started = false, timeEnded = false;
  late StartQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> messageSubscription;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    messageSubscription = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.startQuestion) {
        if (timeEnded) return;
        if (!started) {
          timer = Timer.periodic(1.seconds, (timer) {
            if (currentTimeSec <= 0) {
              timer.cancel();
              timeEnded = true;
              setState(() {});
              return;
            }
            currentTimeSec -= 1;
            setState(() {});
          });
        }
        questionNum++;
        currentQuestion = StartQuestion.fromJson(jsonDecode(m.message));
        started = true;
      }
      if (m.type == KLIMessageType.correctStartAnswer) {
        MatchData().players[widget.playerPos].point = int.parse(m.message);
      }
      if (m.type == KLIMessageType.stopTimer) {
        timer?.cancel();
        // started = false; // add to hide question after time ended
      }
      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const Overview()),
        );
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    messageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
          child: Row(
            children: [
              Expanded(
                flex: 9,
                child: questionContainer(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: playerInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget questionInfo() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
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
                started ? 'Câu hỏi $questionNum' : '',
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topRight: Radius.circular(10)),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: BorderDirectional(
                  end: BorderSide(color: Colors.transparent),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                started ? StartQuestion.mapTypeDisplay(currentQuestion.subject) : '',
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget questionContainer() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        questionInfo(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: BorderDirectional(
                top: BorderSide(color: Colors.white),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 128),
            alignment: Alignment.center,
            child: Text(
              started ? currentQuestion.question : '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: fontSizeLarge),
            ),
          ),
        ),
      ]),
    );
  }

  Widget playerInfo() {
    return Column(
      children: [
        AnimatedCircularProgressBar(
          currentTimeSec: currentTimeSec,
          totalTimeSec: widget.timeLimitSec,
          strokeWidth: 20,
          valueColor: const Color(0xFF00A906),
          backgroundColor: Colors.red,
        ),
        const SizedBox(height: 128),
        Container(
          width: 128,
          height: 128,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.background,
            border: Border.all(color: Colors.white),
          ),
          child: Text(
            '${MatchData().players[widget.playerPos].point}',
            style: const TextStyle(fontSize: fontSizeMedium),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
