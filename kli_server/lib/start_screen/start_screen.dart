import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_server/start_screen/help_screen.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:window_manager/window_manager.dart';

import '../data_manager/data_manager_page.dart';
import '../global.dart';
import '../server_setup/server_setup.dart';

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
            logger.i('[${DateTime.now()}] Exiting app');
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
                label: Text(
                  'v${packageInfo.version}.${packageInfo.buildNumber}',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8)),
                ),
              ),
              items: const [
                SideNavigationBarItem(label: 'Instruction', icon: FontAwesomeIcons.circleQuestion),
                SideNavigationBarItem(label: 'Data Manager', icon: FontAwesomeIcons.database),
                SideNavigationBarItem(label: 'Server Setup', icon: FontAwesomeIcons.server),
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
                    'Open Data Manager',
                    enableCondition: true,
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
                    enableCondition: true,
                    onPressed: () async {
                      logger.i('Opening Server Setup page...');
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ServerSetupPage()),
                      );
                      await KLIServer.stop();
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
}
