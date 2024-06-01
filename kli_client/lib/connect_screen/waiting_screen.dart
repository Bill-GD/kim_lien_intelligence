import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    logHandler.info('Waiting screen', d: 0);
    KLIClient.onMessageReceived.listen((newMessage) {
      if (newMessage.type == KLIMessageType.disconnect) {
        KLIClient.disconnect();
        logHandler.info('Message from Host: ${newMessage.msg}');
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          logHandler.info('Leaving waiting room', d: 0);
          Navigator.pop(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Container(
          decoration: BoxDecoration(image: bgWidget),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              centerTitle: true,
              title: const Text('Waiting room', style: TextStyle(fontSize: fontSizeLarge)),
              forceMaterialTransparency: true,
            ),
            body: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 175),
                child: Column(
                  children: [
                    Text(
                      'Selected role: ${Networking.getClientDisplayID(KLIClient.clientID!)}',
                      style: const TextStyle(fontSize: fontSizeLarge),
                    ),
                    const SizedBox(height: 64),
                    Text(
                      'Connected to: ${KLIClient.socket!.address.address}',
                      style: const TextStyle(fontSize: fontSizeLarge),
                    ),
                    const SizedBox(height: 64),
                    const Text(
                      'Waiting for host to start the game...',
                      style: TextStyle(fontSize: fontSizeLarge),
                    ),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
