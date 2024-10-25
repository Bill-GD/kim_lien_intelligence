import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'accel.dart';
import 'extra.dart';
import 'finish.dart';
import 'obstacle_main.dart';
import 'start.dart';

class ViewerWaitScreen extends StatefulWidget {
  final bool saysWaiting;
  const ViewerWaitScreen({super.key, this.saysWaiting = false});

  @override
  State<ViewerWaitScreen> createState() => _ViewerWaitScreenState();
}

class _ViewerWaitScreenState extends State<ViewerWaitScreen> {
  late StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Window.setEffect(effect: WindowEffect.transparent);
    sub = KLIClient.onMessageReceived.listen((m) {
      switch (m.type) {
        case KLIMessageType.scores:
          int i = 0;
          for (int s in jsonDecode(m.message) as List) {
            MatchData().players[i].point = s;
            i++;
          }
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
        case KLIMessageType.playAudio:
          audioHandler.play(m.message, m.message.contains('background'));
          break;
        case KLIMessageType.enterStart:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => ViewerStartScreen(playerPos: int.parse(m.message))),
          );
          break;
        case KLIMessageType.enterObstacle:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const ViewerObstacleMainScreen()),
          );
          break;
        case KLIMessageType.enterAccel:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const ViewerAccelScreen()),
          );
          break;
        case KLIMessageType.enterFinish:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => ViewerFinishScreen(playerPos: int.parse(m.message))),
          );
          break;
        case KLIMessageType.enterExtra:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(
              builder: (_) => ViewerExtraScreen(
                players: jsonDecode(m.message).cast<int>(),
              ),
            ),
          );
          break;
        default:
          break;
      }
    });
    KLIClient.sendMessage(
      KLISocketMessage(senderID: KLIClient.clientID!, type: KLIMessageType.scores),
    );
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: isTesting,
        backgroundColor: Colors.transparent,
      ),
      body: widget.saysWaiting
          ? Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 900),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đang chờ trận đấu bắt đầu...',
                  style: TextStyle(fontSize: fontSizeLarge),
                ),
              ),
            )
          : null,
    );
  }
}
