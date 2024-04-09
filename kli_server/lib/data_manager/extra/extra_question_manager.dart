import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class ExtraQuestionManager extends StatefulWidget {
  const ExtraQuestionManager({super.key});

  @override
  State<ExtraQuestionManager> createState() => _ExtraQuestionManagerState();
}

class _ExtraQuestionManagerState extends State<ExtraQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context,'Extra Question Manager'),
      backgroundColor: Colors.transparent,
      body: const Center(),
    );
  }
}
