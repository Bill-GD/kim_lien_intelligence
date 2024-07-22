import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';
import 'obstacle_image.dart';

final _key = GlobalKey<ScaffoldState>();

class ObstacleQuestionScreen extends StatefulWidget {
  final double timeLimitSec;

  const ObstacleQuestionScreen({super.key, this.timeLimitSec = 15});

  @override
  State<ObstacleQuestionScreen> createState() => _ObstacleQuestionScreenState();
}

class _ObstacleQuestionScreenState extends State<ObstacleQuestionScreen> {
  int questionIndex = -1;
  late double currentTimeSec;
  bool timeEnded = false,
      canShowAnswers = false,
      canAnnounceAnswer = false,
      canShowImage = false,
      canSelectQuestion = true,
      keywordAnswered = false;
  Timer? timer;

  @override
  void initState() {
    debugPrint('${MatchState().imagePartOrder}');
    currentTimeSec = widget.timeLimitSec;
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
        key: _key,
        appBar: managerAppBar(
          context,
          'Obstacle: ${MatchState().obstacleMatch!.keyword}',
          implyLeading: kDebugMode,
          actions: [Container()],
        ),
        backgroundColor: Colors.transparent,
        // TODO extract this to external stateful widget
        endDrawer: Drawer(
          width: 800,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('a'),
            ),
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
              Flexible(
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
    return Expanded(
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
                child: ObstacleRow(
                  index: i,
                  answer: MatchState().obstacleMatch!.hintQuestions[i]!.answer,
                  revealed: MatchState().revealedObstacleRows[i],
                  answered: MatchState().answeredObstacleRows[i],
                  onTap: canSelectQuestion
                      ? () {
                          questionIndex = i;
                          timeEnded = canAnnounceAnswer = false;
                          currentTimeSec = widget.timeLimitSec;
                          setState(() {});
                        }
                      : null,
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
            // enableCondition: canShowImage,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ObstacleImageScreen(),
                ),
              );
              canShowImage = false;
              canSelectQuestion = true;
              setState(() {});
            },
          ),
          KLIButton(
            'Get Middle Row',
            enableCondition:
                MatchState().allRowsAnswered && !MatchState().answeredObstacleRows[4] && questionIndex != 4,
            onPressed: () {
              questionIndex = 4;
              timeEnded = false;
              currentTimeSec = widget.timeLimitSec;
              canAnnounceAnswer = false;
              setState(() {});
            },
          ),
          KLIButton(
            'Show Answers',
            enableCondition: canShowAnswers,
            onPressed: () {
              canAnnounceAnswer = true;
              setState(() {});
              _key.currentState?.openEndDrawer();
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              KLIButton(
                'Correct',
                enableCondition: canAnnounceAnswer && questionIndex >= 0,
                onPressed: () {
                  MatchState().revealedImageParts[MatchState().imagePartOrder.indexOf(questionIndex)] = true;
                  MatchState().revealedObstacleRows[questionIndex] = true;
                  MatchState().answeredObstacleRows[questionIndex] = true;
                  obstacleWait();
                  questionIndex = -1;
                  canShowAnswers = false;
                  canShowImage = true;
                  setState(() {});
                },
              ),
              KLIButton(
                'Wrong',
                enableCondition: canAnnounceAnswer && questionIndex >= 0,
                onPressed: () {
                  MatchState().answeredObstacleRows[questionIndex] = true;
                  obstacleWait();
                  questionIndex = -1;
                  canShowAnswers = false;
                  canShowImage = true;
                  canSelectQuestion = true;
                  setState(() {});
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              KLIButton(
                'Start',
                enableCondition: questionIndex >= 0 && !timeEnded && !(timer?.isActive == true),
                onPressed: () {
                  canSelectQuestion = false;
                  timer = Timer.periodic(1.seconds, (timer) {
                    if (currentTimeSec <= 0) {
                      timer.cancel();
                      timeEnded = true;
                      canShowAnswers = true;
                      setState(() {});
                      return;
                    }
                    currentTimeSec--;
                    setState(() {});
                  });
                  setState(() {});
                },
              ),
              KLIButton(
                'End',
                enableCondition: keywordAnswered || MatchState().allQuestionsAnswered,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void obstacleWait() {
    if (questionIndex == 4) {
      currentTimeSec = 15;
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
    }
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
                    MatchState().obstacleMatch!.hintQuestions[questionIndex]!.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: fontSizeLarge),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    MatchState().obstacleMatch!.hintQuestions[questionIndex]!.answer,
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
        padding: const EdgeInsets.only(top: 32, bottom: 64),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              qDisplay,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
            const Divider(color: Colors.white),
            const SizedBox(),
            AnimatedCircularProgressBar(
              currentTimeSec: currentTimeSec,
              totalTimeSec: widget.timeLimitSec,
              textSize: fontSizeLarge,
              valueColor: const Color(0xFF00A906),
              backgroundColor: Colors.red,
              strokeWidth: 40,
              dimension: 200,
            ),
          ],
        ),
      ),
    );
  }
}
