import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';
import '../ui/viewer/viewer_wait.dart';
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
  String matchName = '', progressMessage = '';

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
          automaticallyImplyLeading: isTesting,
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
                      if (KLIClient.isPlayer) MatchData().setPos(KLIClient.clientID!.index - 1);
                      checkingCache = true;
                      progressMessage = 'App doesn\'t have data for this match...';
                      setState(() {});

                      setState(() => progressMessage = 'Requesting metadata...');
                      KLIClient.sendMessage(KLISocketMessage(
                        senderID: KLIClient.clientID!,
                        type: KLIMessageType.dataSize,
                      ));

                      KLIClient.onMessageReceived.listen((m) {
                        if (m.type == KLIMessageType.dataSize) {
                          setState(() => progressMessage = 'Received metadata...');
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
                          MatchData().matchName = matchName;
                          setState(() => progressMessage = 'Checking cached data of "$matchName"...');
                          final r = checkCache();

                          if (r) {
                            setState(() => progressMessage = 'Found cached data of "$matchName"...');
                            moveToOverview();
                            return;
                          }

                          setState(() => progressMessage = 'Requesting data of "$matchName"...');
                          KLIClient.sendMessage(KLISocketMessage(
                            senderID: KLIClient.clientID!,
                            type: KLIClient.isPlayer //
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
                          parsePlayerData(m);
                          receivingData = false;
                          setState(() {});
                          moveToOverview();
                        }

                        if (m.type == KLIMessageType.matchData) {
                          parseNewData(m);
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
                      Text(
                        checkingCache
                            ? progressMessage
                            : 'Requesting match data from host'
                                ' (${getSizeString(actualDataSize)}):'
                                ' ${(dataReceived / totalData * 100).toStringAsFixed(2)}% ',
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
    if (KLIClient.isPlayer) {
      KLIClient.sendMessage(KLISocketMessage(
        senderID: KLIClient.clientID!,
        type: KLIMessageType.playerReady,
      ));
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (context) => const Overview()),
      );
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (context) => const ViewerWaitScreen(saysWaiting: true)),
    );
  }

  bool checkCache() {
    if (KLIClient.isPlayer) {
      if (File('$cachePath\\$matchName\\player\\size.txt').existsSync() &&
          File('$cachePath\\$matchName\\player\\names.txt').existsSync()) {
        final s = StorageHandler().readFromFile('$cachePath\\$matchName\\player\\size.txt');
        final n = StorageHandler().readFromFile('$cachePath\\$matchName\\player\\names.txt').split('|');

        if (actualDataSize == int.parse(s)) {
          setState(() => receivingData = false);
          MatchData().players.addAll(List.generate(
                4,
                (i) => Player(
                  pos: i,
                  name: n[i],
                  fullImagePath: '$cachePath\\$matchName\\player\\pi_$i.png',
                ),
              ));
          logHandler.info('Found player data in cache');
          return true;
        }
      }
      return false;
    } else {
      if (File('$cachePath\\$matchName\\other\\size.txt').existsSync() &&
          File('$cachePath\\$matchName\\other\\names.txt').existsSync()) {
        final s = StorageHandler().readFromFile('$cachePath\\$matchName\\other\\size.txt');
        final n = StorageHandler().readFromFile('$cachePath\\$matchName\\other\\names.txt').split('|');

        if (actualDataSize == int.parse(s)) {
          setState(() => receivingData = false);
          MatchData().players.addAll(List.generate(
                4,
                (i) => Player(
                  pos: i,
                  name: n[i],
                  fullImagePath: '$cachePath\\$matchName\\other\\pi_$i.png',
                ),
              ));
          logHandler.info('Found match data in cache');
          return true;
        }
      }
      return false;
    }
  }

  void parseNewData(KLISocketMessage m) {
    final d = jsonDecode(String.fromCharCodes(
      zlib.decode(m.message.codeUnits),
    )) as Map<String, dynamic>;
    final n = List<String>.filled(4, '');

    for (var e in d.entries) {
      if (e.key.contains('pn')) {
        final pos = int.parse(e.key.split('_').last);
        n[pos] = e.value;
        continue;
      }
      if (e.key.contains('pi')) {
        final pos = int.parse(e.key.split('_').last.characters.first);
        MatchData().players.add(Player(
              pos: pos,
              name: n[pos],
              fullImagePath: '$cachePath\\$matchName\\other\\${e.key}',
            ));
      }
      StorageHandler().writeBytesToFile(
        '$cachePath\\$matchName\\other\\${e.key}',
        Networking.decodeMedia(e.value),
        createIfNotExists: true,
      );
    }

    StorageHandler().writeStringToFile(
      '$cachePath\\$matchName\\other\\names.txt',
      n.join('|'),
      createIfNotExists: true,
    );

    StorageHandler().writeStringToFile(
      '$cachePath\\$matchName\\other\\size.txt',
      actualDataSize.toString(),
      createIfNotExists: true,
    );
  }

  void parsePlayerData(KLISocketMessage m) {
    final d = jsonDecode(String.fromCharCodes(
      zlib.decode(m.message.codeUnits),
    )) as Map<String, dynamic>;
    final n = List<String>.filled(4, '');

    for (var e in d.entries) {
      if (e.key.contains('pn')) {
        final pos = int.parse(e.key.split('_').last);
        n[pos] = e.value;
      }

      if (e.key.contains('pi')) {
        final pos = int.parse(e.key.split('_').last.characters.first);
        MatchData().players.add(
              Player(
                pos: pos,
                name: n[pos],
                fullImagePath: '$cachePath\\$matchName\\player\\${e.key}',
              ),
            );
        StorageHandler().writeBytesToFile(
          '$cachePath\\$matchName\\player\\${e.key}',
          Networking.decodeMedia(e.value),
          createIfNotExists: true,
        );
      }
    }

    StorageHandler().writeStringToFile(
      '$cachePath\\$matchName\\player\\names.txt',
      n.join('|'),
      createIfNotExists: true,
    );

    StorageHandler().writeStringToFile(
      '$cachePath\\$matchName\\player\\size.txt',
      actualDataSize.toString(),
      createIfNotExists: true,
    );
  }
}
