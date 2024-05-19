import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:side_navigation/side_navigation.dart';

import '../global.dart';
import 'accel/accel_manager.dart';
import 'extra/extra_manager.dart';
import 'finish/finish_manager.dart';
import 'match/match_manager.dart';
import 'obstacle/obstacle_manager.dart';
import 'start/start_manager.dart';

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
      const ObstacleManager(),
      const AccelManager(),
      const FinishManager(),
      const ExtraManager(),
    ];
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          logger.i('Exiting data manager...');
          Navigator.pop(context);
        }
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ttkl_bg_new.png', package: 'kli_lib'),
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
                  theme: sideNavigationTheme(context),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : contentPages.elementAt(selectedPage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
