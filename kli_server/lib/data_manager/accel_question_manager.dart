import 'package:flutter/material.dart';

class AccelQuestionManager extends StatefulWidget {
  const AccelQuestionManager({super.key});

  @override
  State<AccelQuestionManager> createState() => _AccelQuestionManagerState();
}

class _AccelQuestionManagerState extends State<AccelQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Accel Manager'),
      ),
    );
  }
}
