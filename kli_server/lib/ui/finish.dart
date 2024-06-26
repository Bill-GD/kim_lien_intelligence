import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import '../global.dart';

import '../data_manager/match_state.dart';

class FinishScreen extends StatefulWidget {
  final DecorationImage background;
  final List<FinishQuestion> questions;
  final double timeLimitSec = 60;
  final buttonPadding = const EdgeInsets.only(top: 90, bottom: 70);
  final int playerPos;

  const FinishScreen({
    super.key,
    required this.background,
    required this.playerPos,
    required this.questions,
  });

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  double currentTimeSec = 60;
  bool started = false, timeEnded = false;
  late FinishQuestion currentQuestion;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    currentQuestion = widget.questions.last;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: widget.background,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: managerAppBar(context, 'Finish', implyLeading: kDebugMode),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
          child: Row(children: [
            Expanded(
              flex: 9,
              child: Column(children: [
                questionContainer(),
                answerButtons(),
              ]),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Column(children: [
                  questionInfo(),
                  startEndButton(),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget players() {
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
                  '${MatchState().players[i].name} (${MatchState().scores[i]})',
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
          border: Border.all(color: Theme.of(context).colorScheme.onBackground),
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          players(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  top: BorderSide(width: 1, color: Theme.of(context).colorScheme.onBackground),
                ),
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
                          textWidthBasis: TextWidthBasis.longestLine,
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
        ]),
      ),
    );
  }

  Widget answerButtons() {
    return Padding(
      padding: widget.buttonPadding,
      child: Row(
        children: [
          Expanded(
            child: KLIButton(
              'Correct',
              enableCondition: !timeEnded && started,
              disabledLabel: "Can't answer now",
              onPressed: () {
                MatchState().modifyScore(widget.playerPos, 10);
                nextQuestion();
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KLIButton(
              'Incorrect',
              enableCondition: !timeEnded && started,
              disabledLabel: "Can't answer now",
              onPressed: () {
                nextQuestion();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void nextQuestion() {
    if (widget.questions.isEmpty) {
      timer?.cancel();
      timeEnded = true;
      return;
    }
    currentQuestion = widget.questions.removeLast();
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
          const SizedBox(height: 128),
          Container(
            width: 128,
            height: 128,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.background,
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
            ),
            child: started
                ? Text(
                    'Point: ${currentQuestion.point}',
                    style: const TextStyle(fontSize: fontSizeMedium),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
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
                setState(() {
                  started = true;
                });
              },
            ),
          );
  }
}
