import 'package:flutter/material.dart';

import '../global.dart';
import 'accel_question_manager.dart';
import 'extra_question_manager.dart';
import 'finish_question_manager.dart';
import 'match_manager.dart';
import 'obstacle_question_manager.dart';
import 'start_question_manager.dart';

// This page allows user to manage data
// Has options to manage match, questions
// Opens new page for each type -> init data
// Edit an entry by editing in a dialog box

class DataManagerPage extends StatefulWidget {
  const DataManagerPage({super.key});

  @override
  State<DataManagerPage> createState() => _DataManagerPageState();
}

class _DataManagerPageState extends State<DataManagerPage> {
  Widget getButton(String text, Widget destination) {
    return FilledButton(
      onPressed: () {
        logger.i('Pressed $text');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => destination,
          ),
        );
      },
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Manager'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                getButton('Match', const MatchManager()),
                getButton('Start Questions', const StartQuestionManager()),
                getButton('Obstacle Questions', const ObstacleQuestionManager()),
                getButton('Accel Questions', const AccelQuestionManager()),
                getButton('Finish Questions', const FinishQuestionManager()),
                getButton('Extra Questions', const ExtraQuestionManager()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
