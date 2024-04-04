import 'package:flutter/material.dart';

class AccelQuestionManager extends StatefulWidget {
  const AccelQuestionManager({super.key});

  @override
  State<AccelQuestionManager> createState() => _AccelQuestionManagerState();
}

class _AccelQuestionManagerState extends State<AccelQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Acceleration Question Manager'),
        titleTextStyle: const TextStyle(fontSize: 30),
        centerTitle: true,
      ),
      body: const Center(),
    );
  }
}
