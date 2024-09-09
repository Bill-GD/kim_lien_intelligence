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
  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.pop) {
        Navigator.of(context).pop();
      }
    });
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
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(128),
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
                      squareSize: 100,
                      fontSize: fontSizeLarge,
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
