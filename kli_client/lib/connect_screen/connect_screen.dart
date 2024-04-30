import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _ipTextController = TextEditingController(), _messageController = TextEditingController();
  bool _isConnected = false;
  String _serverMessage = '';
  String _playerId = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ipTextController.dispose();
    _messageController.dispose();
    super.dispose();
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
            DropdownButton(
              value: _playerId.isEmpty ? null : _playerId,
              items: [
                for (final c in Networking.listOfClient)
                  DropdownMenuItem(value: c.toLowerCase().replaceAll(' ', ''), child: Text(c))
              ],
              onChanged: (value) {
                _playerId = value!;
                setState(() {});
              },
            ),
            TextField(
              controller: _ipTextController,
              decoration: const InputDecoration(
                hintText: 'Enter Host IP',
                labelText: 'Host IP',
              ),
            ),
            Text('$_isConnected'),
            TextButton(
              onPressed: () {
                final ip = _ipTextController.value.text.trim();
                if (ip.isEmpty) {
                  showToastMessage(context, 'Please enter an IP');
                  return;
                }
                if (_playerId.isEmpty) {
                  showToastMessage(context, 'Please select a player ID');
                  return;
                }
                logger.i('Client $_playerId is trying to connect to: $ip');

                runZonedGuarded(
                  () async {
                    await initClient(ip, _playerId);
                    setState(() => _isConnected = true);

                    kliClient.onMessageReceived.listen((newMessage) {
                      _serverMessage = newMessage.msg;
                      setState(() {});
                    });
                    if (context.mounted) {
                      showToastMessage(
                        context,
                        'Connected to server as $_playerId with IP: ${kliClient.address}',
                      );
                    }
                  },
                  (e, _) {
                    setState(() => _isConnected = false);
                    logger.e('Error when trying to connect: $e');
                    if (e is SocketException) {
                      showToastMessage(context, 'Host (ip=$ip) not known');
                    } else {
                      showToastMessage(context, '$e');
                    }
                  },
                );
              },
              child: const Text('Connect'),
            ),
            Text('From server: $_serverMessage'),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to Server',
              ),
            ),
            TextButton(
              onPressed: () async {
                if (!_isConnected) {
                  showToastMessage(context, 'Not connected');
                  return;
                }
                if (_messageController.value.text.isEmpty) {
                  showToastMessage(context, 'Please enter a message');
                  return;
                }
                kliClient.sendMessage(
                  KLISocketMessage(_playerId, _messageController.value.text, KLIMessageType.normal),
                );
                if (context.mounted) {
                  showToastMessage(context, 'Sending');
                }
              },
              child: const Text("Send Message"),
            ),
          ],
        ),
      ),
    );
  }
}
