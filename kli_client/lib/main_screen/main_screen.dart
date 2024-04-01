import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _ipTextController = TextEditingController();
  bool _connected = false;
  late Socket socket;
  String serverMessage = '';

  void connectServer() {
    final ip = _ipTextController.value.text;
    debugPrint('Trying to connect to: $ip');

    runZonedGuarded(() async {
      socket = await connectToServer(ip);
      socket.listen((data) {
        setState(() => serverMessage = String.fromCharCodes(data).trim());
      });
      setState(() => _connected = true);
    }, (e, _) {
      setState(() => _connected = false);
      if (e is SocketException) {
        debugPrint('SocketException: Host $ip not known');
      } else {
        debugPrint('Error: $e');
      }
    });
  }

  void sendMessage(String msg) {
    socket.write(msg);
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
              onPressed: () => sendMessage('socket'),
              child: const Text('Send message'),
            ),
          ],
        ),
      ),
    );
  }
}
