import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'overview.dart';

class MCFinishScreen extends StatefulWidget {
  final int playerPos;

  const MCFinishScreen({super.key, required this.playerPos});

  @override
  State<MCFinishScreen> createState() => _MCFinishScreenState();
}

class _MCFinishScreenState extends State<MCFinishScreen> {
  double timeLimitSec = 1, currentTimeSec = 0;
  bool canShowQuestion = false;
  late FinishQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  int questionNum = 0, stealer = -1;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.finishQuestion) {
        currentQuestion = FinishQuestion.fromJson(jsonDecode(m.message));
        questionNum++;
        canShowQuestion = true;
        timeLimitSec = currentTimeSec = currentQuestion.point / 10 * 5 + 5;
        stealer = -1;
      }

      if (m.type == KLIMessageType.continueTimer) {
        timer = Timer.periodic(1.seconds, (timer) {
          if (currentTimeSec <= 0) {
            timer.cancel();
            setState(() {});
            return;
          }
          currentTimeSec -= 1;
          setState(() {});
        });
      }

      if (m.type == KLIMessageType.disableSteal) {
        stealer = int.parse(m.message);
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
          MaterialPageRoute(builder: (_) => const MCOverviewScreen()),
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
                child: Column(
                  children: [
                    AnimatedCircularProgressBar(
                      currentTimeSec: currentTimeSec,
                      totalTimeSec: timeLimitSec,
                      strokeWidth: 20,
                      valueColor: const Color(0xFF00A906),
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
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
                  color: i == widget.playerPos
                      ? Theme.of(context).colorScheme.primaryContainer
                      : i == stealer
                          ? Colors.yellow.shade800.withOpacity(0.7)
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
                  child: canShowQuestion
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentQuestion.question,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: fontSizeLarge),
                            ),
                            Text(
                              currentQuestion.answer,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: fontSizeMedium,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
