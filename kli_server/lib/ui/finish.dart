import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:video_player/video_player.dart';

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
  bool canSelectPoint = true,
      canSelectQuestion = false,
      canPlayVideo = true,
      canStart = false,
      canShowQuestion = false,
      hoverStar = false,
      chosenStar = false,
      canUseStar = true,
      started = false,
      timeEnded = false,
      canEnd = false;
  late FinishQuestion currentQuestion;
  Timer? timer;
  int chosenQuestionCount = 0, questionNum = 0, pointValue = 0, stealer = -1;
  late final StreamSubscription<KLISocketMessage> sub;
  final List<int> chosenQuestions = [0, 0, 0];
  VideoPlayerController? vidController;
  bool get isVidQuestion => currentQuestion.mediaPath.isNotEmpty;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    audioHandler.play(assetHandler.finishPlayerStart);
    Future.delayed(1.seconds, () => audioHandler.play(assetHandler.finishShowPacks));

    sub = KLIServer.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.stealAnswer) {
        audioHandler.play(assetHandler.finishSteal);
        stealer = m.senderID.index - 1;

        KLIServer.sendToAllClients(KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.disableSteal,
          message: '$stealer',
        ));
        timer?.cancel();
        setState(() {});

        if (mounted) {
          final res = await dialogWithActions<bool>(
            context,
            title: 'Stealing',
            content: '${Networking.getClientDisplayID(m.senderID)} has decided to steal the right to answer.',
            time: 150.ms,
            actions: [
              KLIButton(
                'Correct',
                onPressed: () {
                  audioHandler.play(assetHandler.finishCorrect);
                  KLIServer.sendToNonPlayer(KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.playAudio,
                    message: assetHandler.finishCorrect,
                  ));
                  Navigator.of(context).pop(true);
                },
              ),
              KLIButton(
                'Wrong',
                onPressed: () {
                  audioHandler.play(assetHandler.finishIncorrect);
                  KLIServer.sendToNonPlayer(KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.playAudio,
                    message: assetHandler.finishIncorrect,
                  ));
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );

          if (res == true) {
            MatchState().modifyScore(stealer, currentQuestion.point);
            if (!chosenStar) {
              MatchState().modifyScore(widget.playerPos, -currentQuestion.point);
            }
          } else {
            MatchState().modifyScore(stealer, -(currentQuestion.point ~/ 2));
          }

          setState(() {});
          KLIServer.sendToAllClients(KLISocketMessage(
            senderID: ConnectionID.host,
            type: KLIMessageType.scores,
            message: jsonEncode(MatchState().scores),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    sub.cancel();
    vidController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Finish',
          leading: isTesting
              ? BackButton(
                  onPressed: () {
                    KLIServer.sendToAllClients(KLISocketMessage(
                      senderID: ConnectionID.host,
                      type: KLIMessageType.endSection,
                    ));
                    Navigator.of(context).pop();
                  },
                )
              : null,
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(left: 64, right: 64, bottom: 64, top: 96),
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
                      sideWidget(),
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
                      : i == stealer
                          ? Colors.yellow.shade800.withOpacity(0.7)
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
          children: <Widget>[
            players(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: BorderDirectional(top: BorderSide(color: Colors.white)),
                ),
                alignment: Alignment.center,
                child: canShowQuestion
                    ? Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            child: Text(
                              'Câu hỏi $questionNum',
                              style: const TextStyle(fontSize: fontSizeLarge),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              child: Text(
                                '$pointValue điểm',
                                style: const TextStyle(fontSize: fontSizeLarge),
                              ),
                            ),
                          ),
                          !isVidQuestion
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 128, right: 128),
                                  child: Column(
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
                                        style: const TextStyle(
                                          fontSize: fontSizeMedium,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                          if (vidController != null && isVidQuestion)
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 24),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: MediaQuery.of(context).size.width / 2.5,
                                    child: Text(
                                      currentQuestion.answer,
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: fontSizeMSmall,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 48),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [VideoPlayer(vidController!)],
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 100),
                                    child: KLIButton(
                                      'Play',
                                      enableCondition: canShowQuestion && canPlayVideo,
                                      onPressed: () {
                                        vidController!.play();
                                        KLIServer.sendToNonPlayer(KLISocketMessage(
                                          senderID: ConnectionID.host,
                                          type: KLIMessageType.playVideo,
                                        ));
                                        setState(() => canPlayVideo = false);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : const SizedBox(),
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
                audioHandler.play(assetHandler.finishCorrect);
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.finishCorrect,
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
                if (chosenStar) {
                  MatchState().modifyScore(widget.playerPos, -currentQuestion.point);
                  KLIServer.sendToAllClients(KLISocketMessage(
                    senderID: ConnectionID.host,
                    message: jsonEncode(MatchState().scores),
                    type: KLIMessageType.scores,
                  ));
                }
                audioHandler.play(assetHandler.finishIncorrect);
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.finishIncorrect,
                ));

                audioHandler.play(assetHandler.finishStealWait, true);
                KLIServer.sendToAllExcept(
                  [ConnectionID.values[widget.playerPos + 1]],
                  KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.enableSteal,
                  ),
                );
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
                enableCondition: canSelectPoint,
                disabledLabel: 'Already chosen',
                onPressed: () {
                  chosenQuestions[chosenQuestionCount++] = i * 10;
                  canSelectQuestion = chosenQuestionCount == 3;
                  canSelectPoint = !canSelectQuestion;
                  if (!canSelectPoint) {
                    audioHandler.play(assetHandler.finishChosePack);
                    KLIServer.sendToNonPlayer(KLISocketMessage(
                      senderID: ConnectionID.host,
                      type: KLIMessageType.playAudio,
                      message: assetHandler.finishChosePack,
                    ));
                  }
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
    started = false;
    stealer = -1;
    timeLimitSec = currentTimeSec = 5 + point / 10 * 5;
    if (!canUseStar && chosenStar) chosenStar = false;
    pointValue = chosenStar ? currentQuestion.point * 2 : point;

    if (isVidQuestion) {
      vidController = VideoPlayerController.file(
        File(StorageHandler.getFullPath(currentQuestion.mediaPath)),
      )..initialize().then((_) => setState(() => canPlayVideo = true));
    } else {
      vidController?.dispose();
      vidController = null;
    }

    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.finishQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
  }

  Widget sideWidget() {
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
          const Expanded(child: SizedBox()),
          for (final i in range(0, 2))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: KLIButton(
                'Q${i + 1}: ${chosenQuestions[i]}',
                enableCondition: canSelectQuestion && questionNum == i,
                disabledLabel: 'Not chosen yet',
                onPressed: () {
                  nextQuestion(chosenQuestions[i]);
                  canSelectQuestion = false;
                  canStart = true;
                  setState(() {});
                },
              ),
            ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  List<Widget> sideButtons() {
    return [
      // star
      GestureDetector(
        onTap: canUseStar && canSelectQuestion && !started
            ? () {
                if (started) return;
                chosenStar = !chosenStar;
                if (chosenStar) {
                  audioHandler.play(assetHandler.finishChoseStar);
                  KLIServer.sendToNonPlayer(KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.playAudio,
                    message: assetHandler.finishChoseStar,
                  ));
                }
                // chosenStar ? pointValue *= 2 : pointValue ~/= 2;
                setState(() {});
              }
            : null,
        child: MouseRegion(
          cursor: canUseStar && canSelectQuestion && !started //
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
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
      const SizedBox(height: 32),
      KLIButton(
        'Start',
        enableCondition: canStart,
        disabledLabel: 'Currently ongoing',
        onPressed: () {
          canStart = false;
          started = true;
          if (chosenStar && canUseStar) canUseStar = false;
          setState(() {});
          timer = Timer.periodic(1.seconds, (timer) {
            if (currentTimeSec <= 0) {
              timer.cancel();
              timeEnded = true;
              started = false;
              setState(() {});
            } else {
              currentTimeSec--;
              setState(() {});
            }
          });
          audioHandler.play(assetHandler.finishBackground[currentQuestion.point]!, true);

          KLIServer.sendToAllClients(KLISocketMessage(
            senderID: ConnectionID.host,
            type: KLIMessageType.continueTimer,
          ));
        },
      ),
      const SizedBox(height: 32),
      KLIButton(
        'End',
        enableCondition: canEnd,
        disabledLabel: 'Currently ongoing',
        onPressed: () {
          audioHandler.play(assetHandler.finishEndPlayer);
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
