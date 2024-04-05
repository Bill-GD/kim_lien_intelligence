import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class ObstacleQuestionManager extends StatefulWidget {
  const ObstacleQuestionManager({super.key});

  @override
  State<ObstacleQuestionManager> createState() => _ObstacleQuestionManagerState();
}

class _ObstacleQuestionManagerState extends State<ObstacleQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obstacle Question Manager'),
        surfaceTintColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(fontSize: fontSizeXL),
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 1.5,
      ),
      body: const Center(),
    );
  }
}
