import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';
import '../ui/player/obstacle.dart';
import '../ui/player/start.dart';

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  final List<StreamSubscription<void>> messageSubscriptions = [];
  final playerReady = <bool>[false, false, false, false];
  String overviewMessage = '   Chờ máy chủ bắt đầu trận đấu   ';
  bool started = false;

  @override
  void initState() {
    super.initState();

    messageSubscriptions.add(KLIClient.onDisconnected.listen((_) => Navigator.pop(context)));
    messageSubscriptions.add(KLIClient.onMessageReceived.listen((m) async {
      switch (m.type) {
        case KLIMessageType.playerReady:
          playerReady[int.parse(m.message)] = true;
          setState(() {});
          break;
        case KLIMessageType.section:
          overviewMessage = 'Phần thi: ${m.message}';
          setState(() {});
          break;
        case KLIMessageType.startMatch:
          overviewMessage = 'Phần thi: khởi động';
          started = true;
          setState(() {});
          break;
        case KLIMessageType.enterStart:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => PlayerStartScreen(playerPos: int.parse(m.message))),
          );
          setState(() {});
          break;
        case KLIMessageType.enterObstacle:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PlayerObstacleScreen()),
          );
          setState(() {});
          break;
        default:
          break;
      }
    }));

    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, message: '', type: KLIMessageType.playerReady),
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
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Tổng quan', style: TextStyle(fontSize: fontSizeLarge)),
          forceMaterialTransparency: true,
          automaticallyImplyLeading: kDebugMode,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!started) const CircularProgressIndicator(),
                  Text(
                    overviewMessage,
                    style: const TextStyle(fontSize: fontSizeLarge),
                  ),
                  if (!started) const CircularProgressIndicator(),
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
                color: Theme.of(context).colorScheme.onBackground,
              ),
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                Text(
                  '${p.pos + 1} - ${p.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
                const Divider(color: Colors.white),
                Text(
                  p.point.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
