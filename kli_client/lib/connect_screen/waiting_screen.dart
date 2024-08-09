import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  int dataReceived = 0, totalData = 0;
  String matchName = '';

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
      decoration: BoxDecoration(image: bgDecorationImage),
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
                        type: KLIMessageType.dataSize,
                      ));

                      KLIClient.onMessageReceived.listen((m) async {
                        if (m.type == KLIMessageType.dataSize) {
                          totalData = int.parse(m.message);
                          setState(() {});

                          KLIClient.sendMessage(KLISocketMessage(
                            senderID: KLIClient.clientID!,
                            type: KLIMessageType.matchName,
                          ));
                        }

                        if (m.type == KLIMessageType.matchName) {
                          matchName = m.message;
                          final c = await StorageHandler.appCacheDirectory;
                          if (File('$c\\$matchName\\size.txt').existsSync() &&
                              File('$c\\$matchName\\names.txt').existsSync()) {
                            final s = StorageHandler().readFromFile('$c\\$matchName\\size.txt');
                            final n = StorageHandler().readFromFile('$c\\$matchName\\names.txt').split('|');

                            if (totalData == int.parse(s)) {
                              setState(() => receivingData = false);
                              MatchData().players.addAll(List.generate(
                                    4,
                                    (i) => Player(
                                      pos: i,
                                      name: n[i],
                                      fullImagePath: '$c\\$matchName\\player_image_$i.png',
                                    ),
                                  ));
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement<void, void>(
                                  MaterialPageRoute<void>(builder: (context) => const Overview()),
                                );
                              }
                              return;
                            }
                          }

                          KLIClient.sendMessage(KLISocketMessage(
                            senderID: KLIClient.clientID!,
                            type: KLIMessageType.matchData,
                          ));

                          KLIClient.onDataReceived.listen((b) {
                            print(b);
                            dataReceived += b;
                            setState(() {});
                          });
                        }

                        if (m.type == KLIMessageType.matchData) {
                          final d = jsonDecode(String.fromCharCodes(
                            zlib.decode(m.message.codeUnits),
                          )) as Map<String, dynamic>;
                          final n = List<String>.filled(4, '');
                          final c = await StorageHandler.appCacheDirectory;

                          for (var e in d.entries) {
                            if (e.key.contains('player_name')) {
                              final pos = int.parse(e.key.split('_').last);
                              n[pos] = e.value;
                              continue;
                            }
                            if (e.key.contains('player_image')) {
                              final pos = int.parse(e.key.split('_').last.characters.first);
                              MatchData().players.add(Player(
                                    pos: pos,
                                    name: n[pos],
                                    fullImagePath: '$c\\$matchName\\${e.key}',
                                  ));
                            }
                            StorageHandler().writeBytesToFile(
                              '$c\\$matchName\\${e.key}',
                              Networking.decodeMedia(e.value),
                              createIfNotExists: true,
                            );
                          }

                          StorageHandler().writeStringToFile(
                            '$c\\$matchName\\size.txt',
                            totalData.toString(),
                            createIfNotExists: true,
                          );
                          StorageHandler().writeStringToFile(
                            '$c\\$matchName\\names.txt',
                            n.join('|'),
                            createIfNotExists: true,
                          );

                          receivingData = false;
                          setState(() {});
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement<void, void>(
                              MaterialPageRoute<void>(builder: (context) => const Overview()),
                            );
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
              if (receivingData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Requesting match data from host'),
                          SizedBox(width: 16),
                          CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Received $dataReceived / $totalData bytes (${(dataReceived / totalData * 100).toStringAsFixed(2)}%)',
                        style: const TextStyle(fontSize: fontSizeMedium),
                      ),
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
