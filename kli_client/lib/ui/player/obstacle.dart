import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_client/match_data.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class PlayerObstacleScreen extends StatefulWidget {
  final double timeLimitSec = 15;

  const PlayerObstacleScreen({super.key});

  @override
  State<PlayerObstacleScreen> createState() => _PlayerObstacleScreenState();
}

class _PlayerObstacleScreenState extends State<PlayerObstacleScreen> {
  double currentTimeSec = 15;
  bool started = false, timeEnded = false;
  late ObstacleQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> messageSubscription;
  final answerTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    messageSubscription = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.obstacleQuestion) {
        if (timeEnded) return;
        if (!started) {
          timer = Timer.periodic(10.ms, (timer) {
            if (currentTimeSec <= 0) {
              timer.cancel();
              timeEnded = true;
              started = false;
              setState(() {});
              return;
            }
            currentTimeSec -= .01;
            setState(() {});
          });
        }
        currentQuestion = ObstacleQuestion.fromJson(jsonDecode(m.message));
        started = true;
        setState(() {});
      }
      // if (m.type == KLIMessageType.correctStartAnswer) {
      //   MatchData().players[widget.playerPos].point = int.parse(m.message);
      //   setState(() {});
      // }
      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
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
                child: Column(
                  children: [
                    questionContainer(),
                    answerInput(),
                  ],
                ),
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
                MatchData().players[MatchData().playerPos].name,
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
                started ? 'Question ${currentQuestion.id}' : '',
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
            child: started
                ? Text(
                    currentQuestion.question,
                    textAlign: TextAlign.center,
                    // textWidthBasis: TextWidthBasis.longestLine,
                    style: const TextStyle(fontSize: fontSizeLarge),
                  )
                : null,
          ),
        ),
      ]),
    );
  }

  Widget answerInput() {
    return KLITextField(
      readOnly: started && !timeEnded,
      controller: answerTextController,
      maxLines: 1,
      hintText: 'Enter Answer and press Enter to submit',
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
            '${MatchData().players[MatchData().playerPos].point}',
            style: const TextStyle(fontSize: fontSizeMedium),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
