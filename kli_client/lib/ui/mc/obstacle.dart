import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import 'overview.dart';
import '../../global.dart';
import '../../match_data.dart';

class MCObstacleScreen extends StatefulWidget {
  final double timeLimitSec = 15;

  const MCObstacleScreen({super.key});

  @override
  State<MCObstacleScreen> createState() => _MCObstacleScreenState();
}

class _MCObstacleScreenState extends State<MCObstacleScreen> {
  double currentTimeSec = 15;
  bool canShowQuestion = false;
  late ObstacleQuestion currentQuestion;
  Timer? timer;
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.endSection) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const MCOverviewScreen()),
        );
      }

      if (m.type == KLIMessageType.eliminated) {
        currentTimeSec = 0;
        timer?.cancel();
      }

      if (m.type == KLIMessageType.scores) {
        int i = 0;
        for (int s in jsonDecode(m.message) as List) {
          MatchData().players[i].point = s;
          i++;
        }
      }

      if (m.type == KLIMessageType.obstacleQuestion) {
        // if (canAnswer) return;
        currentQuestion = ObstacleQuestion.fromJson(jsonDecode(m.message));
        canShowQuestion = true;
        setState(() {});
        createTimer();
      }

      if (m.type == KLIMessageType.hideQuestion) {
        canShowQuestion = false;
        currentTimeSec = 15;
      }

      setState(() {});

      if (m.type == KLIMessageType.stopTimer) {
        timer?.cancel();
      }

      if (m.type == KLIMessageType.continueTimer) {
        createTimer();
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
          automaticallyImplyLeading: isTesting,
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
          child: Row(
            children: [
              Flexible(
                flex: 9,
                child: questionContainer(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  constraints: const BoxConstraints(maxWidth: 200),
                  alignment: Alignment.topCenter,
                  child: AnimatedCircularProgressBar(
                    currentTimeSec: currentTimeSec,
                    totalTimeSec: widget.timeLimitSec,
                    strokeWidth: 20,
                    valueColor: const Color(0xFF00A906),
                    backgroundColor: Colors.red,
                  ),
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
      ),
    );
  }
}
