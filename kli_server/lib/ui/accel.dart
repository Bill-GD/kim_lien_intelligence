import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

class AccelScreen extends StatefulWidget {
  final double timeLimitSec = 30;
  final buttonPadding = const EdgeInsets.only(top: 90, bottom: 70);

  const AccelScreen({super.key});

  @override
  State<AccelScreen> createState() => _AccelScreenState();
}

class _AccelScreenState extends State<AccelScreen> {
  double currentTimeSec = 30;
  bool started = false, timeEnded = false;
  late AccelQuestion currentQuestion;
  Timer? timer;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
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
        appBar: managerAppBar(context, 'Start', implyLeading: kDebugMode),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
          child: Row(
            children: [
              Expanded(
                flex: 9,
                child: questionContainer(),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Column(
                    children: [
                      questionInfo(),
                      startEndButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget questionContainerTop() {
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
                'Question $questionNum',
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
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
                currentQuestion.question,
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topRight: Radius.circular(10)),
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
                currentQuestion.answer,
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget questionContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            questionContainerTop(),
            // TODO (sequence of) image(s) here
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: BorderDirectional(top: BorderSide(color: Colors.white)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 128),
                alignment: Alignment.center,
                child: started
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentQuestion.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: fontSizeLarge),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentQuestion.answer,
                            softWrap: true,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: fontSizeMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void nextQuestion() {
    if (MatchState().questionList!.isEmpty) {
      timer?.cancel();
      timeEnded = true;

      KLIServer.sendToAllClients(KLISocketMessage(
        senderID: ConnectionID.host,
        type: KLIMessageType.stopTimer,
      ));
      return;
    }
    questionNum++;
    currentQuestion = MatchState().questionList!.removeLast() as AccelQuestion;
    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.startQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
  }

  Widget questionInfo() {
    return Expanded(
      child: Column(
        children: [
          AnimatedCircularProgressBar(
            currentTimeSec: currentTimeSec,
            totalTimeSec: widget.timeLimitSec,
            strokeWidth: 20,
            valueColor: const Color(0xFF00A906),
            backgroundColor: Colors.red,
          ),
          // TODO add buttons here: next question, show answer (like obs)
        ],
      ),
    );
  }

  Widget startEndButton() {
    return started
        ? Padding(
            padding: widget.buttonPadding,
            child: KLIButton(
              'End',
              enableCondition: timeEnded,
              disabledLabel: 'Currently ongoing',
              onPressed: () {
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.endSection,
                ));
                Navigator.of(context).pop();
              },
            ),
          )
        : Padding(
            padding: widget.buttonPadding,
            child: KLIButton(
              'Start',
              enableCondition: !started,
              onPressed: () {
                nextQuestion();
                timer = Timer.periodic(1.seconds, (timer) {
                  if (currentTimeSec <= 0) {
                    timer.cancel();
                    timeEnded = true;
                    setState(() {});
                  } else {
                    currentTimeSec--;
                    setState(() {});
                  }
                });
                started = true;
                setState(() {});
              },
            ),
          );
  }
}
