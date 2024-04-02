import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../global/global.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ServerIPType _ipType = ServerIPType.local;
  String _ipAddress = '';

  @override
  void initState() {
    super.initState();
    getIpAddresses();
  }

  void getIpAddresses() async {
    _ipAddress = 'Local: ${await getLocalIP()}';
    setState(() {});
    _ipAddress += '\nPublic: ${await getPublicIP()}';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _ipAddress,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            DropdownMenu(
              label: const Text('Local'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'local', label: 'Local'),
                DropdownMenuEntry(value: 'public', label: 'Public'),
              ],
              onSelected: (value) {
                _ipType = ServerIPType.values.firstWhere((e) => e.name == value);
              },
            ),
            TextButton(
              onPressed: () async {
                if (kliServer != null) {
                  showToastMessage(context, 'Server already exist.');
                  return;
                }

                try {
                  kliServer = await KLIServer.startServer(_ipType);
                } on Exception catch (error) {
                  if (context.mounted) {
                    showToastMessage(context, error.toString());
                  }
                  return;
                }

                if (context.mounted) {
                  showToastMessage(
                    context,
                    'Started a ${_ipType.name} server with IP: ${kliServer!.address}',
                  );
                }
              },
              child: const Text("Create Server"),
            ),
            TextButton(
              onPressed: () async {
                if (kliServer == null) return;
                await kliServer!.closeServer();
                kliServer = null;
              },
              child: const Text("Kill Server"),
            ),
          ],
        ),
      ),
    );
  }
}
