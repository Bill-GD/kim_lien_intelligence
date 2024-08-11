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
  bool receivingData = false, checkingCache = false;
  int dataReceived = 0, totalData = 0, actualDataSize = 0;
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
                    enableCondition: !checkingCache && !receivingData,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 32),
                  KLIButton(
                    'Ready',
                    enableCondition: !checkingCache && !receivingData,
                    enabledLabel: 'No turning back',
                    onPressed: () {
                      if (MatchData().players.isNotEmpty) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(builder: (context) => const Overview()),
                        );
                        return;
                      }

                      MatchData().setPos(KLIClient.clientID!.index - 1);
                      setState(() => checkingCache = true);

                      KLIClient.sendMessage(KLISocketMessage(
                        senderID: KLIClient.clientID!,
                        type: KLIMessageType.dataSize,
                      ));

                      KLIClient.onMessageReceived.listen((m) async {
                        if (m.type == KLIMessageType.dataSize) {
                          final s = m.message.split('|');
                          totalData = int.parse(s.first);
                          actualDataSize = int.parse(s.last);
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

                            if (actualDataSize == int.parse(s)) {
                              setState(() => receivingData = false);
                              MatchData().players.addAll(List.generate(
                                    4,
                                    (i) => Player(
                                      pos: i,
                                      name: n[i],
                                      fullImagePath: '$c\\$matchName\\player_image_$i.png',
                                    ),
                                  ));

                              KLIClient.sendMessage(
                                KLISocketMessage(
                                    senderID: KLIClient.clientID!, type: KLIMessageType.playerReady),
                              );
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
                          setState(() => receivingData = true);
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
                            actualDataSize.toString(),
                            createIfNotExists: true,
                          );
                          StorageHandler().writeStringToFile(
                            '$c\\$matchName\\names.txt',
                            n.join('|'),
                            createIfNotExists: true,
                          );

                          receivingData = false;
                          setState(() {});

                          KLIClient.sendMessage(
                            KLISocketMessage(senderID: KLIClient.clientID!, type: KLIMessageType.playerReady),
                          );
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
              if (receivingData || checkingCache)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      checkingCache
                          ? const Text('Checking for cached data...')
                          : Text(
                              'Requesting match data from host (${getSizeString(actualDataSize.toDouble())}): ${(dataReceived / totalData).toStringAsFixed(2) * 100}% ',
                            ),
                      const SizedBox(width: 16),
                      const CircularProgressIndicator(),
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
