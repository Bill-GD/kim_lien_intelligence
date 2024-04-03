import 'package:flutter/material.dart';

class ObstacleQuestionManager extends StatefulWidget {
  const ObstacleQuestionManager({super.key});

  @override
  State<ObstacleQuestionManager> createState() => _ObstacleQuestionManagerState();
}

class _ObstacleQuestionManagerState extends State<ObstacleQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Obstacle Manager'),
      ),
    );
  }
}
