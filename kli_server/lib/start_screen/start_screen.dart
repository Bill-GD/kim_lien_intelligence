import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../data_manager/data_manager_page.dart';
import '../global.dart';
import '../server_setup/server_setup.dart';
import 'help_screen.dart';

// This page shows 2 options:
// - Manage Data
// - Start Hosting

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with WindowListener {
  int _sidebarIndex = 0;

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
            image: AssetImage('assets/images/ttkl_bg_new.png'),
            fit: BoxFit.fill,
            opacity: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SideNavigationBar(
              selectedIndex: _sidebarIndex,
              expandable: false,
              header: SideNavigationBarHeader(
                image: const SizedBox.shrink(),
                title: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 10),
                  child: Image.asset('assets/images/ttkl_logo_title_light.png'),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 100, bottom: 10),
                  child: Text(
                    'Host',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ),
                  ),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8)),
                  ),
                ),
              ),
              items: const [
                SideNavigationBarItem(label: 'Hướng dẫn', icon: FontAwesomeIcons.circleQuestion),
                SideNavigationBarItem(label: 'Quản lý dữ liệu', icon: FontAwesomeIcons.database),
                SideNavigationBarItem(label: 'Server Setup', icon: FontAwesomeIcons.server),
                SideNavigationBarItem(label: 'Miscellaneous', icon: FontAwesomeIcons.circlePlus),
              ],
              onTap: (newIndex) {
                if (newIndex == 2) logger.i('Accessing help page');
                setState(() => _sidebarIndex = newIndex);
              },
              theme: SideNavigationBarTheme(
                itemTheme: SideNavigationBarItemTheme(
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  labelTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizeMSmall,
                    height: 3,
                  ),
                ),
                togglerTheme: SideNavigationBarTogglerTheme.standard(),
                dividerTheme: SideNavigationBarDividerTheme.standard(),
              ),
            ),
            Expanded(
              child: Center(
                child: [
                  // Help screen
                  const HelpScreen(),
                  button(
                    context,
                    'Mở phần quản lý dữ liệu',
                    onPressed: () {
                      logger.i('Opening Data Manager page...');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DataManagerPage()),
                      );
                    },
                  ),
                  button(
                    context,
                    'Open Server Setup',
                    onPressed: () async {
                      logger.i('Opening Server Setup page...');
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ServerSetupPage()),
                      );
                      await KLIServer.stop();
                    },
                  ),
                  button(
                    context,
                    'Open Log File',
                    onPressed: () async {
                      logger.i('Opening log...');
                      await launchUrl(Uri.parse(storageHandler!.logFile));
                    },
                  ),
                ].elementAt(_sidebarIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String changelog = """
  0.2.8.3 ({latest}):
  - Added changelog & changelog view in app
  - Changed help screen layout to avoid overflow on launch

  0.2.8.2 ({8491f11}):
  - Trim all text input fields
  - Import preview line spacing
  - Named parameters consistency

  0.2.8.1 ({c858fb4}):
  - Changed all save files to json
  - Notify on errors where applicable

  0.2.8 ({f06065d}):
  - Added preview window for importing data -> can check for errors in data
  - Added obstacle editor (NOT obstacle QUESTION editor)

  0.2.7.1 ({dc7ecea}):
  - Only enable editor 'Done' when all required fields is filled
  - Fixed changing match name delete all of its saved questions

  0.2.7 ({f41ab9c}):
  - Added "localization"
  - Added accel question type
  - Better confirm dialog

  0.2.6.3 ({34330ac}):
  - Added confirm dialog when deleting questions
  - Backend changes: early returns, save files structure
  - Shortened some messages
  - Log message has time
  - Button to open app folder, instruction file, log file

  0.2.6.2 ({7096e17}):
  - Generics for question managers
  - New background image
  - Ensure window only show after forced fullscreen
  - Added exit button in start screen

  0.2.6.1 ({4e00f85}):
  - Help screen is first/default page in start screen

  0.2.6 ({6b65e46}):
  - Added help screen
  - Storage handler excel reader: limit sheet count
  
  0.2.5 ({119b134}):
  - Added feature to add singular start question
  - Fixed manager bug related to nullable
  - Added acceleration question manager
  - Minor fixes: match manager background, can't add start question, wrong log messages

  0.2.4 ({e155b1c}):
  - Better seekbar for finish question video
  - Notify if media file isn't found at specified path
  - Extra question manager
  - Changed sdk lower bound: 2.19.6 -> 3.0 (record/pattern)
  - Better custom list tile for question lists

  0.2.3 ({2cb1ac7}):
  - Finish question video rework: change lib, can remove
  - Output log in release build
  - Updated data manager background

  0.2.2 ({2eea3c9}):
  - Wrap Start questions in a match
  - Log output to file, even from kli_utils
  - Added finish question manager
  - Change log file location

  0.2.1 ({5f21bdf}):
  - Obstacle question manager: wrap questions in a match

  0.2 ({e8fc93f}):
  - Added Match manager: match name, players
  - Added Start question manager: question list, add/edit/remove
  - App theme, icon
  - Better storage handler: init folders/files, read/write file

  0.1.x ({333b4f3}):
  - Added basic messaging (with utf8)
  - Basic setup for data manager: UI
  - Added logger: logs to console
  - Added basic start screen: side navigation, app version
  - Added storage handler: read excel, write to file
  - Force fullscreen on launch

  0.0.1.x ({d9628a9}):
  - Initial version -> setup workspace
  - Added basic server setup & server-client connection""";
}
