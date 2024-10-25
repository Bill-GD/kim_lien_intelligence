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
                
                - Khởi động: Chuyển tự động sang thí sinh tiếp theo sau khi thí sinh trước hoàn thành.
                  Thí sinh hiện tại sẽ được đánh dấu màu xanh.
                  Nhấn 'Start' để bắt đầu đếm giờ và hiển thị câu hỏi.
                  Nếu thí sinh trả lời hết câu hỏi, hoặc hết giờ, tất cả chức năng sẽ bị khóa.
                  Nhấn 'Kết thúc' để kết thúc phần thi.
                - Chướng ngại vật: Đầu tiên chọn câu hỏi. Nhấn 'Bắt đầu' để bắt đầu đếm giờ và khóa chọn câu hỏi.
                  Sau khi hết giờ, nhấn 'Hiện đáp án' để hiển thị của trả lời của thí sinh.
                  Nhấn 'Hiện hình ảnh' để hiển thị hình ảnh sau khi công bố kết quả.
                  Lặp lại cho đến khi tất cả 4 câu hỏi được chọn. Nhấn 'Trung tâm' để hiển thị câu hỏi trung tâm.
                  Nếu tất cả các câu hỏi đã được chọn, nhấn 'Kết thúc' để hoàn thành phần thi.
                - Tăng tốc: Bấm 'Câu tiếp theo' để hiện câu hỏi.
                  Bấm 'Bắt đầu' để bắt đầu đếm giờ.
                  Sau khi hết giờ, nhấn 'Hiển thị đáp án' để hiển thị của trả lời của thí sinh và thời gian.
                  Bấm 'Giải thích' để hiện giải thích câu hỏi.
                - Về đích: Thứ tự được xác định bởi điểm số. Thí sinh có điểm số cao nhất sẽ được chọn trước.
                  Sau mỗi thí sinh, thí sinh có điểm số cao tiếp theo sẽ được chọn.
                  Nếu có hai thí sinh có cùng điểm số, thí sinh có vị trí nhỏ hơn sẽ được chọn.
                  Người chơi được chọn sẽ được đánh dấu.
                - Câu hỏi phụ: Chọn các thí sinh tham gia sau phần về đích.
                  Bấm 'Câu tiếp theo' để chuyển sang câu hỏi tiếp theo.
                  Khi thí sinh ra tín hiệu trả lời, hiện ô thông tin thí sinh trả lời và dừng thời gian. Nếu đúng sẽ kết thúc, nếu sai các thí sinh còn lại có thể trả lời và tiếp tục thời gian.''',
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
            'Khởi động',
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
                KLIServer.sendToViewers(KLISocketMessage(
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
            'Chướng ngại vật',
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
            'Tăng tốc',
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
            'Về đích',
            enableCondition: MatchState().section == MatchSection.finish,
            enabledLabel: 'To Finish',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              if (MatchState().finishPlayerDone.where((e) => e).isEmpty) {
                audioHandler.play(assetHandler.finishStart);
                KLIServer.sendToViewers(KLISocketMessage(
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

              await Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (context) => FinishScreen(
                  playerPos: MatchState().startOrFinishPos,
                ),
              ));

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
            'Câu hỏi phụ',
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
