import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:side_navigation/side_navigation.dart';

import '../global.dart';
import 'accel/accel_question_manager.dart';
import 'extra/extra_question_manager.dart';
import 'finish/finish_question_manager.dart';
import 'match/match_manager.dart';
import 'obstacle/obstacle_question_manager.dart';
import 'start/start_question_manager.dart';

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
  bool _isLoading = true;

  int _selectedPage = 0;
  late final List<Widget> _contentPages;

  @override
  void initState() {
    super.initState();
    _contentPages = [
      const MatchManager(),
      const StartQuestionManager(),
      const ObstacleQuestionManager(),
      const AccelQuestionManager(),
      const FinishQuestionManager(),
      const ExtraQuestionManager(),
    ];
    StorageHandler.init(parentFolder).whenComplete(() => setState(() => _isLoading = false));
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
                  icon: Icons.settings_rounded,
                  label: 'Match',
                ),
                SideNavigationBarItem(
                  icon: Icons.start_rounded,
                  label: 'Start',
                ),
                SideNavigationBarItem(
                  icon: FontAwesomeIcons.roadBarrier,
                  label: 'Obstacle',
                ),
                SideNavigationBarItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Acceleration',
                ),
                SideNavigationBarItem(
                  icon: FontAwesomeIcons.flagCheckered,
                  label: 'Finish',
                ),
                SideNavigationBarItem(
                  icon: Icons.add_box_rounded,
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
          Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _contentPages.elementAt(_selectedPage)),
        ],
      ),
    );
  }
}
