import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/ui/finish.dart';

import '../data_manager/match_state.dart';
import '../global.dart';
import 'accel.dart';
import 'allow_player.dart';
import 'extra.dart';
import 'obstacle_questions.dart';
import 'start.dart';

class MatchOverview extends StatefulWidget {
  const MatchOverview({super.key});

  @override
  State<MatchOverview> createState() => _MatchOverviewState();
}

class _MatchOverviewState extends State<MatchOverview> {
  bool canEndMatch = false, canStartExtra = false;
  List<bool> allowExtra = [];
  StreamSubscription<KLISocketMessage>? sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});

    sub ??= KLIServer.onMessageReceived.listen((m) {
      // if (m.type == KLIMessageType.reconnect) {
      //   MatchState.handleReconnection(m);
      // }
      if (m.type == KLIMessageType.section) {
        KLIServer.sendMessage(
          m.senderID,
          KLISocketMessage(
            senderID: ConnectionID.host,
            message: MatchState().sectionDisplay(MatchState().section),
            type: KLIMessageType.section,
          ),
        );
      }
      if (m.type == KLIMessageType.scores) {
        KLIServer.sendMessage(
          m.senderID,
          KLISocketMessage(
            senderID: ConnectionID.host,
            message: jsonEncode(MatchState().scores),
            type: KLIMessageType.scores,
          ),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant MatchOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateChild = () => setState(() {});
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          fontSize: fontSizeLarge,
          'Tổng quan trận ${MatchState().match.name}',
          // implyLeading: true,
          leading: KLIIconButton(
            const Icon(Icons.arrow_back),
            enableCondition: canEndMatch || isTesting,
            enabledLabel: 'End match',
            disabledLabel: 'Cannot end match yet',
            onPressed: () {
              if (canEndMatch) {
                KLIServer.sendToAllClients(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.endMatch,
                ));
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            const KLIHelpButton(
              content: '''
                Phần thi khởi động sẽ tự động kích hoạt. Nhấn nút tương ứng để bắt đầu phần thi.
                Sau khi mỗi phần thi kết thúc, phần thi tiếp theo sẽ được kích hoạt.
                
                - Khởi động: Chuyển tự động sang người chơi tiếp theo sau khi người chơi trước hoàn thành.
                  Người chơi được chọn sẽ được đánh dấu màu xanh.
                  Nhấn 'Start' để bắt đầu đếm giờ và hiển thị câu hỏi.
                  Nếu người chơi trả lời hết câu hỏi, hoặc hết giờ, tất cả chức năng sẽ bị khóa.
                  Nhấn 'End' để kết thúc phần thi.
                - Obstacle: First select question. Press 'Start' to start the timer and it'll lock question selection.
                  After time is up, Press 'Show answers' to show the answer and time.
                  Press 'Show image' to show the image after announcing the result.
                  Repeat until all 4 question are selected. Press 'Middle question' to show the middle question.
                  If all questions are selected, press 'End' to finish the section.
                - Accel: NA
                - Finish: The order is determined by the score. The player with the highest score will be selected first.
                  After each player, the player with the next highest score will be selected.
                  If there are two players with the same score, the player whose position is smaller will be selected.
                  The seleted player will be highlighted. 
                - Extra: NA''',
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            children: <Widget>[
              sectionButtons(),
              playerDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          KLIButton(
            'Start',
            enableCondition: MatchState().section == MatchSection.start,
            enabledLabel: 'To Start',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              if (!KLIServer.acceptReconnect) KLIServer.acceptReconnect = true;

              // this should only show if somehow the condition is not just match section is start
              if (MatchState().startOrFinishPos > 3) {
                throw KLIException('Start is done', 'All players have finished Start section');
              }
              if (MatchState().startOrFinishPos == 0) {
                audioHandler.play(assetHandler.startStart);
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.startStart,
                ));
              }

              MatchState().loadQuestions();
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.enterStart,
                message: '${MatchState().startOrFinishPos}',
              ));

              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => StartScreen(
                    playerPos: MatchState().startOrFinishPos,
                  ),
                ),
              );

              if (MatchState().startOrFinishPos == 3) {
                MatchState().nextSection();
                showSectionResult();
              }
              MatchState().nextPlayer();
              setState(() {});
            },
          ),
          KLIButton(
            'Obstacle',
            enableCondition: MatchState().section == MatchSection.obstacle,
            enabledLabel: 'To Obstacle',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              MatchState().loadQuestions();
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.enterObstacle,
              ));

              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ObstacleQuestionScreen(),
                ),
              );

              MatchState().nextSection();
              showSectionResult();
              setState(() {});
            },
          ),
          KLIButton(
            'Accel',
            enableCondition: MatchState().section == MatchSection.accel,
            enabledLabel: 'To Accel',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              MatchState().loadQuestions();

              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.enterAccel,
              ));

              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => const AccelScreen(),
                ),
              );

              MatchState().nextSection();
              showSectionResult();
              setState(() {});
              // MatchState().startOrFinishPos = 0;
              MatchState().nextPlayer();
            },
          ),
          KLIButton(
            'Finish',
            enableCondition: MatchState().section == MatchSection.finish,
            enabledLabel: 'To Finish',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              if (MatchState().finishPlayerDone.where((e) => e).isEmpty) {
                audioHandler.play(assetHandler.finishStart);
                KLIServer.sendToNonPlayer(KLISocketMessage(
                  senderID: ConnectionID.host,
                  type: KLIMessageType.playAudio,
                  message: assetHandler.finishStart,
                ));
              }

              if (MatchState().finishNotStarted) MatchState().loadQuestions();

              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.enterFinish,
                message: '${MatchState().startOrFinishPos}',
              ));

              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => FinishScreen(playerPos: MatchState().startOrFinishPos),
                ),
              );

              MatchState().finishPlayerDone[MatchState().startOrFinishPos] = true;
              if (MatchState().allFinishPlayerDone) {
                MatchState().nextSection();
                showSectionResult();
                if (mounted) {
                  final s = await Navigator.of(context).push<List<bool>>(
                    PageRouteBuilder(
                      opaque: false,
                      transitionsBuilder: (_, anim1, __, child) {
                        return ScaleTransition(
                          scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      transitionDuration: 150.ms,
                      reverseTransitionDuration: 150.ms,
                      pageBuilder: (_, __, ___) => const AllowExtraDialog(),
                    ),
                  );
                  if (s != null) allowExtra = s;
                }

                if (allowExtra.isEmpty) {
                  setState(() => canEndMatch = true);
                  return;
                }
                canStartExtra = true;

                KLIServer.sendToAllExcept(
                  ConnectionID.values.where(
                    (e) => e.name.contains('player') && allowExtra[e.index - 1],
                  ),
                  KLISocketMessage(
                    senderID: ConnectionID.host,
                    type: KLIMessageType.endMatch,
                  ),
                );
              } else {
                MatchState().nextPlayer();
              }
              setState(() {});
            },
          ),
          KLIButton(
            'Extra',
            enableCondition: canStartExtra && MatchState().section == MatchSection.extra,
            enabledLabel: 'To Extra',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              MatchState().loadQuestions();
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.enterExtra,
                message: jsonEncode(allowExtra.asMap().entries.where((e) => e.value).map((e) => e.key).toList()),
              ));

              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => ExtraScreen(players: allowExtra),
                ),
              );

              showSectionResult();
              setState(() => canEndMatch = true);
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                type: KLIMessageType.endMatch,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget playerDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < 4; i++) playerWidget(i),
      ],
    );
  }

  Widget playerWidget(int pos) {
    final bool isCurrentPlayer = //
        (MatchState().section == MatchSection.start || MatchState().section == MatchSection.finish) && //
            MatchState().startOrFinishPos == pos;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              borderRadius: BorderRadius.circular(5),
            ),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 450, minHeight: 1, minWidth: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.file(
                File(StorageHandler.getFullPath(MatchState().players[pos].imagePath)),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCurrentPlayer
                    ? Colors.lightGreenAccent //
                    : Theme.of(context).colorScheme.onBackground,
              ),
              color: isCurrentPlayer
                  ? Colors.green[800] //
                  : Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                Text(
                  MatchState().players[pos].name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
                Divider(color: isCurrentPlayer ? Colors.lightGreenAccent : Colors.white),
                Text(
                  MatchState().scores[pos].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSectionResult() {
    final l = <(String, String, int)>[];
    for (int i = 0; i < 4; i++) {
      l.add((
        MatchState().players[i].name,
        StorageHandler.getFullPath(MatchState().players[i].imagePath),
        MatchState().scores[i],
      ));
    }

    l.sort((a, b) => b.$3.compareTo(a.$3));

    KLIServer.sendToNonPlayer(KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.showScores,
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionResult(
          backgroundImage: bgDecorationImage,
          players: l.map((e) => e.$1).toList(),
          images: l.map((e) => e.$2).toList(),
          scores: l.map((e) => e.$3).toList(),
          playMusic: audioHandler.play,
          allowClose: true,
          isServer: true,
        ),
      ),
    );
  }
}
