import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_server/start_screen/help_page.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:side_navigation/side_navigation.dart';

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

class _StartPageState extends State<StartPage> {
  int _sidebarIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ttkl_background.png'),
            fit: BoxFit.fill,
            opacity: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(right: BorderSide(width: 1))),
              child: SideNavigationBar(
                selectedIndex: _sidebarIndex,
                expandable: false,
                header: SideNavigationBarHeader(
                  image: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
                    child: Image.asset(
                      'assets/images/ttkl_logo_title.png',
                      scale: 15,
                    ),
                  ),
                  title: const SizedBox.shrink(),
                  subtitle: const SizedBox.shrink(),
                ),
                footer: SideNavigationBarFooter(
                  label: Text(
                    'v${packageInfo.version}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.8),
                    ),
                  ),
                ),
                items: const [
                  SideNavigationBarItem(
                    icon: FontAwesomeIcons.database,
                    label: 'Data Manager',
                  ),
                  SideNavigationBarItem(
                    icon: FontAwesomeIcons.server,
                    label: 'Server Setup',
                  ),
                  SideNavigationBarItem(
                    icon: FontAwesomeIcons.circleQuestion,
                    label: 'Instruction',
                  ),
                ],
                onTap: (newIndex) {
                  setState(() {
                    _sidebarIndex = newIndex;
                  });
                },
                theme: SideNavigationBarTheme(
                  itemTheme: SideNavigationBarItemTheme(
                    selectedItemColor: Theme.of(context).colorScheme.primary,
                    labelTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, height: 2),
                  ),
                  togglerTheme: SideNavigationBarTogglerTheme.standard(),
                  dividerTheme: SideNavigationBarDividerTheme.standard(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: [
                  ElevatedButton(
                    onPressed: () {
                      logger.i('Opening Data Manager page...');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DataManagerPage(),
                        ),
                      );
                    },
                    child: const Text('Manage Data'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      logger.i('Opening Server Setup page...');
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ServerSetupPage(),
                        ),
                      );
                      await KLIServer.stop();
                    },
                    child: const Text('Start Hosting'),
                  ),
                  const HelpPage(),
                ].elementAt(_sidebarIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
