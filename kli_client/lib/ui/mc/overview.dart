import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'accel.dart';
import 'extra.dart';
import 'finish.dart';
import 'obstacle.dart';
import 'start.dart';

class MCOverviewScreen extends StatefulWidget {
  const MCOverviewScreen({super.key});

  @override
  State<MCOverviewScreen> createState() => _MCOverviewScreenState();
}

class _MCOverviewScreenState extends State<MCOverviewScreen> {
  final List<StreamSubscription<void>> messageSubscriptions = [];
  final playerReady = <bool>[false, false, false, false];
  String overviewMessage = 'Chờ máy chủ bắt đầu trận đấu';
  bool ended = false;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    messageSubscriptions.add(KLIClient.onDisconnected.listen((_) => Navigator.pop(context)));
    messageSubscriptions.add(KLIClient.onMessageReceived.listen((m) {
      if (ended) return;
      switch (m.type) {
        case KLIMessageType.scores:
          int i = 0;
          for (int s in jsonDecode(m.message) as List) {
            MatchData().players[i].point = s;
            i++;
          }
          break;
        case KLIMessageType.section:
          overviewMessage = 'Phần thi: ${m.message}';
          break;
        case KLIMessageType.startMatch:
          overviewMessage = 'Phần thi: khởi động';
          break;
        case KLIMessageType.showScores:
          final l = MatchData().players.map((e) => (e.name, e.fullImagePath, e.point)).toList();

          l.sort((a, b) => b.$3.compareTo(a.$3));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SectionResult(
                backgroundImage: bgDecorationImage!,
                players: l.map((e) => e.$1).toList(),
                images: l.map((e) => e.$2).toList(),
                scores: l.map((e) => e.$3).toList(),
                playMusic: audioHandler.play,
                allowClose: true,
              ),
            ),
          );
          break;
        case KLIMessageType.enterStart:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => MCStartScreen(playerPos: int.parse(m.message))),
          );
          break;
        case KLIMessageType.enterObstacle:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const MCObstacleScreen()),
          );
          break;
        case KLIMessageType.enterAccel:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const MCAccelScreen()),
          );
          break;
        case KLIMessageType.enterFinish:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => MCFinishScreen(playerPos: int.parse(m.message))),
          );
          break;
        case KLIMessageType.enterExtra:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(
              builder: (_) => MCExtraScreen(
                players: jsonDecode(m.message).cast<int>(),
              ),
            ),
          );
          break;
        default:
          break;
      }
      setState(() {});
    }));
    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, type: KLIMessageType.section),
    );
    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, type: KLIMessageType.scores),
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
          automaticallyImplyLeading: isTesting || ended,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 46),
              Text(
                overviewMessage,
                style: const TextStyle(fontSize: fontSizeLarge),
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
              child: Image.file(
                File(p.fullImagePath),
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
