import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';
import 'obstacle_image.dart';

final _key = GlobalKey<ScaffoldState>();

class ObstacleQuestionScreen extends StatefulWidget {
  final double timeLimitSec = 15;
  const ObstacleQuestionScreen({super.key});

  @override
  State<ObstacleQuestionScreen> createState() => _ObstacleQuestionScreenState();
}

class _ObstacleQuestionScreenState extends State<ObstacleQuestionScreen> {
  int questionIndex = -1;
  double currentTimeSec = 15;
  bool canStart = false,
      canShowAnswers = false,
      canAnnounceAnswer = false,
      canShowImage = false,
      canSelectQuestion = true,
      canEnd = false;
  Timer? timer;
  final List<bool?> answerResults = List.filled(4, null);
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    logHandler.info('Image reveal order: ${MatchState().imagePartOrder}');
    sub = KLIServer.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.obstacleRowAnswer) {
        final pos = m.senderID.index - 1;
        MatchState().rowAnswers[pos] = MatchState().eliminatedPlayers[pos] ? '' : m.message;
      }

      if (m.type == KLIMessageType.guessObstacle) {
        final playerPos = m.senderID.index - 1;
        KLIServer.sendToAllClients(KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.stopTimer,
        ));
        KLIServer.sendToAllClients(KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.disableGuessObstacle,
        ));
        timer?.cancel();

        if (mounted) {
          final res = await dialogWithActions<bool>(
            context,
            title: 'Guess Obstacle',
            content: '${Networking.getClientDisplayID(m.senderID)} has decided to guess the obstacle.',
            time: 150.ms,
            actions: [
              KLIButton(
                'Correct',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              KLIButton(
                'Wrong',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          );

          if (res == true) {
            MatchState().modifyScore(
              playerPos,
              MatchState.obstaclePoints[MatchState().answeredObstacleRows.where((e) => e).length],
            );
            KLIServer.sendToAllClients(KLISocketMessage(
              senderID: ConnectionID.host,
              message: jsonEncode(MatchState().scores),
              type: KLIMessageType.scores,
            ));
            canEnd = true;
            canStart = canSelectQuestion = false;
            KLIServer.sendToAllClients(KLISocketMessage(
              senderID: ConnectionID.host,
              type: KLIMessageType.correctObstacleAnswer,
            ));
            setState(() {});
            return;
          }

          MatchState().eliminateObstaclePlayer(playerPos);
          if (!canSelectQuestion) createTimer();
          KLIServer.sendToAllExcept(
            [m.senderID],
            KLISocketMessage(senderID: ConnectionID.host, type: KLIMessageType.continueTimer),
          );
        }
      }
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
        key: _key,
        appBar: managerAppBar(
          context,
          'Obstacle: ${MatchState().obstacleMatch!.keyword}',
          implyLeading: kDebugMode,
          actions: [Container()],
        ),
        backgroundColor: Colors.transparent,
        endDrawer: AnswerDrawer(
          answerResult: answerResults,
          checkboxOnChanged: (i, v) {
            if (MatchState().eliminatedPlayers[i]) return;

            answerResults[i] = v;
            canAnnounceAnswer = answerResults.every((e) => e != null);
            setState(() {});
          },
          canCheck: canShowAnswers,
          answers: MatchState().rowAnswers.asMap().entries.map((e) => (e.value, -1)),
          scores: MatchState().scores,
          playerNames: Iterable.generate(4, (i) => MatchState().players[i].name),
          actions: [
            KLIButton(
              'Announce Result',
              enableCondition: canAnnounceAnswer && questionIndex >= 0,
              onPressed: () {
                obstacleWait();
                for (int i = 0; i < 4; i++) {
                  if (answerResults[i] == true) MatchState().modifyScore(i, 10);
                }

                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  message: jsonEncode(MatchState().scores),
                  type: KLIMessageType.scores,
                ));

                MatchState().answeredObstacleRows[questionIndex] = true;
                MatchState().revealedImageParts[MatchState().imagePartOrder.indexOf(questionIndex)] =
                    MatchState().revealedObstacleRows[questionIndex] = answerResults.any((e) => e == true);
                questionIndex = -1;
                canShowAnswers = false;
                canShowImage = canSelectQuestion = true;

                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.hideQuestion,
                ));
                setState(() {});
              },
            ),
          ],
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
                          canAnnounceAnswer = false;
                          canStart = true;
                          currentTimeSec = widget.timeLimitSec;
                          MatchState().rowAnswers.fillRange(0, 4, '');
                          answerResults.fillRange(0, 4, null);
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
            enableCondition: MatchState().allRowsAnswered &&
                !MatchState().answeredObstacleRows[4] &&
                questionIndex != 4 &&
                canSelectQuestion,
            onPressed: () {
              answerResults.fillRange(0, 4, null);
              questionIndex = 4;
              canAnnounceAnswer = false;
              canStart = true;
              currentTimeSec = widget.timeLimitSec;
              setState(() {});
            },
          ),
          KLIButton(
            'Show Answers',
            enableCondition: canShowAnswers,
            onPressed: () {
              // canAnnounceAnswer = true;
              for (final i in range(0, 3)) {
                if (MatchState().eliminatedPlayers[i]) {
                  answerResults[i] = false;
                }
              }
              _key.currentState?.openEndDrawer();
              setState(() {});
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              KLIButton(
                'Start',
                // enableCondition: questionIndex >= 0 && !timeEnded && !(timer?.isActive == true),
                enableCondition: canStart,
                onPressed: () {
                  canSelectQuestion = canStart = false;
                  KLIServer.sendToAllClients(
                    KLISocketMessage(
                      senderID: ConnectionID.host,
                      type: KLIMessageType.obstacleQuestion,
                      message: jsonEncode(MatchState().obstacleMatch!.hintQuestions[questionIndex]!.toJson()),
                    ),
                  );

                  createTimer();
                  setState(() {});
                },
              ),
              KLIButton(
                'End',
                enableCondition: canEnd,
                onPressed: () {
                  KLIServer.sendToAllClients(KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.endSection,
                  ));
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
          canEnd = true;
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

  void createTimer() {
    timer = Timer.periodic(1.seconds, (timer) {
      if (currentTimeSec <= 0) {
        timer.cancel();
        canShowAnswers = true;
        setState(() {});
        return;
      }
      currentTimeSec--;
      setState(() {});
    });
  }
}
