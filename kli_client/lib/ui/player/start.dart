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
  bool started = false;
  late StartQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.startQuestion) {
        if (!started) {
          timer = Timer.periodic(1.seconds, (timer) {
            if (currentTimeSec <= 0) {
              timer.cancel();
              started = false;
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
                started
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
                  child: started
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          child: Text(
                            StartQuestion.mapTypeDisplay(currentQuestion.subject),
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
                    started ? currentQuestion.question : '',
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
}
