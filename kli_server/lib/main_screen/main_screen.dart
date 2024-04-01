import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final KLIServer _server;
  ServerIPType _ipType = ServerIPType.local;
  String _ipAddress = '';

  @override
  void initState() {
    super.initState();
    getPublicIP().then((value) => setState(() => _ipAddress += '\nPublic: $value'));
    getLocalIP().then((value) => setState(() => _ipAddress += '\nLocal: $value'));
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
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'local', label: 'Local'),
                DropdownMenuEntry(value: 'public', label: 'Public'),
              ],
              onSelected: (value) {
                showToastMessage(context, value ?? 'None');
                _ipType = ServerIPType.values.firstWhere((e) => e.toString() == value);
              },
            ),
            TextButton(
              onPressed: () async {
                KLIServer.startServer(_ipType).then((s) {
                  setState(() => _server = s);

                  showToastMessage(context, 'Started a ${_ipType.name} server with IP: ${_server.address}');
                });
              },
              child: const Text("Create Server"),
            ),
          ],
        ),
      ),
    );
  }
}
