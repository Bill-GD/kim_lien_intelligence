import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';
import 'overview.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late final StreamSubscription<KLISocketMessage> messageSubscription;
  bool receivingData = false;

  @override
  void initState() {
    super.initState();
    logHandler.info('Waiting screen');
    messageSubscription = KLIClient.onMessageReceived.listen((newMessage) {
      if (newMessage.type == KLIMessageType.disconnect) {
        KLIClient.disconnect();
        logHandler.info('Message from Host: ${newMessage.message}');
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    messageSubscription.cancel();
    super.dispose();
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
          automaticallyImplyLeading: kDebugMode,
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 175),
          child: Column(
            children: [
              Text(
                'Connected to: ${KLIClient.remoteAddress}',
                style: const TextStyle(fontSize: fontSizeLarge),
              ),
              const SizedBox(height: 64),
              Text(
                'Selected role: ${Networking.getClientDisplayID(KLIClient.clientID!)}',
                style: const TextStyle(fontSize: fontSizeLarge),
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KLIButton(
                    'Back',
                    enableCondition: !receivingData,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 32),
                  KLIButton(
                    'Ready',
                    enableCondition: !receivingData,
                    onPressed: () {
                      if (MatchData().players.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (context) => const Overview()),
                        );
                        return;
                      }

                      KLIClient.sendMessage(KLISocketMessage(
                        senderID: KLIClient.clientID!,
                        message: 'Request players info',
                        type: KLIMessageType.players,
                      ));
                      receivingData = true;
                      setState(() {});

                      KLIClient.onMessageReceived.listen((m) {
                        if (m.type == KLIMessageType.players) {
                          final d = (jsonDecode(m.message)).map(
                            (e) => {
                              'name': e['name'] as String,
                              'imageBytes': Networking.decodeMedia(e['image']),
                            },
                          );

                          MatchData().players.addAll(d);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (context) => const Overview()),
                          );
                          receivingData = false;
                          setState(() {});
                        }
                      });
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
