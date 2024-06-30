import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';
import 'obstacle_questions.dart';
import 'start.dart';

class MatchOverview extends StatefulWidget {
  const MatchOverview({super.key});

  @override
  State<MatchOverview> createState() => _MatchOverviewState();
}

class _MatchOverviewState extends State<MatchOverview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Match Overview for ${MatchState().match.name}',
          implyLeading: kDebugMode,
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
              // this should only show if somehow the condition is not just match section is start
              if (MatchState().startOrFinishPos > 3) {
                showToastMessage(context, 'All players have finished Start section');
                return;
              }

              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                message: '${MatchState().startOrFinishPos}',
                type: KLIMessageType.enterStart,
              ));

              logHandler.info('Start section, player ${MatchState().startOrFinishPos}');
              await MatchState().loadQuestions();

              if (mounted) {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => StartScreen(
                      playerPos: MatchState().startOrFinishPos,
                    ),
                  ),
                );
              }

              MatchState().nextPlayer();
              if (MatchState().startOrFinishPos == 3) {
                MatchState().nextSection();
              }
              setState(() {});
            },
          ),
          KLIButton(
            'Obstacle',
            enableCondition: MatchState().section == MatchSection.obstacle,
            enabledLabel: 'To Obstacle',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () async {
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                message: '',
                type: KLIMessageType.enterObstacle,
              ));

              await MatchState().loadQuestions();
              if (mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ObstacleQuestionScreen(),
                  ),
                );
              }
              if (MatchState().answeredObstacleRows.every((e) => e)) MatchState().nextSection();
              setState(() {});
            },
          ),
          KLIButton(
            'Accel',
            enableCondition: MatchState().section == MatchSection.accel,
            enabledLabel: 'To Accel',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () {
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                message: '',
                type: KLIMessageType.enterObstacle,
              ));
            },
          ),
          KLIButton(
            'Finish',
            enableCondition: MatchState().section == MatchSection.finish,
            enabledLabel: 'To Finish',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () {
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                message: '',
                type: KLIMessageType.enterFinish,
              ));
            },
          ),
          KLIButton(
            'Extra',
            enableCondition: MatchState().section == MatchSection.extra,
            enabledLabel: 'To Extra',
            disabledLabel: 'Current section: ${MatchState().section.name}',
            onPressed: () {
              KLIServer.sendToAllClients(KLISocketMessage(
                senderID: ConnectionID.host,
                message: '',
                type: KLIMessageType.enterExtra,
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
    final bool isCurrentPlayer =
        (MatchState().section == MatchSection.start || MatchState().section == MatchSection.finish) &&
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
}
