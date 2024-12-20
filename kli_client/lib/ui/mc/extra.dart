import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'overview.dart';

class MCExtraScreen extends StatefulWidget {
  final timeLimitSec = 15.0;
  final List<int> players;
  const MCExtraScreen({super.key, required this.players});

  @override
  State<MCExtraScreen> createState() => _MCExtraScreenState();
}

class _MCExtraScreenState extends State<MCExtraScreen> {
  double currentTimeSec = 0;
  bool canShowQuestion = false;
  late ExtraQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.extraQuestion) {
        currentQuestion = ExtraQuestion.fromJson(jsonDecode(m.message));
        canShowQuestion = true;
        questionNum++;
        currentTimeSec = widget.timeLimitSec;
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

      if (m.type == KLIMessageType.stopTimer) {
        timer?.cancel();
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
                      totalTimeSec: widget.timeLimitSec,
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
                  color: i == MatchData().playerPos ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
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
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    color: Colors.white.withOpacity(widget.players.contains(i) ? 1 : 0.35),
                  ),
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
