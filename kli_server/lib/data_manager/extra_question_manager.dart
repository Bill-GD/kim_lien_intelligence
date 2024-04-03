import 'package:flutter/material.dart';

class ExtraQuestionManager extends StatefulWidget {
  const ExtraQuestionManager({super.key});

  @override
  State<ExtraQuestionManager> createState() => _ExtraQuestionManagerState();
}

class _ExtraQuestionManagerState extends State<ExtraQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Extra Manager'),
      ),
    );
  }
}
