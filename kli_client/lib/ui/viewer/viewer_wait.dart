import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_client/ui/viewer/finish.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../../match_data.dart';
import 'accel.dart';
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
                  'Waiting for the game to start...',
                  style: TextStyle(fontSize: fontSizeLarge),
                ),
              ),
            )
          : null,
    );
  }
}
