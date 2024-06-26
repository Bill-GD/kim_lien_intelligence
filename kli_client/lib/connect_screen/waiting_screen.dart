import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import 'overview.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    logHandler.info('Waiting screen');
    KLIClient.onMessageReceived.listen((newMessage) {
      if (newMessage.type == KLIMessageType.disconnect) {
        KLIClient.disconnect();
        logHandler.info('Message from Host: ${newMessage.message}');
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Waiting room', style: TextStyle(fontSize: fontSizeLarge)),
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 175),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Connected to: ${KLIClient.socket!.address.address}',
                style: const TextStyle(fontSize: fontSizeLarge),
              ),
              const SizedBox(height: 64),
              Text(
                'Selected role: ${Networking.getClientDisplayID(KLIClient.clientID!)}',
                style: const TextStyle(fontSize: fontSizeLarge),
              ),
              const SizedBox(height: 64),
              // const Text(
              //   'Waiting for host to start the game...',
              //   style: TextStyle(fontSize: fontSizeLarge),
              // ),
              // const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KLIButton(
                    'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 32),
                  KLIButton(
                    'Ready',
                    onPressed: () {
                      KLIClient.sendMessage(KLISocketMessage(
                        senderID: KLIClient.clientID!,
                        message: 'Request players info',
                        type: KLIMessageType.players,
                      ));
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const Overview(),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
