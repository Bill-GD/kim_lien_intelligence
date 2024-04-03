import 'package:flutter/material.dart';

class FinishQuestionManager extends StatefulWidget {
  const FinishQuestionManager({super.key});

  @override
  State<FinishQuestionManager> createState() => _FinishQuestionManagerState();
}

class _FinishQuestionManagerState extends State<FinishQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Finish Manager'),
      ),
    );
  }
}
