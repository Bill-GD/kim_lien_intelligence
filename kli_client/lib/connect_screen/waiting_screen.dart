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
                        moveToOverview();
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
                          final r = await checkCache();

                          if (r) {
                            moveToOverview();
                            return;
                          }

                          final id = KLIClient.clientID!.name;

                          KLIClient.sendMessage(KLISocketMessage(
                            senderID: KLIClient.clientID!,
                            type: id.contains('player') //
                                ? KLIMessageType.playerData
                                : KLIMessageType.matchData,
                          ));

                          KLIClient.onDataReceived.listen((b) {
                            dataReceived += b;
                            setState(() {});
                          });
                          receivingData = true;
                          checkingCache = false;
                          setState(() {});
                        }

                        if (m.type == KLIMessageType.playerData) {
                          await parsePlayerData(m);
                          receivingData = false;
                          setState(() {});
                          moveToOverview();
                        }

                        if (m.type == KLIMessageType.matchData) {
                          await parseNewData(m);
                          receivingData = false;
                          setState(() {});
                          moveToOverview();
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
                              'Requesting match data from host (${getSizeString(actualDataSize.toDouble())}): ${(dataReceived / totalData * 100).toStringAsFixed(2)}% ',
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

  void moveToOverview() {
    KLIClient.sendMessage(KLISocketMessage(
      senderID: KLIClient.clientID!,
      type: KLIMessageType.playerReady,
    ));
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (context) => const Overview()),
    );
  }

  Future<bool> checkCache() async {
    final c = await StorageHandler.appCacheDirectory;

    final id = KLIClient.clientID!.name;

    if (id.contains('player')) {
      if (File('$c\\$matchName\\player\\size.txt').existsSync() &&
          File('$c\\$matchName\\player\\names.txt').existsSync()) {
        final s = StorageHandler().readFromFile('$c\\$matchName\\player\\size.txt');
        final n = StorageHandler().readFromFile('$c\\$matchName\\player\\names.txt').split('|');

        if (actualDataSize == int.parse(s)) {
          setState(() => receivingData = false);
          MatchData().players.addAll(List.generate(
                4,
                (i) => Player(
                  pos: i,
                  name: n[i],
                  fullImagePath: '$c\\$matchName\\player\\player_image_$i.png',
                ),
              ));
          logHandler.info('Found player data in cache');
          return true;
        }
      }
      return false;
    } else {
      if (File('$c\\$matchName\\other\\size.txt').existsSync() &&
          File('$c\\$matchName\\other\\names.txt').existsSync()) {
        final s = StorageHandler().readFromFile('$c\\$matchName\\other\\size.txt');
        final n = StorageHandler().readFromFile('$c\\$matchName\\other\\names.txt').split('|');

        if (actualDataSize == int.parse(s)) {
          setState(() => receivingData = false);
          MatchData().players.addAll(List.generate(
                4,
                (i) => Player(
                  pos: i,
                  name: n[i],
                  fullImagePath: '$c\\$matchName\\other\\player_image_$i.png',
                ),
              ));
          logHandler.info('Found match data in cache');
          return true;
        }
      }
      return false;
    }
  }

  Future<void> parseNewData(KLISocketMessage m) async {
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
              fullImagePath: '$c\\$matchName\\other\\${e.key}',
            ));
      }
      StorageHandler().writeBytesToFile(
        '$c\\$matchName\\other\\${e.key}',
        Networking.decodeMedia(e.value),
        createIfNotExists: true,
      );
    }

    StorageHandler().writeStringToFile(
      '$c\\$matchName\\other\\size.txt',
      actualDataSize.toString(),
      createIfNotExists: true,
    );
  }

  Future<void> parsePlayerData(KLISocketMessage m) async {
    final d = jsonDecode(String.fromCharCodes(
      zlib.decode(m.message.codeUnits),
    )) as Map<String, dynamic>;
    final n = List<String>.filled(4, '');
    final c = await StorageHandler.appCacheDirectory;

    for (var e in d.entries) {
      if (e.key.contains('player_name')) {
        final pos = int.parse(e.key.split('_').last);
        n[pos] = e.value;
      }

      if (e.key.contains('player_image')) {
        final pos = int.parse(e.key.split('_').last.characters.first);
        MatchData().players.add(
              Player(
                pos: pos,
                name: n[pos],
                fullImagePath: '$c\\$matchName\\player\\${e.key}',
              ),
            );
        StorageHandler().writeBytesToFile(
          '$c\\$matchName\\player\\${e.key}',
          Networking.decodeMedia(e.value),
          createIfNotExists: true,
        );
      }
    }

    StorageHandler().writeStringToFile(
      '$c\\$matchName\\player\\names.txt',
      n.join('|'),
      createIfNotExists: true,
    );

    StorageHandler().writeStringToFile(
      '$c\\$matchName\\player\\size.txt',
      actualDataSize.toString(),
      createIfNotExists: true,
    );
  }
}
