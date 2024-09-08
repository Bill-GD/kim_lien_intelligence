import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'start.dart';

class ViewerWaitScreen extends StatefulWidget {
  const ViewerWaitScreen({super.key});

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
        case KLIMessageType.enterStart:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => ViewerStartScreen(playerPos: int.parse(m.message))),
          );
          break;
        case KLIMessageType.enterObstacle:
          // Navigator.of(context).pushReplacement<void, void>(
          //   MaterialPageRoute(builder: (_) => const PlayerObstacleScreen()),
          // );
          break;
        case KLIMessageType.enterAccel:
          // Navigator.of(context).pushReplacement<void, void>(
          //   MaterialPageRoute(builder: (_) => const PlayerAccelScreen()),
          // );
          break;
        case KLIMessageType.enterFinish:
          // Navigator.of(context).pushReplacement<void, void>(
          //   MaterialPageRoute(builder: (_) => PlayerFinishScreen(playerPos: int.parse(m.message))),
          // );
          break;
        case KLIMessageType.enterExtra:
          // Navigator.of(context).pushReplacement<void, void>(
          //   MaterialPageRoute(builder: (_) => const PlayerExtraScreen()),
          // );
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
      appBar: AppBar(
        automaticallyImplyLeading: isTesting,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
