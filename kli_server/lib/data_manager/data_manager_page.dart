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

    initStorageHandler().whenComplete(() {
      _contentPages = [
        const MatchManager(),
        const StartQuestionManager(),
        const ObstacleQuestionManager(),
        const AccelQuestionManager(),
        const FinishQuestionManager(),
        const ExtraQuestionManager(),
      ];
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideNavigationBar(
            selectedIndex: _selectedPage,
            expandable: false,
            header: SideNavigationBarHeader(
              image: BackButton(
                onPressed: () {
                  logger.i('Exiting data manager...');
                  Navigator.of(context).pop();
                },
              ),
              title: const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'Data Manager',
                  style: TextStyle(
                    fontSize: fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: SizedBox.shrink(),
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
                logger.i('Selecting ${_contentPages[newIndex].runtimeType}');
              });
            },
            theme: SideNavigationBarTheme(
              itemTheme: SideNavigationBarItemTheme(
                selectedItemColor: Theme.of(context).colorScheme.primary,
                labelTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSizeMSmall,
                  height: 2,
                ),
              ),
              togglerTheme: SideNavigationBarTogglerTheme.standard(),
              dividerTheme: SideNavigationBarDividerTheme.standard(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contentPages.elementAt(_selectedPage),
          ),
        ],
      ),
    );
  }
}
