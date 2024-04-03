import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import 'data_manager/data_manager_page.dart';
import 'server_setup/server_setup.dart';

// This page shows 2 options:
// - Manage Data
// - Start Hosting

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DataManagerPage(),
                  ),
                );
              },
              child: const Text('Manage Data'),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ServerSetupPage(),
                  ),
                );
                await KLIServer.stop();
              },
              child: const Text('Start Hosting'),
            ),
          ],
        ),
      ),
    );
  }
}
