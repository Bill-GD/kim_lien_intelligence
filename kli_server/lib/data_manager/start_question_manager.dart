import 'package:flutter/material.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Start Manager'),
      ),
    );
  }
}