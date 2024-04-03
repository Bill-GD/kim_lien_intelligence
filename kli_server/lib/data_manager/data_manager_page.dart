import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:side_navigation/side_navigation.dart';

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
    return ElevatedButton(
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

  int _selectedIndex = 0;
  final List<Widget> views = [
    // Help message here
    const Center(
      child: Text('Data Manager'),
    ),
    const MatchManager(),
    const StartQuestionManager(),
    const ObstacleQuestionManager(),
    const AccelQuestionManager(),
    const FinishQuestionManager(),
    const ExtraQuestionManager(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(border: Border(right: BorderSide(width: 1))),
            child: SideNavigationBar(
              selectedIndex: _selectedIndex,
              expandable: false,
              items: const [
                SideNavigationBarItem(
                  icon: Icons.arrow_back,
                  label: 'Back',
                ),
                SideNavigationBarItem(
                  icon: CupertinoIcons.add,
                  label: 'Match',
                ),
                SideNavigationBarItem(
                  icon: Icons.format_list_numbered_rtl,
                  label: 'Start',
                ),
                SideNavigationBarItem(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Obstacle',
                ),
                SideNavigationBarItem(
                  icon: Icons.battery_charging_full_outlined,
                  label: 'Acceleration',
                ),
                SideNavigationBarItem(
                  icon: Icons.check_circle_outline,
                  label: 'Finish',
                ),
                SideNavigationBarItem(
                  icon: Icons.filter_list_outlined,
                  label: 'Extra',
                ),
              ],
              onTap: (newIndex) {
                setState(() {
                  if (newIndex == 0) {
                    Navigator.of(context).pop();
                    return;
                  }
                  _selectedIndex = newIndex;
                });
              },
              theme: SideNavigationBarTheme(
                itemTheme: SideNavigationBarItemTheme(
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  labelTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                togglerTheme: SideNavigationBarTogglerTheme.standard(),
                dividerTheme: SideNavigationBarDividerTheme.standard(),
              ),
            ),
          ),
          Expanded(child: views.elementAt(_selectedIndex)),
        ],
      ),
    );
  }
}
