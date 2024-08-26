import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../connect_screen/overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class PlayerExtraScreen extends StatefulWidget {
  final timeLimitSec = 15.0;
  const PlayerExtraScreen({super.key});

  @override
  State<PlayerExtraScreen> createState() => _PlayerExtraScreenState();
}

class _PlayerExtraScreenState extends State<PlayerExtraScreen> {
  double currentTimeSec = 0;
  bool canShowQuestion = false, canAnswer = false, timeEnded = false;
  late ExtraQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    updateChild = setState;
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.extraQuestion) {
        currentQuestion = ExtraQuestion.fromJson(jsonDecode(m.message));
        canShowQuestion = true;
        questionNum++;
        currentTimeSec = widget.timeLimitSec;
      }

      if (m.type == KLIMessageType.continueTimer) {
        canAnswer = true;
        timer = Timer.periodic(1.seconds, (timer) {
          if (currentTimeSec <= 0) {
            timer.cancel();
            timeEnded = true;
            canAnswer = false;
            setState(() {});
            return;
          }
          currentTimeSec -= 1;
          setState(() {});
        });
      }

      if (m.type == KLIMessageType.stopTimer) {
        timer?.cancel();
        canAnswer = false;
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
          MaterialPageRoute(builder: (_) => const Overview()),
        );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: isTesting,
          backgroundColor: Colors.transparent,
        ),
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

  Widget containerTop() {
    return Row(
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
                topRight: i == 3 ? const Radius.circular(10) : Radius.zero,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: i == MatchData().playerPos
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  border: BorderDirectional(
                    end: BorderSide(
                      color: i > 2 ? Colors.transparent : Theme.of(context).colorScheme.onBackground,
                    ),
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
    return Container(
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
                          'Câu hỏi $questionNum',
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
                  child: Text(
                    canShowQuestion ? currentQuestion.question : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: fontSizeLarge),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        const Expanded(child: SizedBox()),
        KLIButton(
          'Answer',
          enableCondition: canAnswer,
          onPressed: () {
            KLIClient.sendMessage(KLISocketMessage(
              senderID: KLIClient.clientID!,
              type: KLIMessageType.extraSignal,
            ));
            canAnswer = false;
            setState(() {});
          },
        ),
      ],
    );
  }
}
