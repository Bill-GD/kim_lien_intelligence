import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _ipAddress = '';
  ServerSocket? serverSocket;

  void startServer() async {
    serverSocket?.close();

    final localIP = await getLocalIP();

    serverSocket = await initServer(localIP);

    // show snackbar here, show ip of server
    if (context.mounted) {
      showToastMessage(context, 'Server started at $_ipAddress');
    }

    serverSocket!.listen((socket) {
      final connectionAddress = socket.remoteAddress.address;
      debugPrint('Connection from $connectionAddress:${socket.remotePort}');
      socket.write('Hello, $connectionAddress!');
      socket.close();
    });
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
            TextButton(
              onPressed: () async {
                _ipAddress = await getPublicIP();
                setState(() {});
              },
              child: const Text("Get IP"),
            ),
            TextButton(
              onPressed: startServer,
              child: const Text("Init Server"),
            ),
          ],
        ),
      ),
    );
  }
}
