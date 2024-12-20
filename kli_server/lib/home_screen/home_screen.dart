import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../data_manager/data_manager_page.dart';
import '../global.dart';
import '../match_setup/match_data_checker.dart';
import 'help_screen.dart';
import 'sound_test.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int sidebarIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          CloseButton(onPressed: () {
            logHandler.info('Exiting app');
            exit(0);
          }),
        ],
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: BoxDecoration(image: bgDecorationImage),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SideNavigationBar(
              selectedIndex: sidebarIndex,
              expandable: false,
              header: SideNavigationBarHeader(
                image: const SizedBox.shrink(),
                title: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 10),
                  child: Image.asset('assets/images/ttkl_logo_title_light.png', package: 'kli_lib'),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(left: 100, bottom: 10),
                  child: Text('Host', style: TextStyle(fontSize: fontSizeSmall, color: Colors.white70)),
                ),
              ),
              footer: SideNavigationBarFooter(
                label: ChangelogPanel(
                  changelog: changelog,
                  versionString: appVersionString,
                  appName: 'KLI Server',
                  devToggle: () {
                    showDebugInfo = !showDebugInfo;
                    updateDebugOverlay();
                  },
                ),
              ),
              items: const [
                SideNavigationBarItem(label: 'Hướng dẫn', icon: FontAwesomeIcons.circleQuestion),
                SideNavigationBarItem(label: 'Quản lý dữ liệu', icon: FontAwesomeIcons.database),
                SideNavigationBarItem(label: 'Bắt đầu trận', icon: Icons.settings_rounded),
                SideNavigationBarItem(label: 'Âm thanh', icon: FontAwesomeIcons.music),
                SideNavigationBarItem(label: 'Log', icon: FontAwesomeIcons.solidFile),
              ],
              onTap: (newIndex) {
                setState(() => sidebarIndex = newIndex);
              },
              theme: sideNavigationTheme(context, 3),
            ),
            Expanded(
              child: Center(
                child: [
                  const HelpScreen(),
                  KLIButton(
                    'Mở phần quản lý dữ liệu',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DataManagerPage()),
                      );
                    },
                  ),
                  KLIButton(
                    'Mở phần thiết lập trận đấu',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MatchDataChecker()),
                      );
                    },
                  ),
                  const SoundTest(),
                  KLIButton(
                    'Mở file log',
                    onPressed: () async {
                      logHandler.info('Opening log...');
                      await launchUrlString(
                        Uri.file(storageHandler.logFile).toFilePath(windows: true),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ].elementAt(sidebarIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
