import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

class ExtraScreen extends StatefulWidget {
  final timeLimitSec = 15.0;
  final List<bool> players;

  const ExtraScreen({super.key, required this.players});

  @override
  State<ExtraScreen> createState() => _ExtraScreenState();
}

class _ExtraScreenState extends State<ExtraScreen> {
  double currentTimeSec = 0;
  bool canNext = true,
      canStart = false,
      canShowQuestion = false,
      canAnnounce = false,
      canEnd = false,
      canStopTimer = false,
      timerStopped = false;
  late ExtraQuestion currentQuestion;
  Timer? timer;
  int questionNum = 0, answeredCount = 0;
  late StreamSubscription<KLISocketMessage> sub;
  late final int playerCount = widget.players.where((e) => e).length;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    audioHandler.stop();

    sub = KLIServer.onMessageReceived.listen((m) async {
      if (m.type == KLIMessageType.extraSignal) {
        // stop timer, show popup
        // return: continue timer if wrong
        final pos = m.senderID.index - 1;

        KLIServer.sendToAllClients(KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.stopTimer,
          message: '$pos',
        ));

        timer?.cancel();
        setState(() {});

        if (mounted) {
          final res = await dialogWithActions<bool>(
            context,
            title: 'Trả lời',
            content: '${Networking.getClientDisplayID(m.senderID)} has decided to answer.',
            time: 150.ms,
            actions: [
              KLIButton(
                'Đúng',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              KLIButton(
                'Sai',
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
          answeredCount++;

          if (res == true) {
            MatchState().extraScores[pos]++;
            canEnd = true;
          } else {
            if (answeredCount == playerCount) {
              if (questionNum == 3) {
                canEnd = true;
                canNext = false;
              } else {
                canNext = true;
              }
            }
            if (currentTimeSec > 0) {
              createTimer();
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.continueTimer,
              ));
            }
          }

          setState(() {});
        }
      }
    });

    setState(() {});
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
        appBar: managerAppBar(
          context,
          'Câu hỏi phụ',
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
                    // correctButtons(),
                    manageButtons(),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Column(
                    children: sideButtons(),
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
                topLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
                topRight: i == 3 ? const Radius.circular(10) : Radius.zero,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: BorderDirectional(
                    end: BorderSide(
                      color: i > 2 ? Colors.transparent : Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  '${MatchState().players[i].name} (${MatchState().scores[i]} - ${MatchState().extraScores[i]})',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(widget.players[i] ? 1 : 0.35),
                  ),
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
                  canShowQuestion
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          child: Text(
                            'Câu hỏi $questionNum',
                            style: const TextStyle(fontSize: fontSizeLarge),
                          ),
                        )
                      : const SizedBox(),
                  Container(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget manageButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Row(
        children: [
          Expanded(
            child: KLIButton(
              'Câu tiếp theo',
              enableCondition: canNext,
              disabledLabel: "Chưa trả lời",
              onPressed: () {
                nextQuestion();
                currentTimeSec = widget.timeLimitSec;
                canNext = timerStopped = false;
                canStart = canShowQuestion = true;
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void createTimer() {
    timer = Timer.periodic(1.seconds, (timer) {
      if (currentTimeSec <= 0) {
        timer.cancel();
        timerStopped = true;
        canNext = MatchState().questionList!.isNotEmpty;
        canEnd = !canNext;
        canStopTimer = canAnnounce = false;
        setState(() {});
      } else {
        currentTimeSec--;
        setState(() {});
      }
    });
  }

  void nextQuestion() {
    currentQuestion = MatchState().questionList!.removeLast() as ExtraQuestion;
    questionNum++;
    for (final i in range(0, 3)) {
      KLIServer.sendToPlayer(
        i,
        KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.extraQuestion,
          message: jsonEncode(currentQuestion.toJson()),
        ),
      );
    }
    KLIServer.sendToNonPlayer(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.extraQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
  }

  List<Widget> sideButtons() {
    return [
      AnimatedCircularProgressBar(
        currentTimeSec: currentTimeSec,
        totalTimeSec: widget.timeLimitSec,
        strokeWidth: 20,
        valueColor: const Color(0xFF00A906),
        backgroundColor: Colors.red,
      ),
      const Expanded(child: SizedBox()),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: KLIButton(
          'Bắt đầu',
          enableCondition: canStart,
          disabledLabel: 'Phần thi chưa kết thúc',
          onPressed: () {
            canStart = false;
            canStopTimer = true;
            KLIServer.sendToAllClients(
              KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.continueTimer,
              ),
            );
            audioHandler.play(assetHandler.obsBackground, true);
            createTimer();
            setState(() {});
          },
        ),
      ),
      KLIButton(
        'Kết thúc',
        enableCondition: canEnd,
        disabledLabel: 'Phần thi chưa kết thúc',
        onPressed: () {
          confirmDialog(
            context,
            message: 'Kết thúc phần thi?',
            acceptLogMessage: 'Section finished',
            onAccept: () {
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.endSection,
              ));
              Navigator.of(context).pop();
            },
          );
        },
      ),
    ];
  }
}
