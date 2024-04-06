import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class ExtraQuestionManager extends StatefulWidget {
  const ExtraQuestionManager({super.key});

  @override
  State<ExtraQuestionManager> createState() => _ExtraQuestionManagerState();
}

class _ExtraQuestionManagerState extends State<ExtraQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extra Question Manager'),
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
