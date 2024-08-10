import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../connect_screen/overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class PlayerFinishScreen extends StatefulWidget {
  final int playerPos;

  const PlayerFinishScreen({super.key, required this.playerPos});

  @override
  State<PlayerFinishScreen> createState() => _PlayerFinishScreenState();
}

class _PlayerFinishScreenState extends State<PlayerFinishScreen> {
  double timeLimitSec = 1, currentTimeSec = 0;
  bool canShowQuestion = false, canSteal = false, timeEnded = false;
  late FinishQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.finishQuestion) {
        currentQuestion = FinishQuestion.fromJson(jsonDecode(m.message));
        questionNum++;
        canShowQuestion = true;
        timeLimitSec = currentTimeSec = currentQuestion.point / 10 * 5 + 5;
        setState(() {});
      }

      if (m.type == KLIMessageType.continueTimer) {
        timer = Timer.periodic(1.seconds, (timer) {
          if (currentTimeSec <= 0) {
            timer.cancel();
            timeEnded = canSteal = true;
            setState(() {});
            return;
          }
          currentTimeSec -= 1;
          setState(() {});
        });
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.disableSteal) {
        canSteal = false;
        setState(() {});
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
          automaticallyImplyLeading: kDebugMode,
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

  Widget questionInfo() {
    return Row(
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: widget.playerPos == 0 ? const Radius.circular(10) : Radius.zero,
                topRight: widget.playerPos == 3 ? const Radius.circular(10) : Radius.zero,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: i == widget.playerPos
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
        // Expanded(
        //   child: ClipRRect(
        //     borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
        //     child: Container(
        //       decoration: BoxDecoration(
        //         color: Colors.transparent,
        //         border: BorderDirectional(
        //           end: BorderSide(color: Theme.of(context).colorScheme.onBackground),
        //         ),
        //       ),
        //       padding: const EdgeInsets.symmetric(vertical: 16),
        //       alignment: Alignment.center,
        //       child: Text(
        //         started ? 'Câu hỏi $questionNum' : '',
        //         style: const TextStyle(fontSize: fontSizeMedium),
        //       ),
        //     ),
        //   ),
        // ),
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
          child: Stack(
            children: [
              Positioned(
                right: 0,
                child: canShowQuestion
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Text(
                          '${currentQuestion.point} điểm',
                          style: const TextStyle(fontSize: fontSizeLarge),
                        ),
                      )
                    : const SizedBox(),
              ),
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
      ]),
    );
  }

  Widget playerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedCircularProgressBar(
          currentTimeSec: currentTimeSec,
          totalTimeSec: timeLimitSec,
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
        const Expanded(child: SizedBox()),
        KLIButton(
          'Steal',
          enableCondition: canSteal,
          onPressed: () {
            KLIClient.sendMessage(KLISocketMessage(
              senderID: KLIClient.clientID!,
              type: KLIMessageType.stealAnswer,
            ));
          },
        ),
      ],
    );
  }
}
