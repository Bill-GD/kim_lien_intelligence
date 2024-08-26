import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

final _key = GlobalKey<ScaffoldState>();

class AccelScreen extends StatefulWidget {
  final double timeLimitSec = 30;
  final buttonPadding = const EdgeInsets.only(top: 90, bottom: 70);

  const AccelScreen({super.key});

  @override
  State<AccelScreen> createState() => _AccelScreenState();
}

class _AccelScreenState extends State<AccelScreen> {
  double currentTimeSec = 30;
  bool canNext = true,
      canStart = false,
      started = false,
      canShowQuestion = false,
      canShowArrangeAns = false,
      canAnnounceAnswer = false,
      timeEnded = false,
      canEnd = false,
      hideAns = true;
  late AccelQuestion currentQuestion;
  List<bool?> answerResults = [null, null, null, null];
  List<(int, String, double)> answers = List.generate(4, (i) => (i, '', -1));
  Timer? timer;
  int questionNum = 0;
  final imgContainerKey = UniqueKey();
  late final StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    sub = KLIServer.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.accelAnswer) {
        final split = m.message.split('|');
        final playerIndex = m.senderID.index - 1;
        answers[playerIndex] = (playerIndex, split[0], double.parse(split[1]));
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
          'Accel',
          implyLeading: isTesting,
          actions: [Container()],
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        endDrawer: AnswerDrawer(
          answerResult: answerResults,
          checkboxOnChanged: (i, v) {
            answerResults[i] = v;
            canAnnounceAnswer = answerResults.every((e) => e != null);
            setState(() {});
          },
          canCheck: !canNext,
          answers: answers.asMap().entries.map((e) => (e.value.$2, e.value.$3)),
          scores: Iterable<int>.generate(4, (i) => MatchState().scores[answers[i].$1]),
          playerNames: Iterable.generate(4, (i) => MatchState().players[answers[i].$1].name),
          showTime: true,
          actions: [
            KLIButton(
              'Announce Result',
              enableCondition: canAnnounceAnswer,
              onPressed: () {
                int mul = 0;
                for (int i = 0; i < 4; i++) {
                  // if (answers[i].$3 < 0) {
                  //   answerResults[i] = false;
                  //   continue;
                  // }
                  // answerResults[i] = answers[i].$2.toLowerCase() == currentQuestion.answer.toLowerCase();
                  if (answerResults[i] == true) {
                    MatchState().modifyScore(answers[i].$1, (4 - mul) * 10);
                    mul++;
                  }
                }
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  message: jsonEncode(MatchState().scores),
                  type: KLIMessageType.scores,
                ));
                canAnnounceAnswer = false;
                canNext = true;
                if (questionNum == 4) canEnd = true;
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.hideQuestion,
                ));
                setState(() {});
              },
            ),
          ],
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: manageButtons(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget questionContainerTop() {
    return IntrinsicHeight(
      child: Row(
        children: [
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
                  questionNum > 0 ? 'Question $questionNum' : '',
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
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: IntrinsicHeight(
                  child: canShowQuestion
                      ? Text(
                          currentQuestion.question,
                          style: const TextStyle(fontSize: fontSizeMedium),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: canShowQuestion && !hideAns
                    ? Text(
                        currentQuestion.answer,
                        style: const TextStyle(fontSize: fontSizeMedium),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget questionContainer() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(right: 40),
      child: Column(
        children: [
          questionContainerTop(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: BorderDirectional(top: BorderSide(color: Colors.white)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 16),
              alignment: Alignment.center,
              child: started
                  ? AccelImageContainer(
                      key: imgContainerKey,
                      images: currentQuestion.imagePaths.map(
                        (e) => Image.file(
                          File(StorageHandler.getFullPath(e)),
                        ),
                      ),
                      shouldShowArrangeResult:
                          currentQuestion.type == AccelQuestionType.arrange && canShowArrangeAns,
                      isArrange: currentQuestion.type == AccelQuestionType.arrange,
                    )
                  : null,
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
      return;
    }
    questionNum++;
    currentQuestion = MatchState().questionList!.removeLast() as AccelQuestion;
    // caching for continuous display
    PaintingBinding.instance.imageCache.clear(); // clear all cached images
    if (currentQuestion.type == AccelQuestionType.sequence) {
      for (var p in currentQuestion.imagePaths) {
        final i = Image.file(File(StorageHandler.getFullPath(p)));
        final stream = i.image.resolve(const ImageConfiguration());
        stream.addListener(ImageStreamListener((_, __) {}));
      }
    }

    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.accelQuestion,
      message: jsonEncode(currentQuestion.toJson()),
    ));
  }

  Widget manageButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedCircularProgressBar(
          currentTimeSec: currentTimeSec,
          totalTimeSec: widget.timeLimitSec,
          strokeWidth: 20,
          valueColor: const Color(0xFF00A906),
          backgroundColor: Colors.red,
        ),
        const SizedBox(height: 160),
        KLIButton(
          hideAns ? 'Show ans' : 'Hide ans',
          enabledLabel: 'Temporarily hide answer',
          textAlign: TextAlign.center,
          onPressed: () {
            setState(() => hideAns = !hideAns);
          },
        ),
        KLIButton(
          'Start',
          enableCondition: canStart,
          disabledLabel: 'Question is not yet answered',
          onPressed: () {
            canStart = false;
            started = true;
            setState(() {});
            timer = Timer.periodic(1.seconds, (timer) {
              if (currentTimeSec <= 0) {
                timer.cancel();
                timeEnded = true;
                canStart = false;
                answers.sort((a, b) => a.$3.compareTo(b.$3));
                setState(() {});
              } else {
                currentTimeSec--;
                setState(() {});
              }
            });
            KLIServer.sendToAllClients(KLISocketMessage(
              senderID: ConnectionID.host,
              type: KLIMessageType.continueTimer,
            ));
            setState(() {});
          },
        ),
        KLIButton(
          'Explanation',
          enableCondition: timeEnded,
          disabledLabel: 'Question is not yet answered',
          textAlign: TextAlign.center,
          onPressed: () {
            showPopupMessage(
              context,
              title: 'Explanation',
              content: currentQuestion.explanation,
              horizontalPadding: 500,
            );
            if (currentQuestion.type == AccelQuestionType.arrange) {
              setState(() => canShowArrangeAns = true);
            }
          },
        ),
        KLIButton(
          'Next question',
          enableCondition: canNext && questionNum < 4,
          disabledLabel: 'Question is not yet answered',
          textAlign: TextAlign.center,
          onPressed: () {
            nextQuestion();
            answerResults.fillRange(0, 4, null);
            answers = List.generate(4, (i) => (i, '', -1));
            currentTimeSec = widget.timeLimitSec;
            canShowQuestion = canStart = true;
            timeEnded = canNext = started = false;
            setState(() {});
          },
        ),
        KLIButton(
          'Show answers',
          enableCondition: timeEnded,
          disabledLabel: 'Timer is still running',
          textAlign: TextAlign.center,
          onPressed: () {
            setState(() {});
            _key.currentState?.openEndDrawer();
          },
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
      ],
    );
  }
}
