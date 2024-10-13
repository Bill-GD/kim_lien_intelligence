import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

class StartScreen extends StatefulWidget {
  final double timeLimitSec = 60;
  final buttonPadding = const EdgeInsets.only(top: 50, bottom: 60);
  final int playerPos;

  const StartScreen({super.key, required this.playerPos});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  double currentTimeSec = 60;
  bool started = false, timeEnded = false;
  late StartQuestion currentQuestion;
  Timer? timer;
  int questionNum = 0;

  @override
  void initState() {
    super.initState();
    audioHandler.play(assetHandler.startPlayerStart);
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
        extendBodyBehindAppBar: true,
        appBar: managerAppBar(
          context,
          'Start',
          leading: BackButton(
            onPressed: isTesting
                ? () {
                    KLIServer.sendToAllClients(KLISocketMessage(
                      senderID: ConnectionID.host,
                      type: KLIMessageType.endSection,
                    ));
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 96),
          child: Row(
            children: [
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    questionContainer(),
                    answerButtons(),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Column(
                    children: [
                      Expanded(
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
                  color: i == widget.playerPos ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
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
                ],
              ),
            ),
          ],
        ),
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
                audioHandler.play(assetHandler.startCorrect);
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.correctStartAnswer,
                  message: MatchState().scores[widget.playerPos].toString(),
                ));
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
                audioHandler.play(assetHandler.startIncorrect);
                nextQuestion();
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.startIncorrect,
                ));
                setState(() {});
              },
            ),
          ),
        ],
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

      audioHandler.stop(true);
      return;
    }
    questionNum++;
    currentQuestion = MatchState().questionList!.removeLast() as StartQuestion;
    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.startQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
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
                audioHandler.play(assetHandler.startEndPlayer);
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
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.startShowQuestions,
                ));
                audioHandler.play(assetHandler.startShowQuestions);

                Future.delayed(4.7.seconds, () {
                  KLIServer.sendToNonPlayer(KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.playAudio,
                    message: assetHandler.startBackground,
                  ));
                  audioHandler.play(assetHandler.startBackground, true);

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
                });
              },
            ),
          );
  }
}
