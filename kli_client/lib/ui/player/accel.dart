import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../connect_screen/overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class PlayerAccelScreen extends StatefulWidget {
  final double timeLimitSec = 30;

  const PlayerAccelScreen({super.key});

  @override
  State<PlayerAccelScreen> createState() => _PlayerAccelScreenState();
}

class _PlayerAccelScreenState extends State<PlayerAccelScreen> {
  double currentTimeSec = 30;
  bool canShowQuestion = false, canAnswer = false;
  String submittedAnswer = '';
  late AccelQuestion currentQuestion;
  int questionNum = 0;
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

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.accelQuestion) {
        if (canAnswer) return;
        questionNum++;
        currentQuestion = AccelQuestion.fromJson(jsonDecode(m.message));
        currentTimeSec = 30;
        canShowQuestion = true;
      }

      if (m.type == KLIMessageType.continueTimer) {
        canAnswer = true;
        createTimer();
      }

      if (m.type == KLIMessageType.hideQuestion) {
        answerTextController.text = '';
        submittedAnswer = '';
        canShowQuestion = false;
        currentTimeSec = 30;
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
    timer = Timer.periodic(10.ms, (timer) {
      if (currentTimeSec <= 0) {
        timer.cancel();
        canAnswer = false;
        setState(() {});
        return;
      }
      currentTimeSec -= .01;
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
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
                topRight: i == 3 ? const Radius.circular(10) : Radius.zero,
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
                            'Question $questionNum',
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
      autofocus: canAnswer,
      hintText: 'Enter Answer and press Enter to submit',
      onSubmitted: (text) {
        if (!canAnswer) return;
        submittedAnswer = text;
        KLIClient.sendMessage(KLISocketMessage(
          senderID: KLIClient.clientID!,
          type: KLIMessageType.accelAnswer,
          message: '$text|${(30 - currentTimeSec).toStringAsPrecision(3)}',
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
