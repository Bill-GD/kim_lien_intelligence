import 'package:flutter/material.dart';

class FinishQuestionManager extends StatefulWidget {
  const FinishQuestionManager({super.key});

  @override
  State<FinishQuestionManager> createState() => _FinishQuestionManagerState();
}

class _FinishQuestionManagerState extends State<FinishQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Finish Question Manager'),
        titleTextStyle: const TextStyle(fontSize: 30),
        centerTitle: true,
      ),
      body: const Center(),
    );
  }
}
