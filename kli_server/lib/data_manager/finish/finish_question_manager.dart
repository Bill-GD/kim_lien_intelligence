import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

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
        title: const Text('Finish Question Manager'),
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
