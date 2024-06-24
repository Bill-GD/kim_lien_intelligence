import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/global.dart';

import '../data_manager/match_state.dart';
import 'start.dart';

class MatchOverview extends StatefulWidget {
  final DecorationImage background;
  const MatchOverview({super.key, required this.background});

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
      decoration: BoxDecoration(
        image: widget.background,
      ),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Match Overview for ${MatchState.i.match.name}',
          implyLeading: kDebugMode,
          actions: [
            const HelpButton(
              content: '''
                To be determined''',
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
            enableCondition: kDebugMode || MatchState.i.currentSection == MatchSection.start,
            enabledLabel: 'To Start',
            disabledLabel: 'Current section: ${MatchState.i.currentSection.name}',
            onPressed: () async {
              if (MatchState.i.startPos >= 3) {
                showToastMessage(context, 'All players have finished Start section');
                return;
              }

              MatchState.i.nextPlayer();
              await MatchState.i.loadQuestions();

              if (mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StartSectionScreen(
                      background: widget.background,
                      playerPos: MatchState.i.startPos,
                      questions: MatchState.i.currentQuestionList! as List<StartQuestion>,
                    ),
                  ),
                );
              }

              if (MatchState.i.startPos == 3) {
                MatchState.i.nextSection();
              }
              setState(() {});
            },
          ),
          KLIButton(
            'Obstacle',
            enableCondition: kDebugMode || MatchState.i.currentSection == MatchSection.obstacle,
            enabledLabel: 'To Obstacle',
            disabledLabel: 'Current section: ${MatchState.i.currentSection.name}',
            onPressed: () {},
          ),
          KLIButton(
            'Accel',
            enableCondition: kDebugMode || MatchState.i.currentSection == MatchSection.accel,
            enabledLabel: 'To Accel',
            disabledLabel: 'Current section: ${MatchState.i.currentSection.name}',
            onPressed: () {},
          ),
          KLIButton(
            'Finish',
            enableCondition: kDebugMode || MatchState.i.currentSection == MatchSection.finish,
            enabledLabel: 'To Finish',
            disabledLabel: 'Current section: ${MatchState.i.currentSection.name}',
            onPressed: () {},
          ),
          KLIButton(
            'Extra',
            enableCondition: kDebugMode || MatchState.i.currentSection == MatchSection.extra,
            enabledLabel: 'To Extra',
            disabledLabel: 'Current section: ${MatchState.i.currentSection.name}',
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
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              borderRadius: BorderRadius.circular(5),
            ),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 450, minHeight: 1, minWidth: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.file(
                File('${StorageHandler.appRootDirectory}\\${player.imagePath}'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              color: Theme.of(context).colorScheme.background,
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
