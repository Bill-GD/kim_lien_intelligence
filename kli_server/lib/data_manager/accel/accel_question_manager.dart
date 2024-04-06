import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

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
        title: const Text('Acceleration Question Manager'),
        surfaceTintColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(fontSize: fontSizeXL),
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 1.1,
      ),
      body: const Center(),
    );
  }
}
