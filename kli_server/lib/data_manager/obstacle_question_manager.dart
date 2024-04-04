import 'package:flutter/material.dart';

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
        automaticallyImplyLeading: false,
        title: const Text('Obstacle Question Manager'),
        titleTextStyle: const TextStyle(fontSize: 30),
        centerTitle: true,
      ),
      body: Center(),
    );
  }
}
