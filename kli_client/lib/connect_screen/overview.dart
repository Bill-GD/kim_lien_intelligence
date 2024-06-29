import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';
import '../ui/player/start.dart';

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  final List<StreamSubscription<void>> messageSubscriptions = [];
  final playerReady = <bool>[false, false, false, false];

  @override
  void initState() {
    super.initState();

    messageSubscriptions.add(KLIClient.onDisconnected.listen((_) => Navigator.pop(context)));
    messageSubscriptions.add(KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.playerReady) {
        playerReady[int.parse(m.message)] = true;
        setState(() {});
      }
      if (m.type == KLIMessageType.startMatch) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerStartScreen(playerPos: MatchData().playerPos)),
        );
      }
    }));

    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, message: 'ready', type: KLIMessageType.playerReady),
    );
  }

  @override
  void dispose() {
    for (var e in messageSubscriptions) {
      e.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Overview', style: TextStyle(fontSize: fontSizeLarge)),
          forceMaterialTransparency: true,
          automaticallyImplyLeading: kDebugMode,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 64),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text(
                    '   Waiting for host to start the game   ',
                    style: TextStyle(fontSize: fontSizeLarge),
                  ),
                  CircularProgressIndicator(),
                ],
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 4; i++) playerWidget(i),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget playerWidget(int pos) {
    final p = MatchData().players[pos];
    final isReady = playerReady[pos];

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              borderRadius: BorderRadius.circular(5),
            ),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 450, minHeight: 1, minWidth: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.memory(
                p.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isReady
                    ? Colors.lightGreenAccent //
                    : Theme.of(context).colorScheme.onBackground,
              ),
              color: isReady
                  ? Colors.green[800] //
                  : Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${p.pos + 1} - ${p.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
          ),
        ],
      ),
    );
  }
}