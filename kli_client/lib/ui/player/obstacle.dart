import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../connect_screen/overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class PlayerObstacleScreen extends StatefulWidget {
  final double timeLimitSec = 15;

  const PlayerObstacleScreen({super.key});

  @override
  State<PlayerObstacleScreen> createState() => _PlayerObstacleScreenState();
}

class _PlayerObstacleScreenState extends State<PlayerObstacleScreen> {
  double currentTimeSec = 15;
  bool canShowQuestion = false, canAnswer = false, canGuessObstacle = false, eliminated = false;
  String submittedAnswer = '';
  late ObstacleQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  final answerTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const Overview()),
        );
      }
      if (m.type == KLIMessageType.eliminated) {
        eliminated = true;
        canAnswer = canGuessObstacle = false;
        currentTimeSec = 0;
        timer?.cancel();
        setState(() {});
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }
      if (m.type == KLIMessageType.obstacleQuestion) {
        canGuessObstacle = true;
        if (canAnswer) return;

        currentQuestion = ObstacleQuestion.fromJson(jsonDecode(m.message));
        canShowQuestion = true;
        setState(() {});

        if (eliminated) return;
        createTimer();
        canAnswer = true;
      }
      if (m.type == KLIMessageType.hideQuestion) {
        answerTextController.text = '';
        submittedAnswer = '';
        canShowQuestion = false;
        if (!eliminated) currentTimeSec = 15;
      }

      setState(() {});

      if (eliminated) {
        setState(() {});
        return;
      }

      if (m.type == KLIMessageType.stopTimer) {
        timer?.cancel();
      }
      if (m.type == KLIMessageType.continueTimer) {
        canGuessObstacle = true;
        createTimer();
      }
      if (m.type == KLIMessageType.disableGuessObstacle) {
        canGuessObstacle = false;
      }
      if (m.type == KLIMessageType.correctObstacleAnswer) {
        canAnswer = canGuessObstacle = false;
        timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    sub.cancel();
    super.dispose();
  }

  void createTimer() {
    timer = Timer.periodic(1.seconds, (timer) {
      if (currentTimeSec <= 0) {
        timer.cancel();
        canAnswer = false;
        setState(() {});
        return;
      }
      currentTimeSec -= 1;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: kDebugMode,
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
          child: Row(
            children: [
              Flexible(
                flex: 9,
                child: Column(
                  children: [
                    questionContainer(),
                    const SizedBox(height: 32),
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

  Widget containerTop() {
    return Row(
      children: [
        for (final i in range(0, 3))
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
                  '${MatchData().players[i].name} (${MatchData().players[i].point})',
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget questionContainer() {
    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            containerTop(),
            Expanded(
              child: Stack(
                children: [
                  canShowQuestion
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          child: Text(
                            'Question ${currentQuestion.id + 1}',
                            style: const TextStyle(fontSize: fontSizeLarge),
                          ),
                        )
                      : const SizedBox(),
                  Container(
                    decoration: const BoxDecoration(
                      border: BorderDirectional(
                        top: BorderSide(color: Colors.white),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 128),
                    alignment: Alignment.center,
                    child: canShowQuestion
                        ? Text(
                            currentQuestion.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: fontSizeLarge),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget answerInput() {
    return KLITextField(
      readOnly: !canAnswer,
      controller: answerTextController,
      maxLines: 1,
      hintText: 'Enter Answer and press Enter to submit',
      onSubmitted: (text) {
        submittedAnswer = text;
        KLIClient.sendMessage(KLISocketMessage(
          senderID: KLIClient.clientID!,
          type: KLIMessageType.obstacleRowAnswer,
          message: text,
        ));
      },
    );
  }

  Widget playerInfo() {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      constraints: const BoxConstraints(maxWidth: 200),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedCircularProgressBar(
            currentTimeSec: currentTimeSec,
            totalTimeSec: widget.timeLimitSec,
            strokeWidth: 20,
            valueColor: const Color(0xFF00A906),
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 512),
          KLIButton(
            'Obstacle',
            enableCondition: canGuessObstacle,
            onPressed: () {
              timer?.cancel();
              KLIClient.sendMessage(KLISocketMessage(
                senderID: KLIClient.clientID!,
                type: KLIMessageType.guessObstacle,
              ));
              canGuessObstacle = false;
              setState(() {});
            },
          ),
          Text(
            'Submitted:\n$submittedAnswer',
            softWrap: true,
            style: const TextStyle(fontSize: fontSizeMedium),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
