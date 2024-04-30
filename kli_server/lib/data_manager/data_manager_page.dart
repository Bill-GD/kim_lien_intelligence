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
  bool isLoading = true;

  int selectedPage = 0;
  late final List<Widget> contentPages;

  @override
  void initState() {
    super.initState();
    contentPages = [
      const MatchManager(),
      const StartQuestionManager(),
      const ObstacleQuestionManager(),
      const AccelQuestionManager(),
      const FinishQuestionManager(),
      const ExtraQuestionManager(),
    ];
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ttkl_bg_new.png'),
            fit: BoxFit.fill,
            opacity: 0.8,
          ),
        ),
        child: Row(
          children: [
            SideNavigationBar(
              selectedIndex: selectedPage,
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
                    'Quản lý dữ liệu',
                    style: TextStyle(fontSize: fontSizeLarge + 1, fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: const SizedBox.shrink(),
              ),
              items: const [
                SideNavigationBarItem(label: 'Trận đấu', icon: Icons.settings_rounded),
                SideNavigationBarItem(label: 'Khởi động', icon: Icons.start_rounded),
                SideNavigationBarItem(label: 'Vượt chướng ngại vật', icon: FontAwesomeIcons.roadBarrier),
                SideNavigationBarItem(label: 'Tăng tốc', icon: Icons.local_fire_department_rounded),
                SideNavigationBarItem(label: 'Về đích', icon: FontAwesomeIcons.flagCheckered),
                SideNavigationBarItem(label: 'Câu hỏi phụ', icon: Icons.add_box_rounded),
              ],
              onTap: (newIndex) {
                setState(() => selectedPage = newIndex);
                logger.i('Selecting ${contentPages[newIndex].runtimeType}');
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contentPages.elementAt(selectedPage),
            ),
          ],
        ),
      ),
    );
  }
}
