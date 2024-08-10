import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

class FinishScreen extends StatefulWidget {
  final int playerPos;

  const FinishScreen({super.key, required this.playerPos});

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  double timeLimitSec = 1, currentTimeSec = 0;
  bool canSelectQuestion = true,
      canStart = false,
      canShowQuestion = false,
      hoverStar = false,
      chosenStar = false,
      started = false,
      timeEnded = false,
      canEnd = false;
  late FinishQuestion currentQuestion;
  Timer? timer;
  int questionNum = 0, pointValue = 0;

  @override
  void initState() {
    super.initState();
    KLIServer.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.stealAnswer) {
        final pos = m.senderID.index - 1;
        KLIServer.sendToAllClients(KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.disableSteal,
        ));
        timer?.cancel();

        if (mounted) {
          final res = await dialogWithActions<bool>(
            context,
            title: 'Stealing',
            content: '${Networking.getClientDisplayID(m.senderID)} has decided to steal the right to answer.',
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
            MatchState().modifyScore(pos, currentQuestion.point);
            MatchState().modifyScore(widget.playerPos, -currentQuestion.point);
          } else {
            MatchState().modifyScore(pos, -(currentQuestion.point ~/ 2));
          }

          setState(() {});
          KLIServer.sendToAllClients(KLISocketMessage(
            senderID: ConnectionID.host,
            message: jsonEncode(MatchState().scores),
            type: KLIMessageType.scores,
          ));
        }
      }
    });
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
                child: Column(
                  children: [
                    questionContainer(),
                    manageButtons(),
                    questionPointButtons(),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Column(
                    children: [
                      questionInfo(),
                      ...sideButtons(),
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
          border: Border.all(color: Colors.white),
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            players(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: BorderDirectional(top: BorderSide(color: Colors.white)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 128),
                alignment: Alignment.center,
                child: canShowQuestion
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentQuestion.question,
                            textAlign: TextAlign.center,
                            // textWidthBasis: TextWidthBasis.longestLine,
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

  Widget manageButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        children: [
          Expanded(
            child: KLIButton(
              'Correct',
              enableCondition: timeEnded && !canSelectQuestion,
              disabledLabel: "Can't answer now",
              onPressed: () {
                MatchState().modifyScore(widget.playerPos, pointValue);
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  message: jsonEncode(MatchState().scores),
                  type: KLIMessageType.scores,
                ));
                canSelectQuestion = questionNum < 3;
                canEnd = questionNum == 3;
                timeEnded = false;
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KLIButton(
              'Incorrect',
              enableCondition: timeEnded && !canSelectQuestion,
              disabledLabel: "Can't answer now",
              onPressed: () {
                canSelectQuestion = questionNum < 3;
                canEnd = questionNum == 3;
                timeEnded = false;
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KLIButton(
              'Explanation',
              enableCondition: canShowQuestion,
              onPressed: () {
                showPopupMessage(
                  context,
                  title: 'Explanation',
                  content: currentQuestion.explanation,
                  horizontalPadding: 400,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget questionPointButtons() {
    return Row(
      children: [
        for (final i in range(1, 3))
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: i == 3 ? 0 : 8,
                left: i == 1 ? 0 : 8,
              ),
              child: KLIButton(
                (i * 10).toString(),
                enableCondition: canSelectQuestion,
                onPressed: () {
                  nextQuestion(i * 10);
                  canSelectQuestion = false;
                  canStart = true;
                  setState(() {});
                },
              ),
            ),
          ),
      ],
    );
  }

  void nextQuestion(int point) {
    int i = 0;
    while ((MatchState().questionList![i] as FinishQuestion).point != point) {
      i = Random().nextInt(MatchState().questionList!.length);
    }
    currentQuestion = MatchState().questionList!.removeAt(i) as FinishQuestion;

    questionNum++;
    canShowQuestion = true;
    timeLimitSec = currentTimeSec = 5 + point / 10 * 5;
    pointValue = currentQuestion.point;
    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.finishQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
  }

  Widget questionInfo() {
    return Expanded(
      child: Column(
        children: [
          AnimatedCircularProgressBar(
            currentTimeSec: currentTimeSec,
            totalTimeSec: timeLimitSec,
            strokeWidth: 20,
            valueColor: const Color(0xFF00A906),
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 64),
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
              canShowQuestion ? pointValue.toString() : '',
              style: const TextStyle(fontSize: fontSizeMedium),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 64),
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
              canShowQuestion ? '$questionNum' : '',
              style: const TextStyle(fontSize: fontSizeMedium),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> sideButtons() {
    return [
      GestureDetector(
        onTap: () {
          chosenStar = !chosenStar;
          chosenStar ? pointValue *= 2 : pointValue ~/= 2;
          setState(() {});
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            setState(() => hoverStar = true);
          },
          onExit: (event) {
            setState(() => hoverStar = false);
          },
          child: Image.asset(
            chosenStar ? 'assets/star_lit.png' : 'assets/star_dim.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: KLIButton(
          'Start',
          enableCondition: canStart,
          disabledLabel: 'Currently ongoing',
          onPressed: () {
            canStart = false;
            started = true;
            timer = Timer.periodic(1.seconds, (timer) {
              if (currentTimeSec <= 0) {
                timer.cancel();
                timeEnded = true;
                canStart = false;
                setState(() {});
              } else {
                currentTimeSec--;
                setState(() {});
              }
            });
          },
        ),
      ),
      KLIButton(
        'End',
        enableCondition: canEnd,
        disabledLabel: 'Currently ongoing',
        onPressed: () {
          KLIServer.sendToAllClients(KLISocketMessage(
            senderID: ConnectionID.host,
            type: KLIMessageType.endSection,
          ));

          Navigator.of(context).pop();
        },
      ),
    ];
  }
}
