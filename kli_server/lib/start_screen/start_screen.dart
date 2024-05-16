import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../data_manager/data_manager_page.dart';
import '../global.dart';
import 'help_screen.dart';
import 'match_data_checker.dart';

// This page shows 2 options:
// - Manage Data
// - Start Hosting

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with WindowListener {
  int sidebarIndex = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          CloseButton(onPressed: () {
            logger.i('Exiting app');
            storageHandler = null;
            exit(0);
          }),
        ],
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ttkl_bg_new.png', package: 'kli_lib'),
            fit: BoxFit.fill,
            opacity: 0.8,
          ),
        ),
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
                label: GestureDetector(
                  onTap: () async {
                    logger.i('Opening changelog...');
                    await showDialog(
                      context: context,
                      builder: (context) {
                        final split = changelog.split(RegExp("(?={)|(?<=})"));

                        return AlertDialog(
                          title: const Text('Changelog', textAlign: TextAlign.center),
                          actions: [
                            TextButton(
                              child: const Text('Licenses'),
                              onPressed: () {
                                showLicensePage(
                                  context: context,
                                  applicationIcon: Image.asset(
                                    'assets/images/ttkl_logo.png',
                                    package: 'kli_lib',
                                    width: 50,
                                    height: 50,
                                  ),
                                  applicationName: 'KLI Server',
                                  applicationVersion: 'v${packageInfo.version}.${packageInfo.buildNumber}',
                                );
                              },
                            ),
                          ],
                          content: SingleChildScrollView(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: fontSizeMSmall),
                                children: <InlineSpan>[
                                  for (String t in split)
                                    TextSpan(
                                      text: t.startsWith('{') ? t.substring(1, t.length - 1) : t,
                                      style: t.startsWith('{') ? const TextStyle(color: Colors.blue) : null,
                                      recognizer: t.startsWith('{')
                                          ? (TapGestureRecognizer()
                                            ..onTap = () {
                                              logger.i('Opening commit: $t');
                                              final commitID = t.replaceAll(RegExp(r'(latest)|[{}]'), '');
                                              final url =
                                                  'https://github.com/Bill-GD/kim_lien_intelligence/commit/$commitID';
                                              launchUrl(Uri.parse(url));
                                            })
                                          : null,
                                    )
                                ],
                              ),
                              softWrap: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'v${packageInfo.version}.${packageInfo.buildNumber}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              items: const [
                SideNavigationBarItem(label: 'Hướng dẫn', icon: FontAwesomeIcons.circleQuestion),
                SideNavigationBarItem(label: 'Quản lý dữ liệu', icon: FontAwesomeIcons.database),
                SideNavigationBarItem(label: 'Bắt đầu trận', icon: Icons.settings_rounded),
                SideNavigationBarItem(label: 'Miscellaneous', icon: FontAwesomeIcons.circlePlus),
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
                      logger.i('Opening Data Manager page...');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DataManagerPage()),
                      );
                    },
                  ),
                  KLIButton(
                    'Mở phần thiết lập trận đấu',
                    onPressed: () async {
                      logger.i('Opening Match Setup');
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MatchDataChecker()),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      KLIButton(
                        'Open Log File',
                        onPressed: () async {
                          logger.i('Opening log...');
                          await launchUrl(Uri.parse(storageHandler!.logFile));
                        },
                      ),
                      KLIButton(
                        'Create MatchState',
                        onPressed: () async {
                          MatchState.createInstance("Match Name");
                          logger.i(jsonEncode(MatchState.instance().toJson()));
                        },
                      ),
                    ],
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
