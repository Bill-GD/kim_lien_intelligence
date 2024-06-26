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
  late final StreamSubscription<void> messageSubscription;
  bool receivingData = false;

  @override
  void initState() {
    super.initState();
    logHandler.info('Waiting screen');

    messageSubscription = KLIClient.onDisconnected.listen((_) => Navigator.pop(context));
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
                    enabledLabel: 'No turning back',
                    onPressed: () {
                      if (MatchData().players.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (context) => const Overview()),
                        );
                        return;
                      }
                      MatchData().setPos(KLIClient.clientID!.index - 1);
                      receivingData = true;
                      setState(() {});

                      KLIClient.sendMessage(KLISocketMessage(
                        senderID: KLIClient.clientID!,
                        message: '',
                        type: KLIMessageType.players,
                      ));

                      KLIClient.onMessageReceived.listen((m) {
                        if (m.type == KLIMessageType.players) {
                          int i = 0;
                          final d = (jsonDecode(m.message) as Iterable).map(
                            (e) {
                              return Player(
                                pos: i++,
                                name: e['name'] as String,
                                imageBytes: Networking.decodeMedia(e['image']),
                              );
                            },
                          );

                          MatchData().players.addAll(d);
                          receivingData = false;
                          setState(() {});
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (context) => const Overview()),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              if (receivingData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Requesting match data from host'),
                      SizedBox(width: 16),
                      CircularProgressIndicator(),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
