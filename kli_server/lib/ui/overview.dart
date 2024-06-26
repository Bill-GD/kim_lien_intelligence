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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Match Overview for ${MatchState.i.match.name}',
          implyLeading: kDebugMode,
          actions: [
            const KLIHelpButton(
              content: '''
                Start section is automatically enabled. Press the corresponding button to start the section.
                After each section is finished, the next section button will be enabled.

                - Start: Automatically change to the next player after the previous player is done.
                  The seleted player will be highlighted.
                  Press 'Start' to start the timer and show the questions.
                  If player answered all questions, or the timer is up, all functions will be locked.
                  Press 'End' finish the section.
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
            enableCondition: MatchState.i.section == MatchSection.start,
            enabledLabel: 'To Start',
            disabledLabel: 'Current section: ${MatchState.i.section.name}',
            onPressed: () async {
              // this should only show if somehow the condition is not just match section is start
              if (MatchState.i.startOrFinishPos > 3) {
                showToastMessage(context, 'All players have finished Start section');
                return;
              }

              logHandler.info('Start section, player ${MatchState.i.startOrFinishPos}');
              await MatchState.i.loadQuestions();

              if (mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StartScreen(
                      playerPos: MatchState.i.startOrFinishPos,
                    ),
                  ),
                );
              }

              if (MatchState.i.startOrFinishPos == 3) {
                MatchState.i.nextSection();
              }
              MatchState.i.nextPlayer();
              setState(() {});
            },
          ),
          KLIButton(
            'Obstacle',
            enableCondition: MatchState.i.section == MatchSection.obstacle,
            enabledLabel: 'To Obstacle',
            disabledLabel: 'Current section: ${MatchState.i.section.name}',
            onPressed: () async {
              await MatchState.i.loadQuestions();
              if (mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ObstacleQuestionScreen(),
                  ),
                );
              }
              if (MatchState.i.answeredObstacleRows.every((e) => e)) MatchState.i.nextSection();
              setState(() {});
            },
          ),
          KLIButton(
            'Accel',
            enableCondition: MatchState.i.section == MatchSection.accel,
            enabledLabel: 'To Accel',
            disabledLabel: 'Current section: ${MatchState.i.section.name}',
            onPressed: () {},
          ),
          KLIButton(
            'Finish',
            enableCondition: MatchState.i.section == MatchSection.finish,
            enabledLabel: 'To Finish',
            disabledLabel: 'Current section: ${MatchState.i.section.name}',
            onPressed: () {},
          ),
          KLIButton(
            'Extra',
            enableCondition: MatchState.i.section == MatchSection.extra,
            enabledLabel: 'To Extra',
            disabledLabel: 'Current section: ${MatchState.i.section.name}',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget playerDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < 4; i++) playerWidget(i, MatchState.i.players[i]),
      ],
    );
  }

  Widget playerWidget(int pos, KLIPlayer player) {
    final bool isCurrentPlayer = MatchState.i.startOrFinishPos == pos &&
        (MatchState.i.section == MatchSection.start || MatchState.i.section == MatchSection.finish);

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
                File(StorageHandler.getFullPath(player.imagePath)),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              color: isCurrentPlayer
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                Text(
                  player.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
                const Divider(color: Colors.white),
                Text(
                  MatchState.i.scores[pos].toString(),
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
