import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../global/global.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _ipTextController = TextEditingController();
  bool _connected = false;
  String serverMessage = '';

  void connectServer() {
    final ip = _ipTextController.value.text;
    debugPrint('Trying to connect to: $ip');

    runZonedGuarded(
      () async {
        kliClient = await KLIClient.initClient(ip);

        setState(() => _connected = true);
        if (mounted) {
          showToastMessage(context, 'Connected to server with IP: ${kliClient.socket.address.address}');
        }

        kliClient.socket.listen((data) {
          setState(() => serverMessage = String.fromCharCodes(data).trim());
        });
      },
      (e, _) {
        setState(() => _connected = false);
        if (e is SocketException) {
          showToastMessage(context, 'Host (ip=$ip) not known');
        } else {
          showToastMessage(context, '$e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Connect to this IP:',
            ),
            TextField(
              controller: _ipTextController,
            ),
            Text(
              '$_connected',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'From server: $serverMessage',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: connectServer,
              child: const Text('Connect'),
            ),
            // send message button
            TextButton(
              onPressed: () => kliClient.sendMessage('socket'),
              child: const Text('Send message'),
            ),
          ],
        ),
      ),
    );
  }
}
