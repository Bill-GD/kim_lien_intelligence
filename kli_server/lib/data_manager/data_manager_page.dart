import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:side_navigation/side_navigation.dart';

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
  int _selectedPage = 0;
  final List<Widget> _contentPages = [
    const MatchManager(),
    const StartQuestionManager(),
    const ObstacleQuestionManager(),
    const AccelQuestionManager(),
    const FinishQuestionManager(),
    const ExtraQuestionManager(),
  ];

  @override
  void initState() {
    super.initState();
    // TODO: implement storage init here
    // Match: same dir

  }

  void _initStorage() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(border: Border(right: BorderSide(width: 1))),
            child: SideNavigationBar(
              selectedIndex: _selectedPage,
              expandable: false,
              header: SideNavigationBarHeader(
                image: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 30, bottom: 30),
                  child: Text('Data Manager', style: Theme.of(context).textTheme.titleLarge),
                ),
                subtitle: const SizedBox.shrink(),
              ),
              items: const [
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
                  _selectedPage = newIndex;
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
          Expanded(child: _contentPages.elementAt(_selectedPage)),
        ],
      ),
    );
  }
}
