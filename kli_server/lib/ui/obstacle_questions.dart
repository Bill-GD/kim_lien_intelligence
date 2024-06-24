import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

final _key = GlobalKey<ScaffoldState>();

class ObstacleQuestionScreen extends StatefulWidget {
  final DecorationImage background;
  final double timeLimitSec;
  const ObstacleQuestionScreen({super.key, required this.background, this.timeLimitSec = 15});

  @override
  State<ObstacleQuestionScreen> createState() => _ObstacleQuestionScreenState();
}

class _ObstacleQuestionScreenState extends State<ObstacleQuestionScreen> {
  int questionIndex = -1;
  double currentTimeSec = 15;
  bool timeEnded = false;
  Timer? timer;

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
        key: _key,
        appBar: managerAppBar(context, 'Obstacle', implyLeading: kDebugMode),
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          width: 800,
          child: Center(
            child: Text('a'),
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 48),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    obstacleRows(),
                    manageButtons(),
                  ],
                ),
              ),
              const SizedBox(height: 72),
              Expanded(
                child: Row(
                  children: [
                    questionContainer(),
                    questionInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget obstacleRows() {
    return Flexible(
      flex: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ObstacleRow(
                      index: i,
                      answer: MatchState.i.obstacleMatch!.hintQuestions[i]!.answer,
                      revealed: MatchState.i.revealedObstacleRows[i],
                    ),
                    const SizedBox(width: 32),
                    KLIIconButton(
                      const Icon(Icons.arrow_back),
                      enableCondition: !MatchState.i.answeredObstacleRows[i],
                      onPressed: () {
                        questionIndex = i;
                        timeEnded = false;
                        currentTimeSec = widget.timeLimitSec;
                        setState(() {});
                      },
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget manageButtons() {
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          KLIButton(
            'Show Image',
            enableCondition: timeEnded,
            onPressed: () {},
          ),
          KLIButton(
            'Get Middle Row',
            enableCondition: MatchState.i.answeredObstacleRows.take(4).every((e) => e) &&
                !MatchState.i.answeredObstacleRows[4],
            onPressed: () {
              questionIndex = 4;
              timeEnded = false;
              currentTimeSec = widget.timeLimitSec;
              setState(() {});
            },
          ),
          KLIButton(
            'Show Answers',
            enableCondition: timeEnded,
            onPressed: () {
              _key.currentState?.openEndDrawer();
            },
          ),
          const SizedBox(height: 32),
          KLIButton(
            'Start',
            enableCondition: questionIndex >= 0 && !timeEnded && !(timer?.isActive == true),
            onPressed: () {
              timer = Timer.periodic(1.seconds, (timer) {
                if (currentTimeSec <= 0) {
                  timer.cancel();
                  timeEnded = true;
                  setState(() {});
                  return;
                }
                currentTimeSec--;
                setState(() {});
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              KLIButton(
                'Correct',
                enableCondition: timeEnded,
                onPressed: () {
                  MatchState.i.revealedObstacleRows[questionIndex] = true;
                  MatchState.i.answeredObstacleRows[questionIndex] = true;
                  questionIndex = -1;
                  setState(() {});
                },
              ),
              KLIButton(
                'Wrong',
                enableCondition: timeEnded,
                onPressed: () {
                  MatchState.i.revealedObstacleRows[questionIndex] = false;
                  MatchState.i.answeredObstacleRows[questionIndex] = true;
                  questionIndex = -1;
                  setState(() {});
                },
              ),
            ],
          ),
          KLIButton(
            'End',
            enableCondition: MatchState.i.answeredObstacleRows.every((e) => e),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget questionContainer() {
    return Expanded(
      flex: 4,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 128),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: questionIndex >= 0
              ? [
                  Text(
                    MatchState.i.obstacleMatch!.hintQuestions[questionIndex]!.question,
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.longestLine,
                    style: const TextStyle(fontSize: fontSizeLarge),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    MatchState.i.obstacleMatch!.hintQuestions[questionIndex]!.answer,
                    softWrap: true,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: fontSizeMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget questionInfo() {
    final qDisplay = questionIndex < 0
        ? ''
        : questionIndex == 4
            ? 'Middle Question'
            : 'Question ${questionIndex + 1}';

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(),
            Text(
              qDisplay,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 68, horizontal: 77),
              decoration: const BoxDecoration(
                border: BorderDirectional(top: BorderSide(color: Colors.white)),
              ),
              child: AnimatedCircularProgressBar(
                currentTimeSec: currentTimeSec,
                totalTimeSec: widget.timeLimitSec,
                textSize: fontSizeLarge,
                valueColor: const Color(0xFF00A906),
                backgroundColor: Colors.red,
                strokeWidth: 40,
                dimension: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObstacleRow extends StatelessWidget {
  final int index;
  final String answer;
  final bool revealed;
  const _ObstacleRow({super.key, required this.index, required this.answer, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final borderColor = revealed
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : MatchState.i.answeredObstacleRows[index]
            ? Theme.of(context).colorScheme.error
            : Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in answer.toUpperCase().split('').where((e) => e != ' '))
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
              ),
              color: Theme.of(context).colorScheme.background,
            ),
            child: Text(
              c,
              style: TextStyle(
                color: revealed ? Colors.white : Colors.transparent,
                fontSize: fontSizeMedium,
              ),
            ),
          )
      ],
    );
  }
}
