import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class ViewerObstacleRowsScreen extends StatefulWidget {
  final List<String> answers;
  final List<bool> revealedAnswers, answeredRows;
  const ViewerObstacleRowsScreen({
    super.key,
    required this.answers,
    required this.revealedAnswers,
    required this.answeredRows,
  });

  @override
  State<ViewerObstacleRowsScreen> createState() => _ViewerObstacleRowsScreenState();
}

class _ViewerObstacleRowsScreenState extends State<ViewerObstacleRowsScreen> {
  late StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    audioHandler.play(assetHandler.obsStart);
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.pop) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: isTesting,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ObstacleRow(
                    index: i,
                    answer: widget.answers[i],
                    revealed: widget.revealedAnswers[i],
                    answered: widget.answeredRows[i],
                    squareSize: 90,
                    fontSize: fontSizeLarge,
                    borderWidth: 3,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
