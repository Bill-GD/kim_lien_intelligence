import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data_manager/data_manager_page.dart';
import '../global.dart';
import '../match_setup/match_data_checker.dart';
import 'background_manager.dart';
import 'help_screen.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int sidebarIndex = 0;

  @override
  void initState() {
    logHandler.depth = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          CloseButton(onPressed: () {
            logHandler.info('Exiting app', d: 0);
            exit(0);
          }),
        ],
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: BoxDecoration(image: bgWidget),
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
                  versionString: 'v${packageInfo.version}.${packageInfo.buildNumber}',
                  appName: 'KLI Server',
                ),
              ),
              items: const [
                SideNavigationBarItem(label: 'Hướng dẫn', icon: FontAwesomeIcons.circleQuestion),
                SideNavigationBarItem(label: 'Quản lý dữ liệu', icon: FontAwesomeIcons.database),
                SideNavigationBarItem(label: 'Bắt đầu trận', icon: Icons.settings_rounded),
                SideNavigationBarItem(label: 'Hình nền', icon: FontAwesomeIcons.image),
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
                  // Help screen
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
                  BackgroundManager(parentSetState: setState),
                  KLIButton(
                    'Open Log File',
                    onPressed: () async {
                      logHandler.info('Opening log...');
                      await launchUrl(Uri.parse(storageHandler.logFile));
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
