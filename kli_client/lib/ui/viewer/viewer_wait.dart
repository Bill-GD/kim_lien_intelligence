import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
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
    sub = KLIClient.onMessageReceived.listen((m) {
      switch (m.type) {
        case KLIMessageType.enterStart:
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => ViewerStartScreen(playerPos: int.parse(m.message))),
          );
          break;
        default:
          break;
      }
    });
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
